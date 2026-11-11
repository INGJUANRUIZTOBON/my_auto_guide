import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/ai_bot_service.dart';
import '../../../shared/widgets/app_snack_bar.dart';

class _ChatMessage {
  final bool isBot;
  final String text;
  final Uint8List? imageBytes;

  const _ChatMessage({
    required this.isBot,
    required this.text,
    this.imageBytes,
  });
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isBot: true,
      text:
          '¡Hola! Soy **Master Mechanic**, tu asistente experto de My Auto Guide. '
          'Escríbeme tu duda o envíame una **foto de una pieza, testigo del tablero o fuga** para analizarla.',
    ),
  ];

  bool _isTyping = false;
  Uint8List? _pendingImageBytes;
  String _pendingMimeType = 'image/jpeg';

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isTyping) return;
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      final lower = file.path.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';

      if (!mounted) return;
      setState(() {
        _pendingImageBytes = bytes;
        _pendingMimeType = mime;
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        'No se pudo acceder a la ${source == ImageSource.camera ? "cámara" : "galería"}. Verifica los permisos.',
      );
    }
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF38BDF8)),
                title: const Text('Tomar foto ahora'),
                subtitle: const Text('Captura un testigo, pieza o fuga con tu cámara'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF38BDF8)),
                title: const Text('Elegir imagen de la galería'),
                subtitle: const Text('Sube una fotografía guardada en tu teléfono'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    final imageBytes = _pendingImageBytes;
    final mimeType = _pendingMimeType;

    if ((text.isEmpty && imageBytes == null) || _isTyping) return;

    final displayText = text.isNotEmpty
        ? text
        : '¿Qué observas en esta imagen? Analiza el estado o posible falla.';

    setState(() {
      _messages.add(
        _ChatMessage(
          isBot: false,
          text: displayText,
          imageBytes: imageBytes,
        ),
      );
      _msgCtrl.clear();
      _pendingImageBytes = null;
      _isTyping = true;
    });
    _scrollToBottom();

    final response = await AIBotService().sendMessage(
      text,
      imageBytes: imageBytes,
      mimeType: mimeType,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(isBot: true, text: response));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openImagePreview(Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Mechanic IA', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF080C14)]
                  : [Colors.blue.shade800, Colors.blue.shade600],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reiniciar chat',
            onPressed: () {
              AIBotService().resetChat();
              setState(() {
                _pendingImageBytes = null;
                _messages
                  ..clear()
                  ..add(
                    const _ChatMessage(
                      isBot: true,
                      text: 'Conversación reiniciada. ¿Tienes alguna otra duda o foto para revisar?',
                    ),
                  );
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF080C14) : Colors.grey.shade50,
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _ChatBubble(
                  message: _messages[i],
                  onImageTap: _openImagePreview,
                ),
              ),
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: _TypingIndicator(),
            ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pendingImageBytes != null)
              _PendingImageBanner(
                bytes: _pendingImageBytes!,
                isDark: isDark,
                onRemove: () => setState(() => _pendingImageBytes = null),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.camera_alt_rounded,
                    color: isDark ? const Color(0xFF38BDF8) : Colors.blue.shade700,
                  ),
                  tooltip: 'Tomar foto',
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_photo_alternate_rounded,
                    color: isDark ? const Color(0xFF38BDF8) : Colors.blue.shade700,
                  ),
                  tooltip: 'Subir imagen',
                  onPressed: _showImageSourceSheet,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: _pendingImageBytes != null
                          ? 'Pregunta sobre esta imagen...'
                          : 'Pregunta sobre tu vehículo...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue.shade700,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingImageBanner extends StatelessWidget {
  final Uint8List bytes;
  final bool isDark;
  final VoidCallback onRemove;

  const _PendingImageBanner({
    required this.bytes,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Imagen adjunta. Escribe tu pregunta o envíala directo.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.blue.shade900,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final ValueChanged<Uint8List> onImageTap;

  const _ChatBubble({
    required this.message,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBot = message.isBot;

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isBot
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.blue.shade600,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isBot ? 0 : 20),
            bottomRight: Radius.circular(isBot ? 20 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageBytes != null) ...[
              GestureDetector(
                onTap: () => onImageTap(message.imageBytes!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    message.imageBytes!,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: isBot
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.white,
                  fontSize: 15,
                ),
                strong: TextStyle(
                  color: isBot
                      ? (isDark ? const Color(0xFF38BDF8) : Colors.blue.shade900)
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: 20),
        Text(
          'Master Mechanic está pensando...',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
