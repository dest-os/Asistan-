import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SohbetEkrani extends StatefulWidget {
  const SohbetEkrani({super.key});

  @override
  State<SohbetEkrani> createState() => _SohbetEkraniState();
}

class _SohbetEkraniState extends State<SohbetEkrani> with TickerProviderStateMixin {
  String _bgImage = 'assets/erkek_ares_ekrani.png';
  String _kullaniciAdi = 'İbrahim';
  String _hitapSekli = 'Efendim';
  String _karakter = 'ERKEK';
  bool _yuklendi = false;

  // Kişiselleştirme & Erişilebilirlik
  double _yaziBoyutu = 18.0;
  double _konusmaHizi = 0.46;
  double _sesTonu = 0.52;

  // Depolama Dizinleri
  String _arsivYolu = "Dahili Hafıza / ARES / Arsiv";
  String _notlarYolu = "Dahili Hafıza / ARES / Notlar";
  String _egitimYolu = "Dahili Hafıza / ARES / Egitim";

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  String _metin = "Seni dinliyorum Efendim...";
  bool _sessizMod = false;
  bool _dinliyor = false;
  bool _konusuyor = false;
  bool _isProcessing = false;
  bool _yaziVar = false;
  double _sesSeviyesi = 0.0;
  bool _isSpeechInitialized = false;

  List<String> _ozelAraclar = [];
  List<Map<String, dynamic>> _kayitliApiler = [];
  List<Map<String, dynamic>> _dinamikOzelModuller = [];
  final Map<String, String> _apiDurumlari = {};

  late AnimationController _spectrumController;
  late AnimationController _pulseController;

