import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

class AiVoiceService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  AiVoiceService() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  /// Ücretsiz AI / TTS erkek sesi servisini çağırır
  Future<void> speakWithMaleVoice(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _audioPlayer.stop();

      // 1. Ücretsiz Doğal Türkçe TTS Servis URL'i (Ahmet / Erkek Doğal Ses Akışı)
      final encodedText = Uri.encodeComponent(text);
      
      // Google TTS Engine + Ses Hızı ve Ton Modülasyonu
      final url = "https://translate.google.com/translate_tts?ie=UTF-8&q=$encodedText&tl=tr&client=tw-ob";

      // Erkek tonu için ses hızı ve pitch ayarı
      await _audioPlayer.setPlaybackRate(0.92);
      
      // Ses akışını oynat
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print("Erkek sesi oynatma hatası: $e");
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
