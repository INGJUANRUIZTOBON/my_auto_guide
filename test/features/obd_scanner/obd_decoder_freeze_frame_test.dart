import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/features/obd_scanner/data/obd_decoder.dart';

void main() {
  group('ObdDecoder Freeze Frame (Mode 02)', () {
    test('Decodes Mode 02 RPM with frame 00 byte', () {
      // 42 0C 00 1A F8 -> RPM = ((0x1A * 256) + 0xF8) / 4 = 1726
      final decoded = ObdDecoder.decodeFreezeFrameResponse('42 0C 00 1A F8\r>');
      expect(decoded, isNotNull);
      expect(decoded!['type'], 'RPM');
      expect(decoded['value'], 1726);
    });

    test('Decodes Mode 02 Coolant temp with CAN header', () {
      // 7E8 04 42 05 00 7B -> Temp = 0x7B (123) - 40 = 83
      final decoded = ObdDecoder.decodeFreezeFrameResponse('7E8 04 42 05 00 7B');
      expect(decoded, isNotNull);
      expect(decoded!['type'], 'CoolantTemp');
      expect(decoded['value'], 83);
    });

    test('Returns null on NO DATA or ERROR', () {
      expect(ObdDecoder.decodeFreezeFrameResponse('NO DATA'), isNull);
      expect(ObdDecoder.decodeFreezeFrameResponse('CAN ERROR'), isNull);
    });
  });
}
