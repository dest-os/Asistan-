import 'package:flutter/material.dart';
import '../services/ai_voice_service.dart';
import '../services/speech_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AiVoiceService _voiceService = AiVoiceService();
  final SpeechService _speechService = SpeechService();
  final TextEditingController _textController = TextEditingController();

  final List<Map<String, String>> _messages = [
    {
      "sender": "assistant",
      "text": "Merhaba! Ben senin yapay zeka destekli erkek sesli asistanınım. Sana nasıl yardımcı olabilirim?"
    }
  ];

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechService.initSpeech();
    
    // Açılışta asistanın konuşması
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _voiceService.speakWithMaleVoice(_messages.first["text"]!);
    });
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage(String userText) {
    if (userText.trim().isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": userText});
      _textController.clear();
    });

    // Basit Yapay Zeka Cevap Mantığı (Kendi AI API'nizi veya kurallarınızı bağlayabilirsiniz)
    String reply = "Söylediklerinizi anladım. Size bu konuda yardımcı olmaktan memnuniyet duyarım.";
    
    final lower = userText.toLowerCase();
    if (lower.contains("merhaba") || lower.contains("selam")) {
      reply = "Merhaba efendim, hoş geldiniz! Bugün sizin için ne yapabilirim?";
    } else if (lower.contains("nasılsın")) {
      reply = "Çok iyiyim, teşekkür ederim. Sizinle çalışmak benim için bir keyif.";
    } else if (lower.contains("adın ne") || lower.contains("kimsin")) {
      reply = "Ben sizin Türkçe erkek sesli akıllı kişisel asistanınızım.";
    } else if (lower.contains("saat kaç")) {
      final now = DateTime.now();
      reply = "Şu an saat ${now.hour} ${now.minute}.";
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _messages.add({"sender": "assistant", "text": reply});
      });
      // Ücretsiz erkek sesiyle cevap verme
      _voiceService.speakWithMaleVoice(reply);
    });
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _textController.text = text;
          });
          if (!_speechService.isListening) {
            setState(() => _isListening = false);
            _sendMessage(text);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Erkek Sesli AI Asistan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_off, color: Colors.white70),
            onPressed: () => _voiceService.stop(),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                FloatingActionButton.small(
                  backgroundColor: _isListening ? Colors.red : const Color(0xFF3B82F6),
                  onPressed: _toggleListening,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Mesajınızı yazın veya mikrofona basın...",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF3B82F6)),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
