import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/services/runt_parser.dart';

void main() {
  group('RuntVehicleProfile', () {
    test('decodes double-serialized Android WebView JSON strings', () {
      final payload = jsonEncode(jsonEncode({
        'marca': 'TOYOTA',
        'linea': 'COROLLA CROSS',
        'modelo_ano': '2024',
        'color': 'GRIS METALICO',
        'cilindraje': '1798',
        'vin': '9BRK1234567890123',
        'soat_estado': 'VIGENTE',
        'soat_aseguradora': 'SEGUROS DEL ESTADO S.A.',
        'soat_vencimiento': '15/08/2027',
        'tecno_vencimiento': '20/09/2028',
      }));

      final profile = RuntVehicleProfile.tryDecodeWebViewResult(payload);
      expect(profile, isNotNull);
      expect(profile!.hasAnyData, isTrue);
      expect(profile.marca, 'TOYOTA');
      expect(profile.linea, 'COROLLA CROSS');
      expect(profile.soatAseguradora, 'SEGUROS DEL ESTADO S.A.');
      expect(
        RuntVehicleProfile.convertToIsoDate(profile.soatVencimiento),
        '2027-08-15',
      );
      expect(
        RuntVehicleProfile.convertToIsoDate(profile.tecnoVencimiento),
        '2028-09-20',
      );
    });

    test('returns null for malformed payloads', () {
      expect(RuntVehicleProfile.tryDecodeWebViewResult('invalid-json'), isNull);
      expect(RuntVehicleProfile.convertToIsoDate(''), isNull);
    });
  });
}
