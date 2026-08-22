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
  double _yaziBoyutu = 22.0;
  double _konusmaHizi = 0.46;
  double _sesTonu = 0.58;

  // Depolama Dizinleri
  String _arsivYolu = "Dahili Hafıza / ARES / Arsiv";
  String _notlarYolu = "Dahili Hafıza / ARES / Notlar";
  String _egitimYolu = "Dahili Hafıza / ARES / Egitim";

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  String _metin = "Seni dinliyorum...";
  bool _sessizMod = false;
  bool _dinliyor = false;
  bool _konusuyor = false;
  bool _isProcessing = false;
  bool _yaziVar = false;
  double _sesSeviyesi = 0.0;
  bool _isSpeechInitialized = false;

  DateTime? _sonCevapZamani;
  List<String> _ozelAraclar = [];
  List<Map<String, dynamic>> _kayitliApiler = [];
  List<Map<String, dynamic>> _dinamikOzelModuller = [];

  late AnimationController _spectrumController;
  late AnimationController _pulseController;

  // ============================================================
  // 📚 DÜNYADAKİ YAPAY ZEKALAR KATALOĞU
  // ============================================================
  final List<Map<String, String>> _hazirKatalog = [
    {
      "id": "google",
      "firma": "Google Gemini (1.5 Flash / Pro)",
      "kategori": "ÜCRETSİZ / GENİŞ KOTA",
      "adres": "https://generativelanguage.googleapis.com",
      "uzmanlik": "Metin, Görsel Analiz, Kodlama, Çeviri, Mantık",
      "link": "https://aistudio.google.com/app/apikey"
    },
    {
      "id": "groq",
      "firma": "Groq (Llama 3.3 70B & Mixtral)",
      "kategori": "ÜCRETSİZ / ULTRA HIZLI",
      "adres": "https://api.groq.com/openai/v1",
      "uzmanlik": "Işık Hızında Çıkarım, Kodlama, Sohbet",
      "link": "https://console.groq.com/keys"
    },
    {
      "id": "huggingface",
      "firma": "Hugging Face (Inference API)",
      "kategori": "ÜCRETSİZ / AÇIK KAYNAK",
      "adres": "https://api-inference.huggingface.co",
      "uzmanlik": "Açık Kaynak Modeller, NLP, Çeviri",
      "link": "https://huggingface.co/settings/tokens"
    },
    {
      "id": "nvidia",
      "firma": "NVIDIA NIM (Llama 3.1 & Nemotron)",
      "kategori": "SÜRE SINIRLI / ÜCRETSİZ KREDİ",
      "adres": "https://integrate.api.nvidia.com",
      "uzmanlik": "Kodlama, Taktiksel Analiz, Yazılım, Matematik",
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
      "id": "mistral",
      "firma": "Mistral AI (Codestral & Mistral Large)",
      "kategori": "SÜRE SINIRLI / ÜCRETSİZ KOTA",
      "adres": "https://api.mistral.ai/v1",
      "uzmanlik": "Avrupa Zekası, Hızlı Kodlama, Çok Dilli",
      "link": "https://console.mistral.ai/api-keys"
    },
    {
      "id": "elevenlabs",
      "firma": "ElevenLabs (Doğal Ses Klonlama)",
      "kategori": "SÜRE SINIRLI / ÜCRETSİZ KOTA",
      "adres": "https://api.elevenlabs.io/v1",
      "uzmanlik": "Gerçekçi İnsan Sesi, Ses Klonlama",
      "link": "https://elevenlabs.io"
    },
    {
      "id": "deepseek",
      "firma": "DeepSeek (V3 & R1 Reasoner)",
      "kategori": "ÜCRETLİ / DÜŞÜK MALİYET",
      "adres": "https://api.deepseek.com/v1",
      "uzmanlik": "Derin Matematik, Yazılım Mimarisi, Mantık",
      "link": "https://platform.deepseek.com"
    },
    {
      "id": "midjourney",
      "firma": "Midjourney / Flux Pro (Görsel)",
      "kategori": "ÜCRETLİ / ÖZEL ÜRETİM",
      "adres": "https://api.midjourney.com",
      "uzmanlik": "Sinematik Görsel, Siberpunk Konsept Sanatı",
      "link": "https://www.midjourney.com"
    },
    {
      "id": "runway",
      "firma": "Runway Gen-3 (Sinematik Video)",
      "kategori": "ÜCRETLİ / VİDEO ÜRETİMİ",
      "adres": "https://api.runwayml.com/v1",
      "uzmanlik": "Yapay Zeka Video Üretimi ve Animasyon",
      "link": "https://runwayml.com"
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
        await _tts.setPitch(_sesTonu);
        await _tts.setSpeechRate(_konusmaHizi);
      } else {
        await _tts.setPitch(1.05);
        await _tts.setSpeechRate(_konusmaHizi);
      }

      List<dynamic>? voices = await _tts.getVoices;
      if (voices != null) {
        for (var v in voices) {
          if (v is Map) {
            String name = (v["name"] ?? "").toString().toLowerCase();
            String locale = (v["locale"] ?? "").toString().toLowerCase();

            if (locale.contains("tr")) {
              if (karakter == 'ERKEK' && (name.contains("male") || name.contains("efz") || name.contains("cfz") || name.contains("c"))) {
                await _tts.setVoice({"name": v["name"].toString(), "locale": v["locale"].toString()});
                break;
              } else if (karakter == 'KADIN' && (name.contains("female") || name.contains("dfz") || name.contains("d"))) {
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
          Future.delayed(const Duration(milliseconds: 600), () {
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
    _hitapSekli = prefs.getString('hitap_sekli') ?? 'Efendim';
    _yaziBoyutu = prefs.getDouble('yazi_boyutu') ?? 22.0;
    _konusmaHizi = prefs.getDouble('konusma_hizi') ?? 0.46;
    _sesTonu = prefs.getDouble('ses_tonu') ?? 0.58;

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
        if (mounted && !_sessizMod) {
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
      if (f.contains("nvidia") && (kayitli.contains("nvidia") || kayitli.contains("llama"))) return true;
      if (f.contains("openai") && kayitli.contains("openai")) return true;
      if (f.contains("groq") && kayitli.contains("groq")) return true;
      if (f.contains("anthropic") && (kayitli.contains("anthropic") || kayitli.contains("claude"))) return true;
      if (f.contains("mistral") && kayitli.contains("mistral")) return true;
      if (f.contains("elevenlabs") && kayitli.contains("elevenlabs")) return true;
      if (f.contains("deepseek") && kayitli.contains("deepseek")) return true;
      if (f.contains("midjourney") && kayitli.contains("midjourney")) return true;
      if (f.contains("runway") && kayitli.contains("runway")) return true;
      if (f.contains("hugging") && kayitli.contains("hugging")) return true;
    }
    return false;
  }

  // ============================================================
  // 🏛️ YAPAY ZEKA KONSEYİ & HAKEM SİSTEMİ (GÜÇLENDİRİLMİŞ)
  // ============================================================
  Future<String> _googleGeminiCagrisi(String apiKey, String soru) async {
    final cleanKey = apiKey.trim();
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$cleanKey");

    String sistemPrompt = "Sen ARES adlı üst düzey yapay zeka asistanısın. "
        "Kullanıcı adı: '$_kullaniciAdi', Hitap: '$_hitapSekli'. "
        "Kullanıcının Türkçe sorularına zeki, doğrudan, profesyonel ve saygılı cevap ver.";

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": "$sistemPrompt\n\nKullanıcı Sorusı: $soru"}
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
      return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";
    } else {
      throw Exception("Google HTTP ${response.statusCode}");
    }
  }

  Future<String> _nvidiaLlamaCagrisi(String apiKey, String soru) async {
    final cleanKey = apiKey.trim();
    final url = Uri.parse("https://integrate.api.nvidia.com/v1/chat/completions");

    String sistemPrompt = "Sen ARES sisteminin stratejik yapay zekasısın. "
        "Kullanıcı: '$_kullaniciAdi', Hitap: '$_hitapSekli'. "
        "Kullanıcının sorusunu teknik ve mantıksal açıdan analiz edip doğrudan Türkçe yanıt üret.";

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $cleanKey",
      },
      body: json.encode({
        "model": "meta/llama-3.1-70b-instruct",
        "messages": [
          {"role": "system", "content": sistemPrompt},
          {"role": "user", "content": soru}
        ],
        "temperature": 0.5,
        "max_tokens": 800,
      }),
    ).timeout(const Duration(seconds: 14));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data["choices"]?[0]?["message"]?["content"] ?? "";
    } else {
      throw Exception("Nvidia HTTP ${response.statusCode}");
    }
  }

  // Akıllı ve Genişletilmiş Selamlaşma / Hızlı Yanıtlayıcı
  String? _temelSelamlasmaMi(String soru) {
    String s = soru.toLowerCase().trim();

    if (s.contains("merhaba") || s.contains("selam") || s.contains("hey ares") || s.contains("günaydın") || s.contains("iyi günler") || s.contains("iyi akşamlar")) {
      return "Merhaba $_kullaniciAdi $_hitapSekli. Tüm sistemlerim aktif ve sizi dinliyorum. Nasıl yardımcı olabilirim?";
    }
    if (s.contains("nasılsın") || s.contains("durumun nedir") || s.contains("sistem durumu") || s.contains("ne yapıyorsun")) {
      return "Teşekkür ederim $_hitapSekli, çekirdek modüllerim ve yapay zekâ konseyim tam kapasiteyle devrede. Emrinizdeyim.";
    }
    if (s == "ares" || s.contains("orada mısın") || s.contains("dinliyor musun") || s.contains("ares beni duyuyor musun")) {
      return "Buradayım ve sizi dinliyorum $_kullaniciAdi $_hitapSekli. Sizi dinliyorum.";
    }
    if (s.contains("saat kaç") || s.contains("zaman nedir")) {
      final now = DateTime.now();
      return "Şu an saat ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $_hitapSekli.";
    }
    if (s.contains("kimsin") || s.contains("sen kimsin") || s.contains("adın ne")) {
      return "Ben ARES, sizin için özelleştirilmiş siberpunk yapay zekâ asistanıyım $_hitapSekli.";
    }
    return null;
  }

  Future<String> _konseyVeHakemIleCevapla(String soru) async {
    // 1. Önce Hızlı Selamlaşma Kontrolü
    String? hizliCevap = _temelSelamlasmaMi(soru);
    if (hizliCevap != null) return hizliCevap;

    // 2. Havuz Kontrolü
    if (_kayitliApiler.isEmpty) {
      return "Efendim, henüz sisteme bir API anahtarı tanımlanmadı. Lütfen sol üstteki menüden Yapay Zeka Havuzu'na girip Google veya Nvidia anahtarınızı ekleyin.";
    }

    String? googleKey;
    String? nvidiaKey;

    for (var api in _kayitliApiler) {
      String firma = (api["firma"] ?? "").toString().toLowerCase();
      if (firma.contains("google") || firma.contains("gemini")) {
        googleKey = api["anahtar"];
      } else if (firma.contains("nvidia") || firma.contains("llama")) {
        nvidiaKey = api["anahtar"];
      }
    }

    if (googleKey == null && _kayitliApiler.isNotEmpty) {
      googleKey = _kayitliApiler.first["anahtar"];
    }

    String googleYaniti = "";
    String nvidiaYaniti = "";

    List<Future> cagrilari = [];
    if (googleKey != null && googleKey.isNotEmpty) {
      cagrilari.add(_googleGeminiCagrisi(googleKey, soru).then((res) => googleYaniti = res).catchError((_) => ""));
    }
    if (nvidiaKey != null && nvidiaKey.isNotEmpty) {
      cagrilari.add(_nvidiaLlamaCagrisi(nvidiaKey, soru).then((res) => nvidiaYaniti = res).catchError((_) => ""));
    }

    await Future.wait(cagrilari);

    if (googleYaniti.trim().isNotEmpty && nvidiaYaniti.trim().isNotEmpty) {
      return googleYaniti.length >= nvidiaYaniti.length ? googleYaniti.trim() : nvidiaYaniti.trim();
    } else if (googleYaniti.trim().isNotEmpty) {
      return googleYaniti.trim();
    } else if (nvidiaYaniti.trim().isNotEmpty) {
      return nvidiaYaniti.trim();
    }

    return "Efendim, yapay zeka sunucularına bağlanırken bir sorun oluştu. Lütfen API anahtarınızın geçerliliğini ve internet bağlantınızı kontrol edin.";
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
      if (!_sessizMod) _mikrofonaDokunuldu();
      return true;
    }
    if (k.contains("sesli moda geç") || k.contains("mikrofonu aç")) {
      if (_sessizMod) _mikrofonaDokunuldu();
      return true;
    }
    if (k.contains("yazıları büyüt") || k.contains("yazıyı büyüt")) {
      setState(() => _yaziBoyutu = 28.0);
      SharedPreferences.getInstance().then((p) => p.setDouble('yazi_boyutu', 28.0));
      _cevapVer("Yazı boyutu büyük moda alındı $_hitapSekli.");
      return true;
    }
    if (k.contains("yazıları küçült") || k.contains("yazıyı küçült")) {
      setState(() => _yaziBoyutu = 18.0);
      SharedPreferences.getInstance().then((p) => p.setDouble('yazi_boyutu', 18.0));
      _cevapVer("Yazı boyutu kompakt moda alındı $_hitapSekli.");
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
              // Anlamsız 1-2 harflik fısıltıları filtrele
              if (recognized.length >= 3) {
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

  void _mikrofonaDokunuldu() async {
    if (_sessizMod) {
      setState(() {
        _sessizMod = false;
        _isProcessing = false;
        _metin = "Seni dinliyorum $_hitapSekli...";
      });
      await _dinlemeBaslat();
    } else {
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
  }

  void _cevapVer(String girdi) async {
    final now = DateTime.now();
    if (_sonCevapZamani != null && now.difference(_sonCevapZamani!).inMilliseconds < 1200) {
      return;
    }
    if (girdi.trim().isEmpty || _isProcessing) return;

    if (_sesliSistemKomutuMu(girdi)) return;

    _sonCevapZamani = now;
    await _speech.stop();

    setState(() {
      _isProcessing = true;
      _dinliyor = false;
      _metin = "Konsey değerlendiriyor $_hitapSekli...";
    });

    String cevap = await _konseyVeHakemIleCevapla(girdi);

    if (mounted) {
      setState(() {
        _metin = cevap;
      });
    }

    if (!_sessizMod) {
      await _tts.speak(cevap);
    } else {
      if (mounted) {
        setState(() {
          _konusuyor = false;
          _isProcessing = false;
        });
      }
    }
  }

  void _gonderilecekMesaj(String text) {
    if (text.trim().isEmpty || _isProcessing) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    _cevapVer(text);
  }

  // ============================================================
  // 🛡️ GÜVENLİ MERKEZİ POP-UP HUD PENCERELERİ (KESİN KAPANIR)
  // ============================================================

  // 1. YAPAY ZEKA HAVUZU POP-UP'I
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
                                "YAPAY ZEKÂ HAVUZU // API KATALOĞU & YÖNETİMİ",
                                style: TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                          // [X] Kapatma Butonu - Doğrudan dialogContext ile Anında Kapatır
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
                            // SOL: HAZIR KATALOG (KAYITLI OLANLARDA YEŞİL ROZET ÇIKAR)
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "📚 HAZIR YAPAY ZEKA LİSTESİ (DOKUN VE OTOMATİK DOLDUR):",
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

                            // SAĞ: DOLDURULAN FORM VE WEB BUTONU
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

                                  // WEB KÖPRÜSÜ BUTONU
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
                                      if (firmaCtrl.text.trim().isEmpty || anahtarCtrl.text.trim().isEmpty) return;

                                      final yeniApi = {
                                        "firma": firmaCtrl.text.trim(),
                                        "adres": adresCtrl.text.trim(),
                                        "anahtar": anahtarCtrl.text.trim(),
                                        "uzmanlik": uzmanlikCtrl.text.trim(),
                                        "tarih": DateTime.now().toIso8601String(),
                                      };

                                      _kayitliApiler.add(yeniApi);
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('kayitli_api_havuzu', json.encode(_kayitliApiler));

                                      setState(() {});
                                      if (!mounted) return;
                                      Navigator.pop(dialogContext); // 💾 Kesin olarak kapatır!
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF042940),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.cyanAccent, width: 1.8),
                                        boxShadow: [
                                          BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 12),
                                        ],
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

  // 2. SİSTEM VE KİŞİSELLEŞTİRME POP-UP'I
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
                  height: MediaQuery.of(context).size.height * 0.82,
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
                              Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 22),
                              SizedBox(width: 10),
                              Text(
                                "SİSTEM & KİŞİSELLEŞTİRME MERKEZİ",
                                style: TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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

                            Text("2. YAZI BOYUTU: ${_yaziBoyutu.toInt()} px (${_yaziBoyutu > 24 ? "Büyük (Yaşlı/Göz Dostu)" : (_yaziBoyutu < 20 ? "Kompakt" : "Standart")})",
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            Slider(
                              value: _yaziBoyutu,
                              min: 16.0,
                              max: 32.0,
                              divisions: 8,
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
                            const SizedBox(height: 20),

                            GestureDetector(
                              onTap: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setDouble('yazi_boyutu', _yaziBoyutu);
                                await prefs.setDouble('konusma_hizi', _konusmaHizi);
                                await prefs.setDouble('ses_tonu', _sesTonu);
                                await _sesMotorunuAyarla(_karakter);

                                setState(() {});
                                if (!mounted) return;
                                Navigator.pop(dialogContext); // 💾 Kesin olarak kapatır!
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
  // ⚙️ 3D SİBERPUNK AYARLAR PANELİ
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
                    border: const Border(
                      right: BorderSide(color: Colors.cyanAccent, width: 2.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.25),
                        blurRadius: 25,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.settings_suggest_rounded, color: Colors.cyanAccent, size: 20),
                              SizedBox(width: 10),
                              Text(
                                "ARES // SİSTEM KONTROL",
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 26),
                            onPressed: () => Navigator.pop(panelContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12, thickness: 1),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // 1. KULLANICI PROFİLİ VE HİTAP
                            _siberpunk3dKart(
                              baslik: "KULLANICI KİMLİĞİ & HİTAP",
                              altBaslik: "Ares'in size nasıl sesleneceğini belirleyin",
                              icon: Icons.person_pin_rounded,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "$_kullaniciAdi ($_hitapSekli)",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _mini3dButon(
                                      metin: "DÜZENLE",
                                      onTap: () => _profilDuzenleModal(setPanelState),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2. SİSTEM VE KİŞİSELLEŞTİRME BUTONU
                            _siberpunk3dButon(
                              baslik: "⚙️ SİSTEM VE KİŞİSELLEŞTİRME",
                              altBaslik: "Karakter, Yüz, Ses Tonu, Yazı Boyutu & Erişilebilirlik",
                              icon: Icons.tune_rounded,
                              vurgulu: true,
                              onTap: () {
                                Navigator.pop(panelContext);
                                _sistemAyarlariPopUpAc();
                              },
                            ),
                            const SizedBox(height: 12),

                            // 3. YAPAY ZEKA HAVUZU BUTONU
                            _siberpunk3dButon(
                              baslik: "🌐 YAPAY ZEKÂ HAVUZU // API YÖNETİMİ",
                              altBaslik: "${_kayitliApiler.length} Yapay Zeka Tanımlı (Hazır Kataloglu)",
                              icon: Icons.hub_rounded,
                              vurgulu: true,
                              onTap: () {
                                Navigator.pop(panelContext);
                                _apiHavuzuPopUpAc();
                              },
                            ),
                            const SizedBox(height: 12),

                            // 4. ARŞİV DOSYASI
                            _siberpunkDepolamaKart(
                              baslik: "📁 ARŞİV MERKEZİ",
                              altBaslik: "Geçmiş sohbet ve çıktıların otomatik kasası",
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
                            const SizedBox(height: 12),

                            // 5. NOTLAR BÖLÜMÜ
                            _siberpunkDepolamaKart(
                              baslik: "📝 NOTLAR MERKEZİ",
                              altBaslik: "Kullanıcı fikirleri ve not kağıtları havuzu",
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
                            const SizedBox(height: 12),

                            // 6. EĞİTİM MERKEZİ
                            _siberpunkDepolamaKart(
                              baslik: "🎓 EĞİTİM MERKEZİ",
                              altBaslik: "Yabancı dil ve özel hoca eğitim havuzu",
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
                            const SizedBox(height: 12),

                            // 7. DİNAMİK EKLENEN ÖZEL MODÜLLER
                            if (_dinamikOzelModuller.isNotEmpty) ...[
                              ..._dinamikOzelModuller.asMap().entries.map((entry) {
                                int idx = entry.key;
                                var mod = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A101D),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.cyanAccent.withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.extension_rounded, color: Colors.cyanAccent, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(mod["baslik"] ?? "Özel Modül", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                              const SizedBox(height: 2),
                                              Text(mod["aciklama"] ?? "", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
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
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.cyanAccent, width: 1.6),
                                  boxShadow: [
                                    BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 10),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline_rounded, color: Colors.cyanAccent, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "YENİ BUTON & KUTU EKLE",
                                      style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 9. SİSTEM & BELLEK SIFIRLAMA
                            _siberpunk3dButon(
                              baslik: "SİSTEM VE BELLEĞİ SIFIRLA",
                              altBaslik: "Önbelleği temizle veya fabrika ayarlarına dön",
                              icon: Icons.delete_sweep_rounded,
                              tehlikeli: true,
                              onTap: () => Navigator.pop(panelContext),
                            ),
                            const SizedBox(height: 20),
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
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
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
              _siberpunkGirisKutusu(
                baslik: "BUTON / MODÜL BAŞLIĞI",
                hint: "Örn: Proje Yönetimi, Finans, Sağlık...",
                controller: baslikCtrl,
                icon: Icons.label_important_rounded,
              ),
              const SizedBox(height: 12),
              _siberpunkGirisKutusu(
                baslik: "GÖREV & AÇIKLAMA",
                hint: "Ares'in bu butonla yapacağı görevi tanımlayın",
                controller: aciklamaCtrl,
                icon: Icons.description_rounded,
              ),
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
  // YARDIMCI 3D WIDGET'LAR
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B3B5F), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0xFF02050A), offset: Offset(0, 4), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 3),
          Text(altBaslik, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    mevcutYol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _mini3dButon(metin: "KLASÖR SEÇ", onTap: onGozat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _siberpunk3dKart({required String baslik, required String altBaslik, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A101D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B3B5F), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0xFF02050A), offset: Offset(0, 4), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 4),
          Text(altBaslik, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 10),
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
    bool tehlikeli = false,
  }) {
    Color anaRenk = tehlikeli ? Colors.redAccent : (vurgulu ? Colors.cyanAccent : const Color(0xFF2684FF));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A101D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: anaRenk.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.6), offset: const Offset(0, 4), blurRadius: 6),
            if (vurgulu) BoxShadow(color: Colors.cyanAccent.withOpacity(0.15), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: anaRenk.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: anaRenk, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(altBaslik, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: anaRenk.withOpacity(0.7), size: 14),
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
          border: Border.all(
            color: aktif ? Colors.cyanAccent : Colors.white12,
            width: aktif ? 2.0 : 1.0,
          ),
          boxShadow: aktif ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 10)] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          baslik,
          style: TextStyle(
            color: aktif ? Colors.cyanAccent : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _mini3dButon({required String metin, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF052136),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.cyanAccent, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          metin,
          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.8),
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
        Text(baslik, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF050811),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF183B5E), width: 1.4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            obscureText: sifreli,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            cursorColor: Colors.cyanAccent,
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.cyan.withOpacity(0.7), size: 18),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
        ),
      ],
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
              const SizedBox(height: 12),
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

  // ============================================================
  // SİBERPUNK + MENÜSÜ
  // ============================================================
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: 45,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _kategoriBasligi("GÖRSEL & KAMERA ALGILAMA"),
                        _listeOgesi(
                          icon: Icons.remove_red_eye,
                          baslik: 'Canlı Algıla (Kamera Modu)',
                          altBaslik: 'Ortamı ve nesneleri anlık incelet',
                          onTap: _fotografCek,
                          context: sheetContext,
                        ),
                        _listeOgesi(
                          icon: Icons.photo_library,
                          baslik: 'Fotoğraf & Galeri',
                          altBaslik: 'Kamera veya galeriden görsel yükle',
                          onTap: _galeridenSec,
                          context: sheetContext,
                        ),
                        _listeOgesi(
                          icon: Icons.document_scanner,
                          baslik: 'OCR (Görsel Metin Taraması)',
                          altBaslik: 'Kitap, tabela veya belgedeki yazıları okut',
                          onTap: _fotografCek,
                          context: sheetContext,
                        ),

                        _kategoriBasligi("MESAJLAŞMA & SOSYAL MEDYA"),
                        _listeOgesi(
                          icon: Icons.chat,
                          baslik: 'WhatsApp & Mesajlaşma',
                          altBaslik: 'Sohbet geçmişi yedeği veya ses kaydı yükle',
                          onTap: () => _gonderilecekMesaj("WhatsApp sohbet geçmişi yüklendi, analiz et."),
                          context: sheetContext,
                        ),
                        _listeOgesi(
                          icon: Icons.push_pin,
                          baslik: 'Pinterest & İlham Panoları',
                          altBaslik: 'Pano veya görsel linki analiz ettir',
                          onTap: () => _gonderilecekMesaj("Pinterest panosu yüklendi, incele."),
                          context: sheetContext,
                        ),
                        _listeOgesi(
                          icon: Icons.share,
                          baslik: 'Facebook & Instagram',
                          altBaslik: 'Gönderi veya paylaşım incele',
                          onTap: () => _gonderilecekMesaj("Sosyal medya gönderisi analize gönderildi."),
                          context: sheetContext,
                        ),
                        _listeOgesi(
                          icon: Icons.video_library,
                          baslik: 'YouTube & TikTok',
                          altBaslik: 'Video bağlantısı verip özet al',
                          onTap: () => _gonderilecekMesaj("Video bağlantısı özet için gönderildi."),
                          context: sheetContext,
                        ),

                        _kategoriBasligi("BULUT & DOSYA DEPOLAMA"),
                        _listeOgesi(
                          icon: Icons.cloud_queue,
                          baslik: 'Bulut Depolama Servisleri',
                          altBaslik: 'Google Drive, OneDrive, Dropbox, iCloud...',
                          onTap: _bulutServisiSec,
                          context: sheetContext,
                        ),
                        _listeOgesi(
                          icon: Icons.insert_drive_file,
                          baslik: 'Belge & Doküman',
                          altBaslik: 'PDF, Word, TXT ve sözleşme dosyaları',
                          onTap: _dosyaSec,
                          context: sheetContext,
                        ),

                        _kategoriBasligi("3D, YAZILIM & PROJE DOSYALARI"),
                        _listeOgesi(
                          icon: Icons.view_in_ar,
                          baslik: '3D & CAD Modelleri',
                          altBaslik: 'SKP, DAE, STL, OBJ dosyaları yükle',
                          onTap: _dosyaSec,
                          context: sheetContext,
                        ),
                        _listeOgesi(
                          icon: Icons.code,
                          baslik: 'Kod & Proje Deposu',
                          altBaslik: 'Dart, Python, ZIP veya GitHub bağlantısı',
                          onTap: _dosyaSec,
                          context: sheetContext,
                        ),

                        _kategoriBasligi("İŞ & ÜRETKENLİK"),
                        _listeOgesi(
                          icon: Icons.graphic_eq,
                          baslik: 'Ses & Müzik Dosyası',
                          altBaslik: 'Ses kaydını metne dök ve özetlet',
                          onTap: _dosyaSec,
                          context: sheetContext,
                        ),
                        _listeOgesi(
                          icon: Icons.content_paste,
                          baslik: 'Panodan Yapıştır',
                          altBaslik: 'Kopyalanan metni/kodu hızlıca aktar',
                          onTap: () => _gonderilecekMesaj("Panodaki metin aktarıldı, incelensin."),
                          context: sheetContext,
                        ),

                        if (_ozelAraclar.isNotEmpty) ...[
                          _kategoriBasligi("ÖZEL EKLENEN ARAÇLAR"),
                          ..._ozelAraclar.map((arac) => _listeOgesi(
                                icon: Icons.extension,
                                baslik: arac,
                                altBaslik: 'Kullanıcı tanımlı özel araç',
                                onTap: () => _gonderilecekMesaj("$arac aracı çalıştırıldı."),
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
      padding: const EdgeInsets.only(top: 14, bottom: 6, left: 8),
      child: Text(
        baslik,
        style: const TextStyle(
          color: Colors.cyan,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _listeOgesi({
    required IconData icon,
    required String baslik,
    required String altBaslik,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.cyan.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.cyan, size: 22),
      ),
      title: Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(altBaslik, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _bulutServisiSec() {
    showDialog(
      context: context,
      builder: (cloudContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F111A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.cyan, width: 1.2),
          ),
          title: const Text('Bulut Servisi Seçin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _bulutOgesi(icon: Icons.add_to_drive, baslik: 'Google Drive', context: cloudContext),
              _bulutOgesi(icon: Icons.cloud_outlined, baslik: 'Microsoft OneDrive', context: cloudContext),
              _bulutOgesi(icon: Icons.folder_zip_outlined, baslik: 'Dropbox', context: cloudContext),
              _bulutOgesi(icon: Icons.apple, baslik: 'iCloud Drive', context: cloudContext),
            ],
          ),
        );
      },
    );
  }

  Widget _bulutOgesi({required IconData icon, required String baslik, required BuildContext context}) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyan),
      title: Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        _dosyaSec();
      },
    );
  }

  Future<void> _fotografCek() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _cevapVer("Çekilen fotoğraf Ares'e iletildi. Görsel inceleniyor...");
    }
  }

  Future<void> _galeridenSec() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _cevapVer("Galeriden seçilen '${image.name}' görseli Ares'e iletildi.");
    }
  }

  Future<void> _dosyaSec() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      _cevapVer("Yüklenen '${result.files.first.name}' belgesi Ares'e gönderildi.");
    }
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

          // 2. ORTA ANA SOHBET ALANI (DİNAMİK YAZI BOYUTLU)
          Positioned(
            left: screenWidth * 0.28,
            right: screenWidth * 0.29,
            top: screenHeight * 0.24,
            bottom: screenHeight * 0.22,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF030508),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: SingleChildScrollView(
                child: Text(
                  _metin,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _yaziBoyutu,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
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
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_off,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 7. ORTA PANEL: CANLI SİBERPUNK SPEKTRUMU / GÖNDER BUTONU
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
                    BoxShadow(
                      color: Color(0x660052CC),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: _yaziVar
                    ? const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 24,
                      )
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
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
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

          // 9. ÜST PANEL: SOL 3 ÇİZGİ AYARLAR BUTONU
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
                setState(() => _metin = "Merhaba $_kullaniciAdi $_hitapSekli, yeni sohbet başladı.");
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
