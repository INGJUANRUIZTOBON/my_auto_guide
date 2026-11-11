// =============================================================================
// ai_bot_service.dart — ASISTENTE IA MULTIMODAL (MASTER MECHANIC)
// =============================================================================
// Prioriza la Edge Function 'gemini-chat' de Supabase y, si aún no está
// desplegada en el proyecto remoto, usa fallback controlado vía Gemini 2.5 Flash
// para asegurar diagnóstico de texto e imágenes en todo momento.
// =============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AIBotService {
  static final AIBotService _instance = AIBotService._internal();
  factory AIBotService() => _instance;
  AIBotService._internal();

  static const String _systemPrompt =
      'Eres Master Mechanic, el asistente técnico automotriz de My Auto Guide. '
      'Responde siempre en español claro, directo y práctico sobre mecánica de '
      'carros y motos, mantenimiento preventivo, testigos del tablero, análisis '
      'visual de piezas o fugas en fotografías y uso de la aplicación. '
      'Cuando recibas una imagen: 1) describe qué componente o síntoma ves, '
      '2) indica nivel de riesgo (¿es seguro conducir?), y 3) da pasos o repuestos recomendados. '
      'Si preguntan algo fuera del ámbito vehicular, aclara amablemente tu especialidad.';

  static const List<String> _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];

  bool _initialized = false;
  final List<Map<String, String>> _history = [];

  void initialize({String? specificModel}) {
    _initialized = true;
  }

  Future<String> sendMessage(
    String text, {
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    if (!_initialized) initialize();

    final trimmed = text.trim();
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;

    if (trimmed.isEmpty && !hasImage) {
      return 'Por favor, escribe tu pregunta o adjunta una imagen.';
    }
    if (trimmed.length > 3000) {
      return 'El mensaje es demasiado largo. Por favor, acórtalo.';
    }

    final effectiveText = trimmed.isNotEmpty
        ? trimmed
        : 'Analiza esta imagen relacionada con mi vehículo. Identifica qué pieza, testigo o falla aparece y dime qué recomiendas hacer.';

    final String? base64Image = hasImage ? base64Encode(imageBytes) : null;

    // 1. Intento principal: Edge Function segura en Supabase
    final edgeResult = await _tryEdgeFunction(
      message: effectiveText,
      imageBase64: base64Image,
      mimeType: mimeType,
    );
    if (edgeResult.reply != null) {
      _recordTurn(effectiveText, edgeResult.reply!, hadImage: hasImage);
      return edgeResult.reply!;
    }
    if (edgeResult.hardStopMessage != null) {
      return edgeResult.hardStopMessage!;
    }

    // 2. Fallback directo con Gemini 2.5 Flash si la Edge Function no está desplegada (404/503)
    final directReply = await _tryDirectGemini(
      message: effectiveText,
      imageBase64: base64Image,
      mimeType: mimeType,
    );
    if (directReply != null) {
      _recordTurn(effectiveText, directReply, hadImage: hasImage);
      return directReply;
    }

    return 'No se pudo conectar con Master Mechanic IA. Verifica tu conexión a internet e intenta de nuevo.';
  }

  Future<({String? reply, String? hardStopMessage})> _tryEdgeFunction({
    required String message,
    String? imageBase64,
    required String mimeType,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'gemini-chat',
        body: {
          'message': message,
          'history': _history,
          if (imageBase64 != null) 'imageBase64': imageBase64,
          if (imageBase64 != null) 'mimeType': mimeType,
        },
      );

      if (response.status == 200) {
        final data = _decodeMap(response.data);
        final text = data?['text']?.toString().trim();
        if (text != null && text.isNotEmpty) {
          return (reply: text, hardStopMessage: null);
        }
      }

      if (response.status == 429) {
        return (
          reply: null,
          hardStopMessage:
              'Has alcanzado el límite de consultas por minuto. Espera un momento e intenta de nuevo.',
        );
      }
    } on FunctionException catch (e) {
      if (kDebugMode) {
        debugPrint('[AI] Edge Function status=${e.status}, usando fallback');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AI] Edge Function no disponible ($e), usando fallback');
      }
    }
    return (reply: null, hardStopMessage: null);
  }

  Future<String?> _tryDirectGemini({
    required String message,
    String? imageBase64,
    required String mimeType,
  }) async {
    final apiKey = (dotenv.env['GEMINI_API_KEY'] ??
            const String.fromEnvironment('GEMINI_API_KEY'))
        .trim();
    if (apiKey.isEmpty) {
      if (kDebugMode) debugPrint('[AI] GEMINI_API_KEY no configurada en .env');
      return null;
    }

    final contents = <Map<String, dynamic>>[
      for (final item in _history)
        {
          'role': item['role'] == 'model' ? 'model' : 'user',
          'parts': [
            {'text': item['text'] ?? ''}
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': message},
          if (imageBase64 != null)
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': imageBase64,
              },
            },
        ],
      },
    ];

    final payload = jsonEncode({
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt}
        ],
      },
    });

    for (final model in _fallbackModels) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        final res = await http
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(seconds: 35));

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List?;
          final parts = candidates?.firstOrNull?['content']?['parts'] as List?;
          final text = parts?.firstOrNull?['text']?.toString().trim();
          if (text != null && text.isNotEmpty) {
            return text;
          }
        } else if (kDebugMode) {
          debugPrint('[AI] Modelo $model respondió HTTP ${res.statusCode}');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[AI] Error con modelo $model: $e');
      }
    }
    return null;
  }

  Map<String, dynamic>? _decodeMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  void _recordTurn(String userText, String modelText, {bool hadImage = false}) {
    _history.add({
      'role': 'user',
      'text': hadImage ? '[Imagen adjunta] $userText' : userText,
    });
    _history.add({'role': 'model', 'text': modelText});
    if (_history.length > 8) {
      _history.removeRange(0, _history.length - 8);
    }
  }

  void resetChat() {
    _history.clear();
    initialize();
  }
}
