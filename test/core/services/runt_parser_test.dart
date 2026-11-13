import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/logic/vehicle_health_logic.dart';
import 'package:my_auto_guide/core/services/runt_parser.dart';

void main() {
  group('RuntVehicleProfile RUNTPRO extraction', () {
    test('Extracts stacked and inline fields from RUNTPRO portal text (moto screenshot)', () {
      const sampleRuntProText = '''
        RUNTPRO Transporte
        PLACA DEL VEHÍCULO:
        AGI18G
        NRO. DE LICENCIA DE TRÁNSITO:
        10025135253
        ESTADO DEL VEHÍCULO:
        ACTIVO
        TIPO DE SERVICIO:
        Particular
        CLASE DE VEHÍCULO:
        MOTOCICLETA
        Información general del vehículo
        Marca: BAJAJ
        Línea: PULSAR NS 200 FI
        Modelo: 2023
        Color: NEGRO NEBULOSA
        Cilindraje: 199
        Tipo de combustible: GASOLINA
        Póliza SOAT
        Estado: VIGENTE
        Entidad que expide el SOAT: SEGUROS DEL ESTADO S.A.
        Fecha de expedición: 12/04/2026
        Fecha fin de vigencia: 12/04/2027
        Revisión Técnico-Mecánica (RTM)
        Estado: VIGENTE
        CDA: CDA MOTOS BOGOTA S.A.S
        Fecha de vigencia: 10/08/2027
      ''';

      final profile = RuntVehicleProfile.parseFromRawText(sampleRuntProText);

      expect(profile.hasAnyData, isTrue);
      expect(profile.estadoVehiculo, 'ACTIVO');
      expect(profile.servicio, 'Particular');
      expect(profile.clase, 'MOTOCICLETA');
      expect(profile.marca, 'BAJAJ');
      expect(profile.linea, 'PULSAR NS 200 FI');
      expect(profile.modeloAno, '2023');
      expect(profile.cilindraje, '199');
      expect(profile.soatEstado, 'VIGENTE');
      expect(profile.soatAseguradora, 'SEGUROS DEL ESTADO S.A.');
      expect(profile.soatVencimiento, '12/04/2027');
      expect(profile.tecnoEstado, 'VIGENTE');
      expect(profile.tecnoVencimiento, '10/08/2027');
    });

    test('tryDecodeWebViewResult merges empty DOM fields with raw_text fallback', () {
      const webViewJson = '''
        {
          "marca": "",
          "linea": "",
          "soat_vencimiento": "",
          "raw_text": "CLASE DE VEHÍCULO:\\nMOTOCICLETA\\nMarca: BAJAJ\\nLínea: PULSAR NS 200 FI"
        }
      ''';

      final decoded = RuntVehicleProfile.tryDecodeWebViewResult(webViewJson);
      expect(decoded, isNotNull);
      expect(decoded!.hasAnyData, isTrue);
      expect(decoded.marca, 'BAJAJ');
      expect(decoded.linea, 'PULSAR NS 200 FI');
      expect(decoded.clase, 'MOTOCICLETA');
    });

    test('resolveStartIsoDate prefers inicio de vigencia over fin de vigencia', () {
      expect(
        RuntVehicleProfile.resolveStartIsoDate(
          inicio: '15/10/2026',
          expedicion: '10/10/2026',
          vencimiento: '15/10/2027',
        ),
        '2026-10-15',
      );
      expect(
        RuntVehicleProfile.resolveStartIsoDate(
          inicio: '',
          expedicion: '',
          vencimiento: '12/06/2027',
        ),
        '2026-06-12',
      );
    });

    test('calculateDocumentPercentage calculates proportional remaining life for both past start dates and future expiry dates', () {
      final halfYearAgo = DateTime.now().subtract(const Duration(days: 182));
      final pctFromStart = VehicleHealthLogic.calculateDocumentPercentage(date: halfYearAgo);
      expect(pctFromStart, closeTo(0.50, 0.03));

      final halfYearAhead = DateTime.now().add(const Duration(days: 182));
      final pctFromFuture = VehicleHealthLogic.calculateDocumentPercentage(date: halfYearAhead);
      expect(pctFromFuture, closeTo(0.50, 0.03));
    });

    test('sanitizeField removes Material icon ligature noise from RUNTPRO innerText', () {
      expect(RuntVehicleProfile.sanitizeField('check_circle VIGENTE'), 'VIGENTE');
      expect(RuntVehicleProfile.sanitizeField('car_crash • Vence: 12/06/2027'), 'Vence: 12/06/2027');
    });

    test('Extracts clase, servicio, SOAT and RTM with alternate headers and tabular dates without colons', () {
      const alternateRuntText = '''
        Información del Automotor
        Placa: XYZ123
        Clase: AUTOMOVIL
        Servicio: PARTICULAR
        Marca: MAZDA
        Línea: CX-30
        Modelo: 2024
        
        SEGURO OBLIGATORIO (SOAT)
        Nro Poliza   Aseguradora             Fecha Inicio  Fecha Vencimiento  Estado
        882910291    SEGUROS DEL ESTADO      20/05/2024    20/05/2025         VIGENTE

        REVISION TECNICOMECANICA Y DE EMISIONES
        Certificado  CDA                     Expedicion    Vencimiento        Estado
        9948210      CDA DEL NORTE S.A.S.    15/01/2024    15/01/2025         VIGENTE
      ''';

      final profile = RuntVehicleProfile.parseFromRawText(alternateRuntText);

      expect(profile.clase, 'AUTOMOVIL');
      expect(profile.servicio, 'PARTICULAR');
      expect(profile.marca, 'MAZDA');
      expect(profile.linea, 'CX-30');
      expect(profile.soatVencimiento, '20/05/2025');
      expect(profile.soatInicioVigencia, '20/05/2024');
      expect(profile.soatEstado, 'VIGENTE');
      expect(profile.tecnoVencimiento, '15/01/2025');
      expect(profile.tecnoInicioVigencia, '15/01/2024');
      expect(profile.tecnoEstado, 'VIGENTE');
    });
  });
}
