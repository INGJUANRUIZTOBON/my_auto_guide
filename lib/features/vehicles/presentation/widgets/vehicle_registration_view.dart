// =============================================================================
// vehicle_registration_view.dart — REGISTRO DE VEHÍCULOS (MOTOS Y CARROS)
// =============================================================================
//
// Pantalla compartida por el registro de motocicletas y el de automóviles.
// Ambos flujos son idénticos salvo el catálogo, la marca por defecto y los
// textos, por lo que se parametrizan mediante [VehicleKind]:
//   - Catálogo visual por marca con carrusel deslizable (PageView).
//   - Selector horizontal de marcas con logos y colores personalizados.
//   - Formulario: placa, cédula, kilometraje, modelo (año) y apodo.
//   - Tabs laterales «Carro / Moto» para alternar entre ambos registros.
//   - Guardado en la tabla `vehiculos` de Supabase y navegación a [InicioApp].
//
// Widgets auxiliares:
//   - [_SideTab]: Botón vertical rotado para los tabs «Carro / Moto».
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/cloud_catalog_service.dart';
import '../../../../core/services/insurance_catalog_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/vehicle_catalog_service.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/smart_vehicle_image.dart';
import '../inicio_app.dart';
import 'insurance_picker_sheet.dart';

/// Tipo de vehículo que se está registrando.
enum VehicleKind { moto, carro }

extension VehicleKindData on VehicleKind {
  String get label => this == VehicleKind.moto ? 'Moto' : 'Carro';

  String get defaultBrand => this == VehicleKind.moto ? 'YAMAHA' : 'TOYOTA';

  String get plateLabel =>
      this == VehicleKind.moto ? 'Placa de la moto' : 'Placa del carro';

  String get submitLabel =>
      this == VehicleKind.moto ? 'Crear Vehículo' : 'Crear Carro';

  String get invalidSelectionMessage => this == VehicleKind.moto
      ? 'Selecciona una moto válida'
      : 'Selecciona un carro válido';

  VehicleKind get other =>
      this == VehicleKind.moto ? VehicleKind.carro : VehicleKind.moto;
}

class VehicleRegistrationView extends StatefulWidget {
  final VehicleKind kind;

  const VehicleRegistrationView({super.key, required this.kind});

  @override
  State<VehicleRegistrationView> createState() =>
      _VehicleRegistrationViewState();
}

class _VehicleRegistrationViewState extends State<VehicleRegistrationView> {
  // Servicios
  final _catalogService = VehicleCatalogService();
  final _cloudCatalog = CloudCatalogService();

  late final Map<String, List<Map<String, String>>> catalogo;
  late final Map<String, String> logos;
  late final Map<String, Color> brandColors;

  List<CatalogBrand> _cloudBrands = [];
  List<CatalogModel> _cloudModels = [];
  bool _loadingCatalog = false;
  bool _isManualMode = false;
  String? _customImagePath;

  late String marcaSeleccionada;
  int indexModelo = 0;
  late PageController _page;

  final TextEditingController _kmsController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _apodoController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _manualMarcaController = TextEditingController();
  final TextEditingController _manualModeloController = TextEditingController();

  String _aseguradoraId = InsuranceCatalogService.noneId;

  final supabase = Supabase.instance.client;

  List<Map<String, String>> get modelosDeMarca {
    if (_cloudModels.isNotEmpty) {
      return _cloudModels
          .map((m) => {'modelo': m.modelo, 'img': m.imagenUrl})
          .toList();
    }
    return catalogo[marcaSeleccionada] ?? const [];
  }

  @override
  void initState() {
    super.initState();
    final isMoto = widget.kind == VehicleKind.moto;
    catalogo = isMoto
        ? _catalogService.getMotoCatalog()
        : _catalogService.getCarCatalog();
    logos =
        isMoto ? _catalogService.getMotoLogos() : _catalogService.getCarLogos();
    brandColors = _catalogService.getBrandColors();
    marcaSeleccionada = widget.kind.defaultBrand;
    _page = PageController(initialPage: indexModelo);

    _inicializarCatalogoCloud();
  }

  Future<void> _inicializarCatalogoCloud() async {
    final isMoto = widget.kind == VehicleKind.moto;
    try {
      final brands = await _cloudCatalog.getBrands(isMoto: isMoto);
      if (mounted && brands.isNotEmpty) {
        setState(() {
          _cloudBrands = brands;
          if (brands.any((b) => b.nombre.toUpperCase() == marcaSeleccionada)) {
            final match = brands.firstWhere(
                (b) => b.nombre.toUpperCase() == marcaSeleccionada);
            marcaSeleccionada = match.nombre.toUpperCase();
          } else {
            marcaSeleccionada = brands.first.nombre.toUpperCase();
          }
        });
        await _cargarModelosDeMarca(marcaSeleccionada);
      }
    } catch (_) {}
  }

