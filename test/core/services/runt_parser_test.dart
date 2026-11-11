import 'package:flutter_test/flutter_test.dart';
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
  });
}
