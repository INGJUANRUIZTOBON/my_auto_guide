import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/vehicle_catalog_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/smart_vehicle_image.dart';

/// Showroom Cinemático 3D de "Mi Garaje":
/// Piso epoxi/asfalto reflectivo, bahías numeradas con underglow LED,
/// pedestal de exhibición de vehículos y bahía holográfica disponible para añadir.
class GarageShowroomView extends StatefulWidget {
  final String currentVehicleId;
  final ValueChanged<String> onSelectVehicle;
  final VoidCallback onAddMoto;
  final VoidCallback onAddCar;
  final VoidCallback? onClose;

  const GarageShowroomView({
    super.key,
    required this.currentVehicleId,
    required this.onSelectVehicle,
    required this.onAddMoto,
    required this.onAddCar,
    this.onClose,
  });

  @override
  State<GarageShowroomView> createState() => _GarageShowroomViewState();
}

class _GarageShowroomViewState extends State<GarageShowroomView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF06080C) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Barra de Control Superior del Showroom
            _buildShowroomHeader(isDark, isDesktop),

            // 2. Escenario Principal del Showroom con Bahías 3D
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: SupabaseService().getVehicles(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar el garaje: ${snapshot.error}',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    );
                  }

                  final vehicles = snapshot.data ?? [];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // Piso Isométrico y Rayos Cenitales
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _ShowroomEpoxyFloorPainter(
                                  isDark: isDark,
                                  pulse: _pulseController.value,
                                ),
                              ),
                            ),
                          ),

                          // Lista Horizontal de Bahías del Garaje
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              return ListView.builder(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 60 : 20,
                                  vertical: 24,
                                ),
                                itemCount: vehicles.length + 1, // +1 para la Bahía Vacía
                                itemBuilder: (context, index) {
                                  if (index < vehicles.length) {
                                    final vehicle = vehicles[index];
                                    final id = vehicle['id'] as String;
                                    final bool isActive = id == widget.currentVehicleId;

                                    return _buildVehicleBay(
                                      vehicle: vehicle,
                                      bayNumber: index + 1,
                                      isActive: isActive,
                                      isDark: isDark,
                                      pulse: _pulseController.value,
                                      isDesktop: isDesktop,
                                    );
                                  } else {
                                    // Última Bahía: Bahía Vacía para Agregar Vehículo
                                    return _buildEmptyBay(
                                      bayNumber: index + 1,
                                      isDark: isDark,
                                      pulse: _pulseController.value,
                                      isDesktop: isDesktop,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowroomHeader(bool isDark, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0B101B).withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.garage_rounded, color: Colors.black, size: 16),
                SizedBox(width: 6),
                Text(
                  'SHOWROOM VIRTUAL',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Mi Garaje',
            style: TextStyle(
              fontSize: isDesktop ? 20 : 17,
              fontWeight: FontWeight.w800,
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          if (widget.onClose != null)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              tooltip: 'Cerrar Showroom',
              onPressed: widget.onClose,
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleBay({
    required Map<String, dynamic> vehicle,
    required int bayNumber,
    required bool isActive,
    required bool isDark,
    required double pulse,
    required bool isDesktop,
  }) {
    final id = vehicle['id'] as String;
    final String brand = (vehicle['marca'] as String? ?? '').toUpperCase();
    final String model = (vehicle['modelo'] as String? ?? '').toUpperCase();
    final String nickname = vehicle['apodo'] as String? ?? '';
    final String plate = (vehicle['placa'] as String? ?? '').toUpperCase();
    final int kms = vehicle['kms'] as int? ?? 0;
    final double health = ((vehicle['health_index'] ?? 85) as num).toDouble();

    // Determinar si es moto o carro
    final String imgRaw = (vehicle['image_path'] as String? ?? '').toLowerCase();
    final bool isCar = imgRaw.contains('carros/') ||
        brand.contains('CARRO') ||
        (vehicle['is_car'] == true);

    // Resolver mejor imagen disponible (360 o catálogo)
    final images360 = (vehicle['images_360_urls'] is List)
        ? List<String>.from(vehicle['images_360_urls'])
        : <String>[];
    final String? bestImage = images360.isNotEmpty
        ? images360.first
        : (vehicle['image_path'] ?? vehicle['foto_url'] ??
            VehicleCatalogService().resolveVehicleImage(brand, model, isCar: isCar));

    final cardWidth = isDesktop ? 360.0 : 290.0;
    final underglowColor = isActive
        ? const Color(0xFF00E5FF)
        : (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.6) : const Color(0xFF2563EB));

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 28),
      child: Column(
        children: [
          // Header de la Bahía
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? const Color(0xFF00E5FF) : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
                child: Text(
                  'BAHÍA 0$bayNumber',
                  style: TextStyle(
                    color: isActive ? const Color(0xFF00E5FF) : (isDark ? Colors.white70 : Colors.black54),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'EN COCKPIT',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Tarjeta Pedestal del Vehículo
          Expanded(
            child: InkWell(
              onTap: () {
                if (!kIsWeb) HapticFeedback.heavyImpact();
                widget.onSelectVehicle(id);
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.90)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF00E5FF)
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: isActive ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: underglowColor.withValues(alpha: isActive ? 0.35 + pulse * 0.15 : 0.08),
                      blurRadius: isActive ? 30 : 12,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de Marca e Icono
                    Row(
                      children: [
                        Icon(
                          isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                          color: isActive ? const Color(0xFF00E5FF) : (isDark ? Colors.white70 : Colors.black87),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nickname.isNotEmpty ? nickname : '$brand $model',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Outfit',
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (plate.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                            ),
                            child: Text(
                              plate,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$brand $model',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),

                    // Pedestal Central con la Imagen del Vehículo
                    Expanded(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Sombra reflectiva en el piso del pedestal
                            Positioned(
                              bottom: 10,
                              child: Container(
                                width: 180,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: underglowColor.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (images360.isNotEmpty)
                              Showroom360Turntable(
                                imageUrls: images360,
                                isCar: isCar,
                              )
                            else if (bestImage != null && bestImage.isNotEmpty)
                              SmartVehicleImage(
                                imagePath: bestImage,
                                isCar: isCar,
                                fit: BoxFit.contain,
                              )
                            else
                              Icon(
                                isCar ? Icons.directions_car_filled : Icons.two_wheeler,
                                size: 80,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Ficha de Métricas: Kilometraje e Índice de Salud
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Odómetro',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                              Text(
                                '${AppFormat.thousandsOrRaw(kms.toString())} KM',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Salud ISH',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                              Text(
                                '${health.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: health > 70
                                      ? const Color(0xFF10B981)
                                      : (health > 40 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botón de Acción de Bahía
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!kIsWeb) HapticFeedback.heavyImpact();
                          widget.onSelectVehicle(id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive
                              ? const Color(0xFF00E5FF)
                              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          foregroundColor: isActive
                              ? Colors.black
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isActive ? 'SELECCIONADO' : 'ENCENDER / CAMBIAR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBay({
    required int bayNumber,
    required bool isDark,
    required double pulse,
    required bool isDesktop,
  }) {
    final cardWidth = isDesktop ? 360.0 : 290.0;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 28),
      child: Column(
        children: [
          // Header de Bahía Disponible
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'BAHÍA 0$bayNumber • LIBRE',
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bahía Holográfica Vacía (Requerimiento 1 & 2 Opción A)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0B101B).withValues(alpha: 0.70)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.35 + pulse * 0.25),
                  width: 1.8,
                  style: BorderStyle.solid,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15 + pulse * 0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Holograma pulsante central
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.08 + pulse * 0.10),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.30),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 50,
                        color: const Color(0xFFA78BFA).withValues(alpha: 0.85 + pulse * 0.15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Espacio Disponible',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aparca un nuevo vehículo en tu garaje',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Botones Rápidos para Moto y Carro
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onAddMoto,
                          icon: const Icon(Icons.two_wheeler_rounded, size: 16),
                          label: const Text('Moto'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00E5FF),
                            side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onAddCar,
                          icon: const Icon(Icons.directions_car_rounded, size: 16),
                          label: const Text('Carro'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFA78BFA),
                            side: const BorderSide(color: Color(0xFFA78BFA), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter que proyecta el piso de resina epoxi reflectiva y las marcas de bahía
class _ShowroomEpoxyFloorPainter extends CustomPainter {
  final bool isDark;
  final double pulse;

  _ShowroomEpoxyFloorPainter({required this.isDark, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gradiente ambiental de fondo con haz de luz cenital
    final centerSpotRect = Rect.fromCenter(
      center: Offset(w / 2, 0),
      width: w * 0.9,
      height: h * 1.4,
    );
    final spotPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF00E5FF) : const Color(0xFF3B82F6)).withValues(alpha: 0.08 + pulse * 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(centerSpotRect);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), spotPaint);

    // Cuadrícula perspectiva del suelo
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    final double step = 60.0;
    for (double x = 0; x <= w; x += step) {
      canvas.drawLine(Offset(x, h * 0.35), Offset(x, h), gridPaint);
    }
    for (double y = h * 0.35; y <= h; y += 45.0) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShowroomEpoxyFloorPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.isDark != isDark;
  }
}

/// Turntable 360 interactivo para el Showroom:
/// Rotación continua suave (~180ms/fotograma), precarga en memoria para cero parpadeo,
/// soporte de swipe manual y reanudación automática.
class Showroom360Turntable extends StatefulWidget {
  final List<String> imageUrls;
  final bool isCar;
  final Duration rotationInterval;

  const Showroom360Turntable({
    super.key,
    required this.imageUrls,
    required this.isCar,
    this.rotationInterval = const Duration(milliseconds: 180),
  });

  @override
  State<Showroom360Turntable> createState() => _Showroom360TurntableState();
}

class _Showroom360TurntableState extends State<Showroom360Turntable> {
  int _currentIndex = 0;
  Timer? _rotationTimer;
  Timer? _resumeTimer;
  double _dragStartX = 0.0;
  bool _isUserDragging = false;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _startAutoRotation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final url in widget.imageUrls) {
        precacheImage(NetworkImage(url), context).catchError((_) {});
      }
    }
  }

  void _startAutoRotation() {
    _rotationTimer?.cancel();
    if (widget.imageUrls.length <= 1) return;
    _rotationTimer = Timer.periodic(widget.rotationInterval, (_) {
      if (!_isUserDragging && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.imageUrls.length;
        });
      }
    });
  }

  void _handleDragStart(DragStartDetails details) {
    _isUserDragging = true;
    _dragStartX = details.localPosition.dx;
    _resumeTimer?.cancel();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.imageUrls.isEmpty) return;
    final double offset = details.localPosition.dx - _dragStartX;
    final int change = (offset / 14).round();
    if (change != 0) {
      setState(() {
        _currentIndex = (_currentIndex - change) % widget.imageUrls.length;
        if (_currentIndex < 0) _currentIndex += widget.imageUrls.length;
      });
      _dragStartX = details.localPosition.dx;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _isUserDragging = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _resumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    final currentImgUrl = widget.imageUrls[_currentIndex % widget.imageUrls.length];

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            currentImgUrl,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Icon(
              widget.isCar ? Icons.directions_car : Icons.two_wheeler,
              size: 80,
              color: Colors.white24,
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.threed_rotation_rounded,
                    size: 13,
                    color: _isUserDragging ? const Color(0xFF10B981) : const Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isUserDragging ? 'MANUAL' : '360° AUTO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: _isUserDragging ? const Color(0xFF10B981) : const Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