  Future<void> _cargarModelosDeMarca(String marca) async {
    final isMoto = widget.kind == VehicleKind.moto;
    setState(() => _loadingCatalog = true);
    try {
      final models = await _cloudCatalog.getModelsForBrand(marca, isMoto: isMoto);
      if (mounted) {
        setState(() {
          _cloudModels = models;
          indexModelo = 0;
          _loadingCatalog = false;
        });
        if (_page.hasClients) {
          _page.jumpToPage(0);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _kmsController.dispose();
    _modeloController.dispose();
    _apodoController.dispose();
    _placaController.dispose();
    _cedulaController.dispose();
    _manualMarcaController.dispose();
    _manualModeloController.dispose();
    super.dispose();
  }

  Future<void> _cambiarMarca(String marca) async {
    if (marcaSeleccionada == marca) return;
    setState(() {
      marcaSeleccionada = marca;
      indexModelo = 0;
      if (_page.hasClients) {
        _page.jumpToPage(0);
      }
    });
    await _cargarModelosDeMarca(marca);
  }

  Future<void> _seleccionarFotoPersonalizada() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona la foto de tu vehículo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00E5FF)),
                title: const Text('Tomar foto con la cámara', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF00FF87)),
                title: const Text('Elegir de la galería', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null && mounted) {
        setState(() {
          _customImagePath = picked.path;
        });
      }
    }
  }

  Future<void> _mostrarSelectorAseguradora() async {
    final selected = await InsurancePickerSheet.show(
      context: context,
      currentId: _aseguradoraId,
      isMoto: widget.kind == VehicleKind.moto,
      title: 'Aseguradora Todo Riesgo',
      confirmButtonText: 'Listo',
    );
    if (selected != null && mounted) {
      setState(() {
        _aseguradoraId = selected.id;
      });
    }
  }

  // Guardar en Supabase y navegar
  Future<void> _guardarVehiculo() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      AppSnackBar.show(context, 'Debes iniciar sesión');
      return;
    }

    final kms = int.tryParse(_kmsController.text.trim()) ?? 0;
    final apodo = _apodoController.text.trim();
    final placa = _placaController.text.trim().toUpperCase();
    final cedula = _cedulaController.text.trim();

    final String marca;
    final String modelo;
    final String imagePath;

    if (_isManualMode) {
      marca = _manualMarcaController.text.trim().toUpperCase();
      modelo = _manualModeloController.text.trim();
      imagePath = _customImagePath ??
          (widget.kind == VehicleKind.moto
              ? 'assets/motos/bajaj/boxer-ct100.png'
              : 'assets/carros/toyota/corolla.png');
      if (marca.isEmpty || modelo.isEmpty) {
        AppSnackBar.show(context, 'Por favor ingresa la marca y el modelo de tu vehículo');
        return;
      }
    } else {
      marca = marcaSeleccionada;
      modelo = modelosDeMarca.isEmpty ? '' : modelosDeMarca[indexModelo]['modelo']!;
      imagePath = modelosDeMarca.isEmpty ? '' : modelosDeMarca[indexModelo]['img']!;
      if (modelo.isEmpty || imagePath.isEmpty) {
        AppSnackBar.show(context, widget.kind.invalidSelectionMessage);
        return;
      }
    }

    if (placa.isEmpty) {
      AppSnackBar.show(context, 'Por favor ingresa la ${widget.kind.plateLabel.toLowerCase()}');
      return;
    }
    if (cedula.isEmpty) {
      AppSnackBar.show(context, 'Por favor ingresa la cédula del propietario');
      return;
    }

    try {
      final row = await SupabaseService().createVehicle(
        userId: user.id,
        marca: marca,
        modelo: modelo,
        apodo: apodo,
        kms: kms,
        imagePath: imagePath,
        placa: placa,
        cedula: cedula,
        aseguradoraId: _aseguradoraId,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InicioApp(vehiculoId: row['id'] as String),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Error al guardar: ${e.message}');
    }
  }

  void _irAOtroRegistro() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleRegistrationView(kind: widget.kind.other),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 240;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modeloActual =
        modelosDeMarca.isEmpty ? '' : modelosDeMarca[indexModelo]['modelo']!;

    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 0, elevation: 0, backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: headerHeight,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/lineasfondo.png'),
                  fit: BoxFit.cover,
                  alignment: const Alignment(-0.20, -0.05),
                  colorFilter: isDark
                      ? ColorFilter.mode(
                          Colors.black.withOpacity(0.85), BlendMode.darken)
                      : null,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  'Mi Garaje',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Registra tu vehículo para empezar',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (!_isManualMode) ...[
                  SizedBox(
                    height: headerHeight,
                    child: Row(
                      children: [
                        Column(
                          children: [
                            _SideTab(
                              text: 'Carro',
                              selected: widget.kind == VehicleKind.carro,
                              onTap: widget.kind == VehicleKind.carro
                                  ? null
                                  : _irAOtroRegistro,
                            ),
                            _SideTab(
                              text: 'Moto',
                              selected: widget.kind == VehicleKind.moto,
                              onTap: widget.kind == VehicleKind.moto
                                  ? null
                                  : _irAOtroRegistro,
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _loadingCatalog
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF00E5FF),
                                  ),
                                )
                              : PageView.builder(
                                  controller: _page,
                                  itemCount: modelosDeMarca.length,
                                  onPageChanged: (i) =>
                                      setState(() => indexModelo = i),
                                  itemBuilder: (context, i) {
                                    final img = modelosDeMarca[i]['img']!;
                                    final imageWidget = SmartVehicleImage(
                                      imagePath: img,
                                      fit: BoxFit.contain,
                                      isCar: widget.kind == VehicleKind.carro,
                                    );
                                    // Solo el modelo activo porta el Hero tag para evitar conflicto en el PageView
                                    return i == indexModelo
                                        ? Hero(
                                            tag: 'vehicle_main_image',
                                            child: imageWidget,
                                          )
                                        : imageWidget;
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    modeloActual,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: Builder(
                      builder: (context) {
                        final brandsList = _cloudBrands.isNotEmpty
                            ? _cloudBrands
                                .map((b) => b.nombre.toUpperCase())
                                .toList()
                            : logos.keys.toList();

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: brandsList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final marca = brandsList[index];
                            final selected = marcaSeleccionada == marca;
                            final brandColor = _cloudBrands.isNotEmpty
                                ? _cloudBrands
                                    .firstWhere(
                                      (b) => b.nombre.toUpperCase() == marca,
                                      orElse: () => _cloudBrands.first,
                                    )
                                    .color
                                : (brandColors[marca] ?? Colors.blue);
                            final logoPath = _cloudBrands.isNotEmpty
                                ? _cloudBrands
                                    .firstWhere(
                                      (b) => b.nombre.toUpperCase() == marca,
                                      orElse: () => _cloudBrands.first,
                                    )
                                    .logoUrl
                                : (logos[marca] ?? '');

                            return GestureDetector(
                              onTap: () => _cambiarMarca(marca),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? brandColor.withOpacity(0.1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: selected
                                              ? brandColor
                                              : Colors.grey.shade300,
                                          width: 2),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: SmartVehicleImage(
                                      imagePath: logoPath,
                                      fit: BoxFit.contain,
                                      width: 48,
                                      height: 48,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    marca,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: selected
                                          ? brandColor
                                          : (isDark
                                              ? Colors.white70
                                              : Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // Modo manual: Foto personalizada + Marca y modelo manual
                  GestureDetector(
                    onTap: _seleccionarFotoPersonalizada,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: _customImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SmartVehicleImage(
                                imagePath: _customImagePath,
                                fit: BoxFit.cover,
                                isCar: widget.kind == VehicleKind.carro,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_rounded,
                                    size: 46, color: Color(0xFF00E5FF)),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca para tomar o subir foto de tu vehículo',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    _manualMarcaController,
                    'Marca del vehículo (ej. Royal Enfield, Bajaj, Renault)',
                    Icons.branding_watermark_rounded,
                  ),
                  _buildField(
                    _manualModeloController,
                    'Línea o Modelo (ej. Himalayan 450, Duster)',
                    Icons.directions_car_rounded,
                  ),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _isManualMode = !_isManualMode);
                  },
                  icon: Icon(
                    _isManualMode
                        ? Icons.auto_awesome_rounded
                        : Icons.edit_note_rounded,
                    color: const Color(0xFF00E5FF),
                  ),
                  label: Text(
                    _isManualMode
                        ? 'Volver a seleccionar del catálogo'
                        : '¿No encuentras tu modelo? Escríbelo manualmente',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(
                    _placaController, widget.kind.plateLabel, Icons.tag),
                _buildField(
                    _cedulaController,
                    'Cédula del propietario',
                    Icons.badge,
                    helperText: 'Cifrada de forma segura para consultas de SOAT y RUNT'),
                _buildField(
                    _kmsController,
                    'Kilometraje (Odómetro)',
                    Icons.speed,
                    helperText: 'Kilómetros totales que marca el tablero de tu vehículo'),
                _buildField(
                    _modeloController, 'Modelo (Año)', Icons.calendar_today),
                _buildField(_apodoController, 'Apodo', Icons.edit),
                _buildInsuranceSelectorField(),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _guardarVehiculo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF035880),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(widget.kind.submitLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceSelectorField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final company = InsuranceCatalogService.findById(_aseguradoraId);
    final isNone = company == null;
    final displayName =
        isNone ? 'No tengo aseguradora todo riesgo' : company.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !isNone
              ? const Color(0xFF035880).withOpacity(0.4)
              : (isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _mostrarSelectorAseguradora,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: isNone
                      ? (isDark ? Colors.white54 : Colors.black45)
                      : const Color(0xFF035880),
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Aseguradora Todo Riesgo',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isNone ? FontWeight.normal : FontWeight.w600,
                          color: isNone
                              ? (isDark ? Colors.white70 : Colors.black54)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller, String label, IconData icon,
      {String? helperText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 2,
          prefixIcon: Icon(icon, color: const Color(0xFF035880)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _SideTab extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  const _SideTab({required this.text, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 100,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF035880) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF035880).withOpacity(0.3)),
        ),
        child: RotatedBox(
            quarterTurns: 3,
            child: Center(
                child: Text(text,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold)))),
      ),
    );
  }
}
