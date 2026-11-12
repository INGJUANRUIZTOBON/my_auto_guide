import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/services/driver_license_parser.dart';

void main() {
  group('RuntDriverProfile license parser', () {
    test('Extracts multiple categories, active vs expired status and earliest expiration', () {
      const sampleCitizenRunt = '''
        RUNTPRO Transporte
        Nombre completo: JUAN DAVID RUIZ TOBON
        Número de documento: 10025135253
        Estado del conductor: ACTIVO
        Licencias de conducción
        Número de licencia: 10025135253
        Categoría: A2
        Estado: ACTIVA
        Fecha de expedición: 14/09/2021
        Fecha de vencimiento: 14/09/2031
        Organismo de tránsito: SECRETARIA DE MOVILIDAD BOGOTA
        Número de licencia: 10025135253
        Categoría: B1
        Estado: ACTIVA
        Fecha de expedición: 14/09/2021
        Fecha de vencimiento: 14/09/2033
        Número de licencia: 99887766
        Categoría: C1
        Estado: VENCIDA
        Fecha de expedición: 01/03/2020
        Fecha de vencimiento: 01/03/2023
      ''';

      final profile = RuntDriverProfile.parseFromRawText(sampleCitizenRunt);

      expect(profile.hasAnyData, isTrue);
      expect(profile.nombreConductor, 'JUAN DAVID RUIZ TOBON');
      expect(profile.estadoConductor, 'ACTIVO');
      expect(profile.licencias.length, 3);
      expect(profile.vigentes.length, 2);
      expect(profile.vigentes.map((e) => e.categoria).toList(), ['A2', 'B1']);
      expect(profile.earliestExpiration, DateTime(2031, 9, 14));
    });

    test('Parses tabular single-line categories and marks expired date as not vigente even if labeled ACTIVA', () {
      const raw = '''
        A2 ACTIVA 10/01/2020 10/01/2022
        B1 ACTIVA 10/01/2025 10/01/2035
      ''';

      final profile = RuntDriverProfile.parseFromRawText(raw);
      expect(profile.licencias.length, 2);
      expect(profile.licencias[0].isVigente, isFalse);
      expect(profile.licencias[1].isVigente, isTrue);
      expect(profile.vigentes.length, 1);
      expect(profile.vigentes.first.categoria, 'B1');
    });

    test('Parses RUNTPRO Ver Detalle popup stacked layout for A2, C1, B1 accurately', () {
      const mobilePopupDump = '''
        1002579736 STRIA MCPAL TTOyTTE ESPINAL 01/12/2021 ACTIVA NO Ver Detalle
        Categorías de la licencia Nro: 1002579736
        A2
        01/12/2021
        01/12/2031
        C1
        01/12/2021
        01/12/2024
        B1
        01/12/2021
        01/12/2031
      ''';

      final profile = RuntDriverProfile.parseFromRawText(mobilePopupDump);
      expect(profile.licencias.length, 3);
      expect(profile.licencias.map((l) => l.categoria).toList(), ['A2', 'C1', 'B1']);
      // A2 (2031) y B1 (2031) vigentes, C1 (2024) vencida
      expect(profile.licencias[0].isVigente, isTrue);
      expect(profile.licencias[1].isVigente, isFalse);
      expect(profile.licencias[2].isVigente, isTrue);
      expect(profile.vigentes.length, 2);
      expect(profile.earliestExpiration, DateTime(2031, 12, 1));
    });

    test('Parses mobile stacked cards without colons and interleaved field labels', () {
      const mobileCardDump = '''
        NOMBRE COMPLETO
        J****N D****O R****Z T****N
        DOCUMENTO
        C.C. 1002579736
        ESTADO DEL CONDUCTOR
        ACTIVO
        NÚMERO DE INSCRIPCIÓN
        20290929
        Categorías de la licencia Nro: 1002579736
        Categoría
        A2
        Fecha expedición
        01/12/2021
        Fecha vencimiento
        01/12/2031
        Categoría
        B1
        Fecha expedición
        01/12/2021
        Fecha vencimiento
        01/12/2031
      ''';

      final profile = RuntDriverProfile.parseFromRawText(mobileCardDump);
      expect(profile.nombreConductor, contains('R****Z'));
      expect(profile.estadoConductor, 'ACTIVO');
      expect(profile.numeroInscripcion, '20290929');
      expect(profile.licencias.length, 2);
      expect(profile.vigentes.length, 2);
      expect(profile.earliestExpiration, DateTime(2031, 12, 1));
    });
  });
}
