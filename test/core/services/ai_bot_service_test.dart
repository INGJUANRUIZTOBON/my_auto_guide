import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/services/ai_bot_service.dart';

void main() {
  group('AIBotService validation', () {
    test('rejects empty text when no image is attached', () async {
      final service = AIBotService();
      service.resetChat();

      final res = await service.sendMessage('   ');
      expect(res, contains('escribe tu pregunta'));
    });

    test('rejects overly long messages before calling remote APIs', () async {
      final service = AIBotService();
      final longText = 'a' * 3001;

      final res = await service.sendMessage(longText);
      expect(res, contains('demasiado largo'));
    });
  });
}
