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
  double _yaziBoyutu = 20.0;
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

  late AnimationController _spectrumController;
  late AnimationController _pulseController;

  final List<Map<String, String>> _hazirKatalog = [
    {
      "id": "google",
      "firma": "Google Gemini",
      "kategori": "ÜCRETSİZ / GÜÇLÜ MODEL",
      "adres": "https://generativelanguage.googleapis.com",
      "uzmanlik": "Genel Zeka, Metin, Sohbet, Kod",
      "link": "https://aistudio.google.com/app/apikey"
    },
    {
      "id": "groq",
      "firma": "Groq Llama 3",
      "kategori": "ÜCRETSİZ / IŞIK HIZINDA",
      "adres": "https://api.groq.com/openai/v1",
      "uzmanlik": "Hızlı Sohbet, Mantık, Kod",
      "link": "https://console.groq.com/keys"
    },
    {
      "id": "nvidia",
      "firma": "NVIDIA NIM",
      "kategori": "ÜCRETSİZ KOTA / OMURGA",
      "adres": "https://integrate.api.nvidia.com",
      "uzmanlik": "Strateji, Mantık, Kodlama",
      "link": "https://build.nvidia.com"
    },
    {
      "id": "openai",
      "firma": "OpenAI GPT-4o",
      "kategori": "API ANAHTARI GEREKLİ",
      "adres": "https://api.openai.com/v1",
      "uzmanlik": "Genel Zeka, Mantık, Veri Analizi",
      "link": "https://platform.openai.com/api-keys"
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
    String kayitliHitap = prefs.getString('hitap_sekli') ?? 'Efendim';

    _hitapSekli = kayitliHitap;
    _yaziBoyutu = prefs.getDouble('yazi_boyutu') ?? 20.0;
    _konusmaHizi = prefs.getDouble('konusma_hizi') ?? 0.46;
    _sesTonu = prefs.getDouble('ses_tonu') ?? 0.58;

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
        _yuklendi = true;
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_sessizMod && !_konusuyor) {
          _dinlemeBaslat();
        }
      });
    }
  }

  // ============================================================
  // 🏛️ SAĞLAM YAPAY ZEKA ÇAĞRI MOTORLARI
  // ============================================================

  // 1. Google Gemini API Çağrısı
  Future<String> _cagriGemini(String apiKey, String soru) async {
    final cleanKey = apiKey.trim();
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$cleanKey");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {
                  "text": "Sen ARES adlı siberpunk yapay zeka asistanısın. Kullanıcıya '$_hitapSekli' diye hitap et. Soruya doğrudan, akıcı ve net Türkçe cevap ver:\n\n$soru"
                }
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        if (text != null) return text.toString().trim();
      }
      return "Gemini Hatası (Kod: ${response.statusCode})";
    } catch (e) {
      return "Gemini Bağlantı Hatası: $e";
    }
  }

  // 2. OpenAI / Groq / NVIDIA Çağrısı
  Future<String> _cagriOpenAIFormat(String urlStr, String apiKey, String modelAdi, String soru) async {
    final cleanKey = apiKey.trim();
    String endpoint = urlStr.trim();
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
          "model": modelAdi,
          "messages": [
            {"role": "system", "content": "Sen ARES asistanısın. Kullanıcıya '$_hitapSekli' diye hitap et. Türkçe cevap ver."},
            {"role": "user", "content": soru}
          ],
          "max_tokens": 800,
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final text = data["choices"]?[0]?["message"]?["content"];
        if (text != null) return text.toString().trim();
      }
      return "API Hatası (Kod: ${response.statusCode})";
    } catch (e) {
      return "API Bağlantı Hatası: $e";
    }
  }

  // ============================================================
  // 🎙️ YEREL CEVAPLAR (API'YE ASLA GİTMEZ)
  // ============================================================
  String? _yerelCevapMi(String soru) {
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
    if (s.contains("kimsin") || s.contains("adın ne")) {
      return "Ben ARES, kişisel siberpunk yapay zekâ asistanınızım $_hitapSekli.";
    }
    return null;
  }

  // ============================================================
  // 🚀 AKILLI CEVAP MOTORU (TÜM APİ'LERİ OTOMATİK DOLAŞIR)
  // ============================================================
  Future<void> _cevapVer(String girdi) async {
    final temizGirdi = girdi.trim();
    if (temizGirdi.isEmpty || _isProcessing) return;

    // 1. Sesli Sistem Komutu mu?
    if (_sesliKomutMu(temizGirdi)) return;

    await _speech.stop();

    // 2. Selamlaşma / Yerel Cevap mı?
    String? yerel = _yerelCevapMi(temizGirdi);
    if (yerel != null) {
      setState(() {
        _metin = yerel;
        _isProcessing = false;
        _dinliyor = false;
      });
      if (!_sessizMod) await _tts.speak(yerel);
      return;
    }

    // 3. API Kontrolü
    if (_kayitliApiler.isEmpty) {
      String mesaj = "Efendim, henüz sisteme bir API anahtarı tanımlanmadı. Lütfen Ayarlar -> Yapay Zekâ Havuzu'ndan Google veya Groq anahtarınızı ekleyin.";
      setState(() {
        _metin = mesaj;
        _isProcessing = false;
      });
      if (!_sessizMod) await _tts.speak(mesaj);
      return;
    }

    // 4. Konsey Değerlendiriyor
    setState(() {
      _isProcessing = true;
      _dinliyor = false;
      _metin = "Konsey değerlendiriyor $_hitapSekli...";
    });

    String nihaiCevap = "";

    // Kayıtlı API'leri sırayla dene
    for (var api in _kayitliApiler) {
      String firma = (api["firma"] ?? "").toString().toLowerCase();
      String anahtar = (api["anahtar"] ?? "").toString().trim();
      String adres = (api["adres"] ?? "").toString().trim();

      if (anahtar.isEmpty) continue;

      if (firma.contains("google") || firma.contains("gemini") || anahtar.startsWith("AIza")) {
        String res = await _cagriGemini(anahtar, temizGirdi);
        if (!res.contains("Hatası")) {
          nihaiCevap = res;
          break;
        }
      } else if (firma.contains("groq")) {
        String res = await _cagriOpenAIFormat("https://api.groq.com/openai/v1", anahtar, "llama-3.3-70b-versatile", temizGirdi);
        if (!res.contains("Hatası")) {
          nihaiCevap = res;
          break;
        }
      } else if (firma.contains("nvidia")) {
        String res = await _cagriOpenAIFormat("https://integrate.api.nvidia.com/v1", anahtar, "meta/llama-3.1-70b-instruct", temizGirdi);
        if (!res.contains("Hatası")) {
          nihaiCevap = res;
          break;
        }
      } else if (adres.isNotEmpty) {
        String res = await _cagriOpenAIFormat(adres, anahtar, "gpt-3.5-turbo", temizGirdi);
        if (!res.contains("Hatası")) {
          nihaiCevap = res;
          break;
        }
      }
    }

    if (nihaiCevap.isEmpty) {
      nihaiCevap = "Efendim, girdiğiniz API anahtarı sunucu tarafından onaylanmadı (Kota veya Geçersiz Anahtar). Lütfen Yapay Zeka Havuzu'ndan anahtarınızı kontrol ediniz.";
    }

    if (mounted) {
      setState(() {
        _metin = nihaiCevap;
        _isProcessing = false;
      });
    }

    if (!_sessizMod) {
      await _tts.speak(nihaiCevap);
    }
  }

  bool _sesliKomutMu(String girdi) {
    String k = girdi.toLowerCase().trim();
    if (k.contains("ayarları aç") || k.contains("ayarlar")) {
      _ayarlarPaneliniAc();
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
            if (mounted) setState(() => _dinliyor = (status == 'listening'));
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
              setState(() => _sesSeviyesi = (level / 8.0).clamp(0.1, 1.0));
            }
          },
          onResult: (result) {
            if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
              _cevapVer(result.recognizedWords.trim());
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

  void _gonderilecekMesaj(String text) {
    if (text.trim().isEmpty || _isProcessing) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    _cevapVer(text);
  }

  // ============================================================
  // 🛡️ POP-UP PENCERELERİ & AYARLAR
  // ============================================================
  void _apiHavuzuPopUpAc() {
    final firmaCtrl = TextEditingController();
    final adresCtrl = TextEditingController();
    final anahtarCtrl = TextEditingController();
    final uzmanlikCtrl = TextEditingController();
    String seciliLink = "https://aistudio.google.com/app/apikey";

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.84,
                  height: MediaQuery.of(context).size.height * 0.88,
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent, width: 2.0),
                    boxShadow: [
                      BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 25),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.hub_rounded, color: Colors.cyanAccent, size: 20),
                              SizedBox(width: 8),
                              Text("YAPAY ZEKÂ HAVUZU // API KATALOĞU", style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      Expanded(
                        child: Row(
                          children: [
                            // SOL: KATALOG
                            Expanded(
                              flex: 4,
                              child: ListView.builder(
                                itemCount: _hazirKatalog.length,
                                itemBuilder: (context, index) {
                                  final item = _hazirKatalog[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0C1424),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      title: Text(item["firma"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      subtitle: Text(item["kategori"]!, style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                                      trailing: const Icon(Icons.touch_app, color: Colors.cyanAccent, size: 16),
                                      onTap: () {
                                        firmaCtrl.text = item["firma"]!;
                                        adresCtrl.text = item["adres"]!;
                                        uzmanlikCtrl.text = item["uzmanlik"]!;
                                        seciliLink = item["link"]!;
                                        setModalState(() {});
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const VerticalDivider(color: Colors.white12, width: 20),
                            // SAĞ: FORM
                            Expanded(
                              flex: 5,
                              child: ListView(
                                children: [
                                  _siberInput("1. MODEL ADI", firmaCtrl, Icons.business),
                                  const SizedBox(height: 8),
                                  _siberInput("2. API ANAHTARI (KEY)", anahtarCtrl, Icons.key, sifreli: true),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () async {
                                      try {
                                        await launchUrl(Uri.parse(seciliLink), mode: LaunchMode.externalApplication);
                                      } catch (_) {}
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF082032),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.cyanAccent),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text("🔑 ÜCRETSİZ API ANAHTARI ALMA SAYFASINI AÇ", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF042940),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                                    ),
                                    onPressed: () async {
                                      if (anahtarCtrl.text.trim().isEmpty) return;
                                      final yeni = {
                                        "firma": firmaCtrl.text.trim().isEmpty ? "Google Gemini" : firmaCtrl.text.trim(),
                                        "adres": adresCtrl.text.trim(),
                                        "anahtar": anahtarCtrl.text.trim(),
                                        "uzmanlik": uzmanlikCtrl.text.trim(),
                                      };
                                      _kayitliApiler.removeWhere((a) => a["firma"] == yeni["firma"]);
                                      _kayitliApiler.add(yeni);

                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('kayitli_api_havuzu', json.encode(_kayitliApiler));

                                      setState(() {});
                                      if (!mounted) return;
                                      Navigator.pop(dialogContext);
                                    },
                                    child: const Text("SİSTEME KAYDET VE AKTİF ET", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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

  Widget _siberInput(String baslik, TextEditingController ctrl, IconData icon, {bool sifreli = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik, style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF050811),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF183B5E)),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: sifreli,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.cyan, size: 14),
              border: InputBorder.none,
              hintText: "Buraya giriniz...",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  void _ayarlarPaneliniAc() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Ayarlar",
      pageBuilder: (panelContext, anim1, anim2) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.44,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF060911).withOpacity(0.98),
                border: const Border(right: BorderSide(color: Colors.cyanAccent, width: 2.0)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ARES // AYARLAR", style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(panelContext)),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          tileColor: const Color(0xFF0A101D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.cyanAccent)),
                          leading: const Icon(Icons.hub, color: Colors.cyanAccent),
                          title: const Text("YAPAY ZEKÂ HAVUZU // API", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          subtitle: Text("${_kayitliApiler.length} API Tanımlı", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.cyanAccent, size: 12),
                          onTap: () {
                            Navigator.pop(panelContext);
                            _apiHavuzuPopUpAc();
                          },
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
  }

  void _artiMenusuAc() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0B10),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.cyanAccent),
                title: const Text("Kamera ile Algıla", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final XFile? p = await _picker.pickImage(source: ImageSource.camera);
                  if (p != null) _cevapVer("Çekilen fotoğraf inceleniyor...");
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.cyanAccent),
                title: const Text("Galeriden Görsel Seç", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final XFile? p = await _picker.pickImage(source: ImageSource.gallery);
                  if (p != null) _cevapVer("Seçilen görsel inceleniyor...");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 🖥️ ARAYÜZ KATMANI
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
          Positioned.fill(
            child: Image.asset(
              _bgImage,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),

          // ORTA METİN ALANI
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
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),

          // "+" BUTONU
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

          // YAZI GİRİŞİ
          Positioned(
            left: screenWidth * 0.315,
            bottom: screenHeight * 0.080,
            width: screenWidth * 0.280,
            height: screenHeight * 0.075,
            child: Center(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(border: InputBorder.none, hintText: ''),
                onSubmitted: _gonderilecekMesaj,
              ),
            ),
          ),

          // MİKROFON BUTONU
          Positioned(
            left: screenWidth * 0.608,
            bottom: screenHeight * 0.082,
            width: 44,
            height: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _mikrofonaDokunuldu,
              child: Container(color: Colors.transparent),
            ),
          ),

          // GÖNDER / SPEKTRUM BUTONU
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
                ),
                alignment: Alignment.center,
                child: _yaziVar
                    ? const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 3.2,
                          height: _dinliyor ? 16.0 : 8.0,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                        )),
                      ),
              ),
            ),
          ),

          // AYARLAR BUTONU (SOL ÜST)
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
        ],
      ),
    );
  }
}