  // ============================================================
  // 📚 DÜNYADAKİ YAPAY ZEKALAR KATALOĞU
  // ============================================================
  final List<Map<String, String>> _hazirKatalog = [
    {
      "id": "google",
      "firma": "Google Gemini (1.5 / 2.0 Flash)",
      "kategori": "ÜCRETSİZ / GENİŞ KOTA",
      "adres": "https://generativelanguage.googleapis.com",
      "uzmanlik": "Metin, Görsel Analiz, Kodlama, Çeviri, Mantık",
      "link": "https://aistudio.google.com/app/apikey"
    },
    {
      "id": "groq",
      "firma": "Groq (Llama 3.3 70B)",
      "kategori": "ÜCRETSİZ / ULTRA HIZLI",
      "adres": "https://api.groq.com/openai/v1",
      "uzmanlik": "Işık Hızında Çıkarım, Kodlama, Sohbet",
      "link": "https://console.groq.com/keys"
    },
    {
      "id": "nvidia",
      "firma": "NVIDIA NIM (Llama 3.1 & Nemotron)",
      "kategori": "1 YIL ÜCRETSİZ / GÜÇLÜ OMURGA",
      "adres": "https://integrate.api.nvidia.com",
      "uzmanlik": "Kodlama, Taktiksel Analiz, Yazılım, Mantık",
      "link": "https://build.nvidia.com"
    },
    {
      "id": "openai",
      "firma": "OpenAI (GPT-4o & GPT-4o-mini)",
      "kategori": "SÜRE SINIRLI / DENEME KREDİSİ",
      "adres": "https://api.openai.com/v1",
      "uzmanlik": "Genel Zeka, Mantık, Çeviri, Veri Analizi",
      "link": "https://platform.openai.com/api-keys"
    },
    {
      "id": "anthropic",
      "firma": "Anthropic (Claude 3.5 Sonnet)",
      "kategori": "SÜRE SINIRLI / DENEME KREDİSİ",
      "adres": "https://api.anthropic.com/v1",
      "uzmanlik": "İleri Düzey Kodlama, Edebi Yazım, Mimari",
      "link": "https://console.anthropic.com/settings/keys"
    },
    {
      "id": "deepseek",
      "firma": "DeepSeek (V3 & R1)",
      "kategori": "DÜŞÜK MALİYETLİ / GELİŞMİŞ AKIL",
      "adres": "https://api.deepseek.com/v1",
      "uzmanlik": "Derin Matematik, Yazılım Mimarisi, Mantık",
      "link": "https://platform.deepseek.com"
    },
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();

    _spectrumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _textController.addListener(() {
      final textVar = _textController.text.trim().isNotEmpty;
      if (textVar != _yaziVar) {
        setState(() => _yaziVar = textVar);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _yukle();
    });
  }

  @override
  void dispose() {
    _spectrumController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _sesMotorunuAyarla(String karakter) async {
    try {
      await _tts.setLanguage("tr-TR");
      await _tts.awaitSpeakCompletion(true);

      if (karakter == 'ERKEK') {
        await _tts.setPitch(_sesTonu); // Tok erkek sesi
        await _tts.setSpeechRate(_konusmaHizi);
      } else {
        await _tts.setPitch(1.08); // Kadın sesi
        await _tts.setSpeechRate(_konusmaHizi);
      }

      List<dynamic>? voices = await _tts.getVoices;
      if (voices != null) {
        for (var v in voices) {
          if (v is Map) {
            String name = (v["name"] ?? "").toString().toLowerCase();
            String locale = (v["locale"] ?? "").toString().toLowerCase();

            if (locale.contains("tr")) {
              if (karakter == 'ERKEK' && (name.contains("male") || name.contains("tr-tr-x-cfz") || name.contains("tr-tr-x-c") || name.contains("efz"))) {
                await _tts.setVoice({"name": v["name"].toString(), "locale": v["locale"].toString()});
                break;
              } else if (karakter == 'KADIN' && (name.contains("female") || name.contains("tr-tr-x-dfz") || name.contains("tr-tr-x-d") || name.contains("dfz"))) {
                await _tts.setVoice({"name": v["name"].toString(), "locale": v["locale"].toString()});
                break;
              }
            }
          }
        }
      }
    } catch (_) {}

    _tts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _konusuyor = true;
          _dinliyor = false;
        });
      }
    });

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _konusuyor = false;
          _isProcessing = false;
        });

        if (!_sessizMod) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && !_sessizMod && !_konusuyor && !_isProcessing) {
              _dinlemeBaslat();
            }
          });
        }
      }
    });

    _tts.setErrorHandler((_) {
      if (mounted) {
        setState(() {
          _konusuyor = false;
          _isProcessing = false;
        });
      }
    });
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    _karakter = prefs.getString('secilen_karakter') ?? 'ERKEK';

    String kayitliIsim = prefs.getString('kullanici_adi') ?? 'İbrahim';
    if (kayitliIsim.contains("import") || kayitliIsim.contains("dart:") || kayitliIsim.length > 20) {
      kayitliIsim = 'İbrahim';
      await prefs.setString('kullanici_adi', 'İbrahim');
    }

    String kayitliHitap = prefs.getString('hitap_sekli') ?? 'Efendim';
    if (kayitliHitap.contains("import") || kayitliHitap.contains("dart:") || kayitliHitap.length > 15) {
      kayitliHitap = 'Efendim';
      await prefs.setString('hitap_sekli', 'Efendim');
    }

    _hitapSekli = kayitliHitap;
    _yaziBoyutu = prefs.getDouble('yazi_boyutu') ?? 18.0;
    _konusmaHizi = prefs.getDouble('konusma_hizi') ?? 0.46;
    _sesTonu = prefs.getDouble('ses_tonu') ?? 0.52;

    List<String> eklenenler = prefs.getStringList('ozel_eklenen_araclar') ?? [];
    _arsivYolu = prefs.getString('arsiv_kayit_yolu') ?? "Dahili Hafıza / ARES / Arsiv";
    _notlarYolu = prefs.getString('notlar_kayit_yolu') ?? "Dahili Hafıza / ARES / Notlar";
    _egitimYolu = prefs.getString('egitim_kayit_yolu') ?? "Dahili Hafıza / ARES / Egitim";

    String? apilerJson = prefs.getString('kayitli_api_havuzu');
    if (apilerJson != null) {
      try {
        _kayitliApiler = List<Map<String, dynamic>>.from(json.decode(apilerJson));
      } catch (_) {}
    }

    String? modullerJson = prefs.getString('dinamik_ozel_moduller');
    if (modullerJson != null) {
      try {
        _dinamikOzelModuller = List<Map<String, dynamic>>.from(json.decode(modullerJson));
      } catch (_) {}
    }

    await _sesMotorunuAyarla(_karakter);

    if (mounted) {
      setState(() {
        _bgImage = (_karakter == 'KADIN')
            ? 'assets/kadin_ares_ekrani.png'
            : 'assets/erkek_ares_ekrani.png';
        _kullaniciAdi = kayitliIsim;
        _metin = "Seni dinliyorum $_hitapSekli...";
        _ozelAraclar = eklenenler;
        _yuklendi = true;
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_sessizMod && !_konusuyor) {
          _dinlemeBaslat();
        }
      });
    }
  }

  Future<void> _karakterDegistir(String yeniKarakter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secilen_karakter', yeniKarakter);
    _karakter = yeniKarakter;
    await _sesMotorunuAyarla(yeniKarakter);
    if (mounted) {
      setState(() {
        _bgImage = (_karakter == 'KADIN')
            ? 'assets/kadin_ares_ekrani.png'
            : 'assets/erkek_ares_ekrani.png';
        _metin = "$_karakter ARES aktif edildi $_hitapSekli.";
      });
    }
  }

  bool _apiKayitliMi(String firmaAdi) {
    String f = firmaAdi.toLowerCase();
    for (var api in _kayitliApiler) {
      String kayitli = (api["firma"] ?? "").toString().toLowerCase();
      if (f.contains("google") && (kayitli.contains("google") || kayitli.contains("gemini"))) return true;
      if (f.contains("groq") && kayitli.contains("groq")) return true;
      if (f.contains("nvidia") && (kayitli.contains("nvidia") || kayitli.contains("llama"))) return true;
      if (f.contains("openai") && kayitli.contains("openai")) return true;
      if (f.contains("anthropic") && (kayitli.contains("anthropic") || kayitli.contains("claude"))) return true;
      if (f.contains("deepseek") && kayitli.contains("deepseek")) return true;
    }
    return false;
  }

  // ============================================================
  // 🏛️ YAPAY ZEKA ÇAĞRI MOTORLARI
  // ============================================================

  // 1. Google Gemini Çağrısı (1.5 Flash / 2.0 Flash)
  Future<String?> _googleGeminiCagrisi(String apiKey, String soru) async {
    final cleanKey = apiKey.trim();
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$cleanKey");

    String sistemPrompt = "Sen ARES adlı üst düzey yapay zeka asistanısın. "
        "Kullanıcıya '$_hitapSekli' diye hitap et. "
        "Kullanıcının sorusuna doğrudan, net, akıcı ve mükemmel Türkçe cevap ver.";

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": "$sistemPrompt\n\nKullanıcı: $soru"}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.6,
            "maxOutputTokens": 800,
          }
        }),
      ).timeout(const Duration(seconds: 14));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"]?.toString().trim();
      } else {
        _apiDurumlari["google"] = "Hata ${response.statusCode}";
        return null;
      }
    } catch (_) {
      _apiDurumlari["google"] = "Bağlantı Hatası";
      return null;
    }
  }

  // 2. Groq / NVIDIA / OpenAI Uyumluluk Çağrısı
  Future<String?> _openAiUyumlulukCagrisi(String baseUrl, String apiKey, String model, String soru) async {
    final cleanKey = apiKey.trim();
    String endpoint = baseUrl.trim();
    if (!endpoint.endsWith("/chat/completions")) {
      endpoint = endpoint.endsWith("/") ? "${endpoint}chat/completions" : "$endpoint/chat/completions";
    }

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $cleanKey",
        },
        body: json.encode({
          "model": model,
          "messages": [
            {
              "role": "system",
              "content": "Sen ARES adlı siberpunk yapay zekasın. Kullanıcıya '$_hitapSekli' diye hitap et. Doğrudan Türkçe yanıt ver."
            },
            {"role": "user", "content": soru}
          ],
          "max_tokens": 800,
        }),
      ).timeout(const Duration(seconds: 14));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data["choices"]?[0]?["message"]?["content"]?.toString().trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // 🎙️ YEREL DİYALOG AYIKLAMA (API'YE GİTMEZ)
  // ============================================================
  String? _yerelSelamlasmaMi(String soru) {
    String s = soru.toLowerCase().replaceAll(RegExp(r'[^\w\sğüşıöçĞÜŞİÖÇ]'), '').trim();

    if (s == "ares" || s.contains("merhaba") || s.contains("selam") || s.contains("hey ares")) {
      return "Efendim, sistemlerim aktif. Sizin için ne yapabilirim?";
    }
    if (s.contains("nasılsın") || s.contains("durumun") || s.contains("sistem durumu")) {
      return "Teşekkür ederim $_hitapSekli, tüm modüllerim devrede ve emrinizdeyim.";
    }
    if (s.contains("orada mısın") || s.contains("dinliyor musun") || s.contains("beni duyuyor")) {
      return "Buradayım ve dinliyorum $_hitapSekli. Emrinizdeyim.";
    }
    if (s.contains("saat kaç")) {
      final now = DateTime.now();
      return "Şu an saat ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $_hitapSekli.";
    }
    if (s.contains("kimsin") || s.contains("adın ne") || s.contains("sen kimsin")) {
      return "Ben ARES, kişisel siberpunk yapay zekâ asistanınızım $_hitapSekli.";
    }
    return null;
  }

  Future<String> _soruyuYapayZekayaSor(String soru) async {
    if (_kayitliApiler.isEmpty) {
      return "Efendim, henüz sisteme bir API anahtarı tanımlanmadı. Lütfen sol üstteki Ayarlar menüsünden Yapay Zekâ Havuzu'na girip Google Gemini veya Groq anahtarınızı ekleyin.";
    }

    String? sonuc;

    for (var api in _kayitliApiler) {
      String firma = (api["firma"] ?? "").toString().toLowerCase();
      String anahtar = (api["anahtar"] ?? "").toString().trim();
      String adres = (api["adres"] ?? "").toString().trim();

      if (anahtar.isEmpty) continue;

      if (firma.contains("google") || firma.contains("gemini") || anahtar.startsWith("AIza")) {
        sonuc = await _googleGeminiCagrisi(anahtar, soru);
        if (sonuc != null && sonuc.isNotEmpty) return sonuc;
      } else if (firma.contains("groq")) {
        sonuc = await _openAiUyumlulukCagrisi("https://api.groq.com/openai/v1", anahtar, "llama-3.3-70b-versatile", soru);
        if (sonuc != null && sonuc.isNotEmpty) return sonuc;
      } else if (firma.contains("nvidia")) {
        sonuc = await _openAiUyumlulukCagrisi("https://integrate.api.nvidia.com/v1", anahtar, "meta/llama-3.1-70b-instruct", soru);
        if (sonuc != null && sonuc.isNotEmpty) return sonuc;
      } else if (adres.isNotEmpty && adres.startsWith("http")) {
        sonuc = await _openAiUyumlulukCagrisi(adres, anahtar, "gpt-3.5-turbo", soru);
        if (sonuc != null && sonuc.isNotEmpty) return sonuc;
      }
    }

    return "Efendim, kayıtlı API anahtarınız sunucu tarafından reddedildi veya kota doldu. Lütfen Ayarlar -> Yapay Zeka Havuzu'ndan geçerli bir Google veya Groq anahtarı giriniz.";
  }

  // ============================================================
  // 🎙️ SESLİ VE DOKUNMATİK ÇİFTE KOMUT MOTORU
  // ============================================================
  bool _sesliSistemKomutuMu(String girdi) {
    String k = girdi.toLowerCase().trim();

    if (k.contains("ayarları aç") || k.contains("ayar menüsü") || k.contains("ayarlar paneli")) {
      _ayarlarPaneliniAc();
      return true;
    }
    if (k.contains("api ekle") || k.contains("yapay zeka havuzu") || k.contains("api havuzu")) {
      _apiHavuzuPopUpAc();
      return true;
    }
    if (k.contains("sistem ayarları") || k.contains("kişiselleştirme")) {
      _sistemAyarlariPopUpAc();
      return true;
    }
    if (k.contains("kadın ares") || k.contains("kadına geç")) {
      _karakterDegistir('KADIN');
      return true;
    }
    if (k.contains("erkek ares") || k.contains("erkeğe geç")) {
      _karakterDegistir('ERKEK');
      return true;
    }
    if (k.contains("sessiz moda geç") || k.contains("mikrofonu kapat")) {
      _sessizModaAl();
      return true;
    }
    if (k.contains("sesli moda geç") || k.contains("mikrofonu aç")) {
      _sesliModaAl();
      return true;
    }
    return false;
  }

  Future<void> _dinlemeBaslat() async {
    if (_sessizMod || _konusuyor || _isProcessing) return;

    try {
      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speech.initialize(
          onStatus: (status) {
            if (mounted) {
              setState(() {
                _dinliyor = (status == 'listening');
              });
            }
          },
          onError: (_) {
            if (mounted) setState(() => _dinliyor = false);
          },
        );
      }

      if (_isSpeechInitialized && !_sessizMod && !_konusuyor && !_isProcessing && !_speech.isListening) {
        if (mounted) setState(() => _dinliyor = true);
        await _speech.listen(
          localeId: "tr_TR",
          listenMode: stt.ListenMode.confirmation,
          pauseFor: const Duration(seconds: 3),
          onSoundLevelChange: (level) {
            if (mounted) {
              setState(() {
                _sesSeviyesi = (level / 8.0).clamp(0.1, 1.0);
              });
            }
          },
          onResult: (result) {
            if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
              String recognized = result.recognizedWords.trim();
              if (recognized.length >= 2) {
                _cevapVer(recognized);
              }
            }
          },
        );
      }
    } catch (_) {
      if (mounted) setState(() => _dinliyor = false);
    }
  }

  void _sesliModaAl() async {
    setState(() {
      _sessizMod = false;
      _isProcessing = false;
      _metin = "Seni dinliyorum $_hitapSekli...";
    });
    await _dinlemeBaslat();
  }

  void _sessizModaAl() async {
    await _speech.stop();
    await _tts.stop();
    setState(() {
      _sessizMod = true;
      _dinliyor = false;
      _konusuyor = false;
      _isProcessing = false;
      _metin = "Sessiz Mod Aktif (Sadece Yazı İle İletişim)";
    });
  }

  void _mikrofonaDokunuldu() async {
    if (_sessizMod) {
      _sesliModaAl();
    } else {
      if (_dinliyor) {
        await _speech.stop();
        setState(() => _dinliyor = false);
      } else {
        await _dinlemeBaslat();
      }
    }
  }

  void _cevapVer(String girdi) async {
    final temizGirdi = girdi.trim();
    if (temizGirdi.isEmpty || _isProcessing) return;

    if (_sesliSistemKomutuMu(temizGirdi)) return;

    await _speech.stop();

    // 1. Önce Selamlaşma mı kontrol et
    String? selamCevabi = _yerelSelamlasmaMi(temizGirdi);
    if (selamCevabi != null) {
      setState(() {
        _metin = selamCevabi;
        _isProcessing = false;
        _dinliyor = false;
      });
      if (!_sessizMod) {
        await _tts.speak(selamCevabi);
      }
      return;
    }

    // 2. Selamlaşma değilse API kontrolü
    if (_kayitliApiler.isEmpty) {
      setState(() {
        _metin = "Efendim, henüz sisteme bir API anahtarı tanımlanmadı. Lütfen sol üstteki Ayarlar menüsünden Yapay Zeka Havuzu'na girip Google veya Groq anahtarınızı ekleyin.";
        _isProcessing = false;
      });
      if (!_sessizMod) {
        await _tts.speak("Efendim, henüz sisteme bir API anahtarı tanımlanmadı. Lütfen Ayarlar menüsünden anahtarınızı ekleyin.");
      }
      return;
    }

    // 3. API varsa soruyu gönder
    setState(() {
      _isProcessing = true;
      _dinliyor = false;
      _metin = "Konsey değerlendiriyor $_hitapSekli...";
    });

    String cevap = await _soruyuYapayZekayaSor(temizGirdi);

    if (mounted) {
      setState(() {
        _metin = cevap;
        _isProcessing = false;
      });
    }

    if (!_sessizMod) {
      await _tts.speak(cevap);
    }
  }

  void _gonderilecekMesaj(String text) {
    if (text.trim().isEmpty || _isProcessing) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    _cevapVer(text);
  }

  // ============================================================
  // 🛡️ POP-UP PENCERELERİ (API HAVUZU & SİSTEM AYARLARI)
  // ============================================================

  void _apiHavuzuPopUpAc() {
    final TextEditingController firmaCtrl = TextEditingController();
    final TextEditingController adresCtrl = TextEditingController();
    final TextEditingController anahtarCtrl = TextEditingController();
    final TextEditingController uzmanlikCtrl = TextEditingController();

    String seciliWebLink = "https://aistudio.google.com/app/apikey";

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  height: MediaQuery.of(context).size.height * 0.88,
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.cyanAccent, width: 2.0),
                    boxShadow: [
                      BoxShadow(color: Colors.cyanAccent.withOpacity(0.35), blurRadius: 30, spreadRadius: 3),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.hub_rounded, color: Colors.cyanAccent, size: 22),
                              SizedBox(width: 10),
                              Text(
                                "YAPAY ZEKÂ HAVUZU // API KATALOĞU",
                                style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),

                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SOL: HAZIR KATALOG
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "📚 HAZIR YAPAY ZEKA LİSTESİ:",
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _hazirKatalog.length,
                                      itemBuilder: (context, index) {
                                        final item = _hazirKatalog[index];
                                        final bool kayitli = _apiKayitliMi(item["firma"]!);

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: kayitli ? const Color(0xFF07241E) : const Color(0xFF0C1424),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: kayitli ? Colors.greenAccent : const Color(0xFF1B3B5F),
                                              width: kayitli ? 1.6 : 1.0,
                                            ),
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item["firma"]!,
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                ),
                                                if (kayitli)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.greenAccent.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: Colors.greenAccent, width: 0.8),
                                                    ),
                                                    child: const Text("🟢 AKTİF", style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                                  ),
                                              ],
                                            ),
                                            subtitle: Text("${item["kategori"]!} • ${item["uzmanlik"]!}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                                            trailing: const Icon(Icons.touch_app_rounded, color: Colors.cyanAccent, size: 18),
                                            onTap: () {
                                              firmaCtrl.text = item["firma"]!;
                                              adresCtrl.text = item["adres"]!;
                                              uzmanlikCtrl.text = item["uzmanlik"]!;
                                              seciliWebLink = item["link"]!;
                                              setModalState(() {});
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(color: Colors.white12, width: 24),

                            // SAĞ: FORM VE WEB BUTONU
                            Expanded(
                              flex: 5,
                              child: ListView(
                                children: [
                                  _siberpunkGirisKutusu(
                                    baslik: "1. FİRMA / MODEL ADI",
                                    hint: "Listeden seçin veya yazın",
                                    controller: firmaCtrl,
                                    icon: Icons.business_rounded,
                                  ),
                                  const SizedBox(height: 8),
                                  _siberpunkGirisKutusu(
                                    baslik: "2. API ADRESİ (ENDPOINT)",
                                    hint: "https://...",
                                    controller: adresCtrl,
                                    icon: Icons.link_rounded,
                                  ),
                                  const SizedBox(height: 8),
                                  _siberpunkGirisKutusu(
                                    baslik: "3. API ANAHTARI (SECRET KEY)",
                                    hint: "Anahtarınızı buraya yapıştırın",
                                    controller: anahtarCtrl,
                                    icon: Icons.vpn_key_rounded,
                                    sifreli: true,
                                  ),
                                  const SizedBox(height: 8),
                                  _siberpunkGirisKutusu(
                                    baslik: "4. UZMANLIK ALANI",
                                    hint: "Metin, Kod, Görsel...",
                                    controller: uzmanlikCtrl,
                                    icon: Icons.psychology_rounded,
                                  ),
                                  const SizedBox(height: 12),

                                  // WEB KÖPRÜSÜ
                                  GestureDetector(
                                    onTap: () async {
                                      try {
                                        final uri = Uri.parse(seciliWebLink);
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } catch (_) {}
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF082032),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.8), width: 1.2),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.open_in_browser_rounded, color: Colors.cyanAccent, size: 20),
                                          SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              "🔑 SEÇİLİ MODELİN API ANAHTARI ALMA SAYFASINI AÇ",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // SİSTEME KAYDET BUTONU
                                  GestureDetector(
                                    onTap: () async {
                                      if (anahtarCtrl.text.trim().isEmpty) return;

                                      final yeniApi = {
                                        "firma": firmaCtrl.text.trim().isEmpty ? "Google Gemini" : firmaCtrl.text.trim(),
                                        "adres": adresCtrl.text.trim(),
                                        "anahtar": anahtarCtrl.text.trim(),
                                        "uzmanlik": uzmanlikCtrl.text.trim(),
                                        "tarih": DateTime.now().toIso8601String(),
                                      };

                                      _kayitliApiler.removeWhere((a) => a["firma"] == yeniApi["firma"]);
                                      _kayitliApiler.add(yeniApi);

                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('kayitli_api_havuzu', json.encode(_kayitliApiler));

                                      setState(() {});
                                      if (!mounted) return;
                                      Navigator.pop(dialogContext);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF042940),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.cyanAccent, width: 1.8),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save_rounded, color: Colors.cyanAccent, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            "SİSTEME KAYDET VE AKTİF ET",
                                            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _sistemAyarlariPopUpAc() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.70,
                  height: MediaQuery.of(context).size.height * 0.84,
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.cyanAccent, width: 2.0),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 22),
                              SizedBox(width: 10),
                              Text("SİSTEM & KİŞİSELLEŞTİRME MERKEZİ", style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 26),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),

                      Expanded(
                        child: ListView(
                          children: [
                            const Text("1. ARES KARAKTER & ARAYÜZ MODELİ:", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _karakterSecim3dButon(
                                    baslik: "ERKEK ARES 👦",
                                    aktif: _karakter == 'ERKEK',
                                    onTap: () {
                                      _karakterDegistir('ERKEK');
                                      setModalState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _karakterSecim3dButon(
                                    baslik: "KADIN ARES 👩",
                                    aktif: _karakter == 'KADIN',
                                    onTap: () {
                                      _karakterDegistir('KADIN');
                                      setModalState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Text("2. YAZI BOYUTU: ${_yaziBoyutu.toInt()} px", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            Slider(
                              value: _yaziBoyutu,
                              min: 14.0,
                              max: 26.0,
                              divisions: 6,
                              activeColor: Colors.cyanAccent,
                              inactiveColor: Colors.white12,
                              onChanged: (val) {
                                setModalState(() => _yaziBoyutu = val);
                                setState(() => _yaziBoyutu = val);
                              },
                            ),
                            const SizedBox(height: 10),

                            Text("3. ARES KONUŞMA HIZI: ${(_konusmaHizi * 2).toStringAsFixed(1)}x", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            Slider(
                              value: _konusmaHizi,
                              min: 0.30,
                              max: 0.80,
                              divisions: 10,
                              activeColor: Colors.cyanAccent,
                              inactiveColor: Colors.white12,
                              onChanged: (val) {
                                setModalState(() => _konusmaHizi = val);
                                setState(() => _konusmaHizi = val);
                              },
                            ),
                            const SizedBox(height: 10),

                            Text("4. SES TONU DERİNLİĞİ: ${_sesTonu.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            Slider(
                              value: _sesTonu,
                              min: 0.40,
                              max: 1.20,
                              divisions: 8,
                              activeColor: Colors.cyanAccent,
                              inactiveColor: Colors.white12,
                              onChanged: (val) {
                                setModalState(() => _sesTonu = val);
                                setState(() => _sesTonu = val);
                              },
                            ),
                            const SizedBox(height: 18),

                            GestureDetector(
                              onTap: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setDouble('yazi_boyutu', _yaziBoyutu);
                                await prefs.setDouble('konusma_hizi', _konusmaHizi);
                                await prefs.setDouble('ses_tonu', _sesTonu);
                                await _sesMotorunuAyarla(_karakter);

                                setState(() {});
                                if (!mounted) return;
                                Navigator.pop(dialogContext);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF042940),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.cyanAccent, width: 1.8),
                                ),
                                alignment: Alignment.center,
                                child: const Text("TÜM AYARLARI KAYDET VE SİSTEME İŞLE", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ⚙️ 3D SİBERPUNK AYARLAR ÇEKMECESİ
  // ============================================================
  void _ayarlarPaneliniAc() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Ayarlar",
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (panelContext, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setPanelState) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.44,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF060911).withOpacity(0.97),
                    border: const Border(right: BorderSide(color: Colors.cyanAccent, width: 2.0)),
                    boxShadow: [
                      BoxShadow(color: Colors.cyanAccent.withOpacity(0.25), blurRadius: 25, spreadRadius: 2)
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.settings_suggest_rounded, color: Colors.cyanAccent, size: 20),
                              SizedBox(width: 8),
                              Text("ARES // SİSTEM", style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                            onPressed: () => Navigator.pop(panelContext),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, thickness: 1),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // 1. KULLANICI KİMLİĞİ
                            _siberpunk3dKart(
                              baslik: "KULLANICI KİMLİĞİ & HİTAP",
                              altBaslik: "Ares'in seslenme bilgisi",
                              icon: Icons.person_pin_rounded,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "$_kullaniciAdi ($_hitapSekli)",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _mini3dButon(
                                    metin: "DÜZENLE",
                                    onTap: () => _profilDuzenleModal(setPanelState),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 2. SİSTEM VE KİŞİSELLEŞTİRME
                            _siberpunk3dButon(
                              baslik: "⚙️ SİSTEM & KİŞİSELLEŞTİRME",
                              altBaslik: "Karakter, Ses Tonu, Yazı Boyutu",
                              icon: Icons.tune_rounded,
                              vurgulu: true,
                              onTap: () {
                                Navigator.pop(panelContext);
                                _sistemAyarlariPopUpAc();
                              },
                            ),
                            const SizedBox(height: 10),

                            // 3. YAPAY ZEKA HAVUZU
                            _siberpunk3dButon(
                              baslik: "🌐 YAPAY ZEKÂ HAVUZU // API",
                              altBaslik: "${_kayitliApiler.length} Yapay Zeka Tanımlı",
                              icon: Icons.hub_rounded,
                              vurgulu: true,
                              onTap: () {
                                Navigator.pop(panelContext);
                                _apiHavuzuPopUpAc();
                              },
                            ),
                            const SizedBox(height: 10),

                            // 4. ARŞİV DOSYASI
                            _siberpunkDepolamaKart(
                              baslik: "📁 ARŞİV MERKEZİ",
                              altBaslik: "Sohbet ve çıktıların otomatik kasası",
                              icon: Icons.archive_rounded,
                              mevcutYol: _arsivYolu,
                              onGozat: () async {
                                String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                                if (selectedDirectory != null) {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('arsiv_kayit_yolu', selectedDirectory);
                                  setPanelState(() => _arsivYolu = selectedDirectory);
                                  setState(() => _arsivYolu = selectedDirectory);
                                }
                              },
                            ),
                            const SizedBox(height: 10),

                            // 5. NOTLAR BÖLÜMÜ
                            _siberpunkDepolamaKart(
                              baslik: "📝 NOTLAR MERKEZİ",
                              altBaslik: "Fikir ve not havuzu",
                              icon: Icons.edit_note_rounded,
                              mevcutYol: _notlarYolu,
                              onGozat: () async {
                                String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                                if (selectedDirectory != null) {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('notlar_kayit_yolu', selectedDirectory);
                                  setPanelState(() => _notlarYolu = selectedDirectory);
                                  setState(() => _notlarYolu = selectedDirectory);
                                }
                              },
                            ),
                            const SizedBox(height: 10),

                            // 6. EĞİTİM MERKEZİ
                            _siberpunkDepolamaKart(
                              baslik: "🎓 EĞİTİM MERKEZİ",
                              altBaslik: "Yabancı dil ve hoca havuzu",
                              icon: Icons.school_rounded,
                              mevcutYol: _egitimYolu,
                              onGozat: () async {
                                String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                                if (selectedDirectory != null) {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('egitim_kayit_yolu', selectedDirectory);
                                  setPanelState(() => _egitimYolu = selectedDirectory);
                                  setState(() => _egitimYolu = selectedDirectory);
                                }
                              },
                            ),
                            const SizedBox(height: 10),

                            // 7. DİNAMİK MODÜLLER
                            if (_dinamikOzelModuller.isNotEmpty) ...[
                              ..._dinamikOzelModuller.asMap().entries.map((entry) {
                                int idx = entry.key;
                                var mod = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A101D),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.cyanAccent.withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.extension_rounded, color: Colors.cyanAccent, size: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(mod["baslik"] ?? "Özel Modül", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                              const SizedBox(height: 2),
                                              Text(mod["aciklama"] ?? "", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                          onPressed: () async {
                                            _dinamikOzelModuller.removeAt(idx);
                                            final prefs = await SharedPreferences.getInstance();
                                            await prefs.setString('dinamik_ozel_moduller', json.encode(_dinamikOzelModuller));
                                            setPanelState(() {});
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],

                            // ➕ 8. YENİ BUTON VE KUTU EKLE
                            GestureDetector(
                              onTap: () => _yeniDinamikModulEkleModal(setPanelState),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.cyanAccent, width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline_rounded, color: Colors.cyanAccent, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      "YENİ BUTON & KUTU EKLE",
                                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _profilDuzenleModal(StateSetter setPanelState) {
    final nameCtrl = TextEditingController(text: _kullaniciAdi);
    final hitapCtrl = TextEditingController(text: _hitapSekli);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF080D18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
          ),
          title: const Text("PROFİL BİLGİLERİNİ GÜNCELLE", style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _siberpunkGirisKutusu(baslik: "KULLANICI ADI", hint: "Adınız", controller: nameCtrl, icon: Icons.person),
              const SizedBox(height: 10),
              _siberpunkGirisKutusu(baslik: "HİTAP ŞEKLİ", hint: "Örn: Efendim, Komutan", controller: hitapCtrl, icon: Icons.record_voice_over),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(modalContext),
              child: const Text("İPTAL", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF042940)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('kullanici_adi', nameCtrl.text.trim());
                await prefs.setString('hitap_sekli', hitapCtrl.text.trim());
                setPanelState(() {
                  _kullaniciAdi = nameCtrl.text.trim();
                  _hitapSekli = hitapCtrl.text.trim();
                });
                setState(() {
                  _kullaniciAdi = nameCtrl.text.trim();
                  _hitapSekli = hitapCtrl.text.trim();
                });
                if (!mounted) return;
                Navigator.pop(modalContext);
              },
              child: const Text("KAYDET", style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  void _yeniDinamikModulEkleModal(StateSetter setPanelState) {
    final baslikCtrl = TextEditingController();
    final aciklamaCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF080D18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
          ),
          title: const Text("YENİ ÖZEL BUTON & KUTU EKLE", style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _siberpunkGirisKutusu(baslik: "BUTON / MODÜL BAŞLIĞI", hint: "Örn: Proje Yönetimi, Finans...", controller: baslikCtrl, icon: Icons.label_important),
              const SizedBox(height: 12),
              _siberpunkGirisKutusu(baslik: "GÖREV & AÇIKLAMA", hint: "Ares'in yapacağı görevi tanımlayın", controller: aciklamaCtrl, icon: Icons.description),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(modalContext),
              child: const Text("İPTAL", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF042940)),
              onPressed: () async {
                if (baslikCtrl.text.trim().isEmpty) return;

                final yeniModul = {
                  "baslik": baslikCtrl.text.trim(),
                  "aciklama": aciklamaCtrl.text.trim(),
                  "tarih": DateTime.now().toIso8601String(),
                };

                _dinamikOzelModuller.add(yeniModul);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('dinamik_ozel_moduller', json.encode(_dinamikOzelModuller));

                setPanelState(() {});
                setState(() {});
                if (!mounted) return;
                Navigator.pop(modalContext);
              },
              child: const Text("SİSTEME EKLE", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // YARDIMCI WIDGET'LAR
  // ============================================================
  Widget _siberpunkDepolamaKart({
    required String baslik,
    required String altBaslik,
    required IconData icon,
    required String mevcutYol,
    required VoidCallback onGozat,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A101D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B3B5F), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 6),
              Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Text(altBaslik, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    mevcutYol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _mini3dButon(metin: "SEÇ", onTap: onGozat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _siberpunk3dKart({required String baslik, required String altBaslik, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A101D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B3B5F), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 6),
              Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Text(altBaslik, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _siberpunk3dButon({
    required String baslik,
    required String altBaslik,
    required IconData icon,
    required VoidCallback onTap,
    bool vurgulu = false,
  }) {
    Color anaRenk = vurgulu ? Colors.cyanAccent : const Color(0xFF2684FF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A101D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: anaRenk.withOpacity(0.6), width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: anaRenk.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: anaRenk, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 1),
                  Text(altBaslik, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: anaRenk.withOpacity(0.7), size: 12),
          ],
        ),
      ),
    );
  }

  Widget _karakterSecim3dButon({required String baslik, required bool aktif, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: aktif ? const Color(0xFF042940) : const Color(0xFF080D1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: aktif ? Colors.cyanAccent : Colors.white12, width: aktif ? 2.0 : 1.0),
        ),
        alignment: Alignment.center,
        child: Text(
          baslik,
          style: TextStyle(color: aktif ? Colors.cyanAccent : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _mini3dButon({required String metin, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF052136),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.cyanAccent, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          metin,
          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10),
        ),
      ),
    );
  }

  Widget _siberpunkGirisKutusu({
    required String baslik,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool sifreli = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF050811),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF183B5E), width: 1.4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            obscureText: sifreli,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            cursorColor: Colors.cyanAccent,
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.cyan.withOpacity(0.7), size: 16),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  void _artiMenusuAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.40,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0B10).withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.cyan.withOpacity(0.6), width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: 45,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _kategoriBasligi("GÖRSEL & KAMERA ALGILAMA"),
                        _listeOgesi(icon: Icons.remove_red_eye, baslik: 'Canlı Algıla (Kamera Modu)', altBaslik: 'Ortamı anlık incelet', onTap: _fotografCek, context: sheetContext),
                        _listeOgesi(icon: Icons.photo_library, baslik: 'Fotoğraf & Galeri', altBaslik: 'Görsel yükle', onTap: _galeridenSec, context: sheetContext),

                        _kategoriBasligi("MESAJLAŞMA & SOSYAL MEDYA"),
                        _listeOgesi(icon: Icons.chat, baslik: 'WhatsApp & Mesajlaşma', altBaslik: 'Sohbet geçmişi analizi', onTap: () => _gonderilecekMesaj("WhatsApp sohbet analizi başlatıldı."), context: sheetContext),
                        _listeOgesi(icon: Icons.push_pin, baslik: 'Pinterest Panoları', altBaslik: 'Pano linki incelet', onTap: () => _gonderilecekMesaj("Pinterest analizi başlatıldı."), context: sheetContext),

                        _kategoriBasligi("BULUT & DOSYA DEPOLAMA"),
                        _listeOgesi(icon: Icons.insert_drive_file, baslik: 'Belge & Doküman', altBaslik: 'PDF, Word, TXT', onTap: _dosyaSec, context: sheetContext),
                        _listeOgesi(icon: Icons.code, baslik: 'Kod & Proje Deposu', altBaslik: 'Dart, Python, ZIP', onTap: _dosyaSec, context: sheetContext),

                        if (_ozelAraclar.isNotEmpty) ...[
                          _kategoriBasligi("ÖZEL EKLENEN ARAÇLAR"),
                          ..._ozelAraclar.map((arac) => _listeOgesi(
                                icon: Icons.extension,
                                baslik: arac,
                                altBaslik: 'Özel araç',
                                onTap: () => _gonderilecekMesaj("$arac çalıştırıldı."),
                                context: sheetContext,
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _kategoriBasligi(String baslik) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4, left: 6),
      child: Text(baslik, style: const TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _listeOgesi({required IconData icon, required String baslik, required String altBaslik, required VoidCallback onTap, required BuildContext context}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.cyan, size: 20),
      title: Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(altBaslik, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _fotografCek() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) _cevapVer("Çekilen fotoğraf Ares'e iletildi. Görsel inceleniyor...");
  }

  Future<void> _galeridenSec() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) _cevapVer("Galeriden seçilen '${image.name}' görseli Ares'e iletildi.");
  }

  Future<void> _dosyaSec() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) _cevapVer("Yüklenen '${result.files.first.name}' belgesi Ares'e gönderildi.");
  }

  // ============================================================
  // EKRAN YERLEŞİMİ
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. ARKA PLAN GÖRSELİ
          Positioned.fill(
            child: Image.asset(
              _bgImage,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),

          // 2. ORTA ANA SOHBET ALANI
          Positioned(
            left: screenWidth * 0.28,
            right: screenWidth * 0.29,
            top: screenHeight * 0.23,
            bottom: screenHeight * 0.21,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF030508),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  _metin,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _yaziBoyutu,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),

          // 3. SOL PANEL ARAMA KUTUSU
          Positioned(
            left: screenWidth * 0.028,
            bottom: screenHeight * 0.080,
            width: screenWidth * 0.178,
            height: screenHeight * 0.075,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _metin = "Arama paneli açıldı $_hitapSekli..."),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 4. ORTA PANEL: "+" BUTONU ALANI
          Positioned(
            left: screenWidth * 0.260,
            bottom: screenHeight * 0.080,
            width: screenWidth * 0.048,
            height: screenHeight * 0.075,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _artiMenusuAc,
              child: Container(color: Colors.transparent),
            ),
          ),

          // 5. ORTA PANEL: YAZI GİRİŞ ALANI
          Positioned(
            left: screenWidth * 0.315,
            bottom: screenHeight * 0.080,
            width: screenWidth * 0.280,
            height: screenHeight * 0.075,
            child: Center(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '',
                ),
                onSubmitted: _gonderilecekMesaj,
              ),
            ),
          ),

          // 6. ORTA PANEL: MİKROFON BUTONU
          Positioned(
            left: screenWidth * 0.608,
            bottom: screenHeight * 0.082,
            width: 44,
            height: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _mikrofonaDokunuldu,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: Colors.transparent),
                  if (_dinliyor && !_sessizMod)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 36 + (_pulseController.value * 12),
                          height: 36 + (_pulseController.value * 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity((1 - _pulseController.value).clamp(0.0, 1.0)),
                              width: 2.0,
                            ),
                          ),
                        );
                      },
                    ),
                  if (_sessizMod)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), shape: BoxShape.circle),
                      child: const Icon(Icons.mic_off, color: Colors.redAccent, size: 20),
                    ),
                ],
              ),
            ),
          ),

          // 7. ORTA PANEL: CANLI SPEKTRUM / GÖNDER BUTONU
          Positioned(
            left: screenWidth * 0.665,
            bottom: screenHeight * 0.082,
            width: 44,
            height: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_yaziVar) {
                  _gonderilecekMesaj(_textController.text);
                } else {
                  _mikrofonaDokunuldu();
                }
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0747A6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x660052CC), blurRadius: 10, spreadRadius: 1)
                  ],
                ),
                alignment: Alignment.center,
                child: _yaziVar
                    ? const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24)
                    : AnimatedBuilder(
                        animation: _spectrumController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              double barHeight;
                              if (_sessizMod) {
                                barHeight = 4.0;
                              } else if (_konusuyor) {
                                barHeight = 10.0 + (sin((_spectrumController.value * 2 * pi) + (index * 1.0)).abs() * 16.0);
                              } else if (_dinliyor) {
                                barHeight = 8.0 + (sin((_spectrumController.value * 2 * pi) + (index * 1.2)).abs() * 16.0 * _sesSeviyesi);
                              } else {
                                barHeight = 8.0;
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                width: 3.2,
                                height: barHeight.clamp(4.0, 26.0),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                              );
                            }),
                          );
                        },
                      ),
              ),
            ),
          ),

          // 8. SAĞ PANEL: DİSKET / KAYDET BUTONU
          Positioned(
            left: screenWidth * 0.772,
            bottom: screenHeight * 0.080,
            width: screenWidth * 0.190,
            height: screenHeight * 0.075,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _metin = "Sohbet ve veriler başarıyla kaydedildi $_hitapSekli."),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 9. ÜST PANEL: SOL AYARLAR BUTONU
          Positioned(
            left: screenWidth * 0.245,
            top: screenHeight * 0.050,
            width: screenWidth * 0.040,
            height: screenHeight * 0.055,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _ayarlarPaneliniAc,
              child: Container(color: Colors.transparent),
            ),
          ),

          // 10. ÜST PANEL: SAĞ YENİ SOHBET BUTONU
          Positioned(
            left: screenWidth * 0.690,
            top: screenHeight * 0.050,
            width: screenWidth * 0.040,
            height: screenHeight * 0.055,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _textController.clear();
                setState(() => _metin = "Seni dinliyorum $_hitapSekli...");
                _dinlemeBaslat();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
