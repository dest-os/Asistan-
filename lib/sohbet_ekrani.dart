import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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

  late AnimationController _spectrumController;
  late AnimationController _pulseController;

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
        await _tts.setPitch(0.58);
        await _tts.setSpeechRate(0.44);
      } else {
        await _tts.setPitch(1.05);
        await _tts.setSpeechRate(0.50);
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
          Future.delayed(const Duration(milliseconds: 500), () {
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
    List<String> eklenenler = prefs.getStringList('ozel_eklenen_araclar') ?? [];

    String? apilerJson = prefs.getString('kayitli_api_havuzu');
    if (apilerJson != null) {
      try {
        _kayitliApiler = List<Map<String, dynamic>>.from(json.decode(apilerJson));
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

      Future.delayed(const Duration(milliseconds: 600), () {
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
        _metin = "$_karakter ARES arayüzü ve ses motoru aktif edildi $_hitapSekli.";
      });
    }
  }

  // ============================================================
  // DİNLEME VE CEVAP SİSTEMİ
  // ============================================================
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
              if ((status == 'notListening' || status == 'done') && !_sessizMod && !_konusuyor && !_isProcessing) {
                Future.delayed(const Duration(milliseconds: 400), () {
                  if (mounted && !_sessizMod && !_konusuyor && !_dinliyor && !_isProcessing) {
                    _dinlemeBaslat();
                  }
                });
              }
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
          onSoundLevelChange: (level) {
            if (mounted) {
              setState(() {
                _sesSeviyesi = (level / 8.0).clamp(0.1, 1.0);
              });
            }
          },
          onResult: (result) {
            if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
              _cevapVer(result.recognizedWords);
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
    if (_sonCevapZamani != null && now.difference(_sonCevapZamani!).inMilliseconds < 2000) {
      return;
    }
    if (girdi.trim().isEmpty || _konusuyor || _isProcessing) return;

    _sonCevapZamani = now;
    setState(() => _isProcessing = true);
    await _speech.stop();

    String cevap = "Merhaba $_kullaniciAdi $_hitapSekli, sizi dinledim. Ares sistemi devrede.";

    if (mounted) {
      setState(() {
        _metin = cevap;
        _dinliyor = false;
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
  // ⚙️ 3D SİBERPUNK AYARLAR PANELİ (SOL ÇİZGİLERDEN AÇILIR)
  // ============================================================
  void _ayarlarPaneliniAc() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Ayarlar",
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.42,
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
                  // ÜST BAŞLIK & KAPATMA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.cyanAccent, width: 1.2),
                            ),
                            child: const Icon(Icons.settings_suggest_rounded, color: Colors.cyanAccent, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
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
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12, thickness: 1),
                  const SizedBox(height: 10),

                  // KAYDIRILABİLİR 3D AYAR BUTONLARI LİSTESİ
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // 1. KULLANICI PROFİLİ VE HİTAP (3D KART)
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
                                  onTap: _profilDuzenleModal,
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. KARAKTER VE SES GEÇİŞİ (İKİLİ 3D SEÇİCİ)
                        _siberpunk3dKart(
                          baslik: "ARES KARAKTER & SES MODELİ",
                          altBaslik: "Aktif arayüz ve ses motorunu anında değiştirin",
                          icon: Icons.record_voice_over_rounded,
                          child: Row(
                            children: [
                              Expanded(
                                child: _karakterSecim3dButon(
                                  baslik: "ERKEK ARES",
                                  aktif: _karakter == 'ERKEK',
                                  onTap: () {
                                    _karakterDegistir('ERKEK');
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _karakterSecim3dButon(
                                  baslik: "KADIN ARES",
                                  aktif: _karakter == 'KADIN',
                                  onTap: () {
                                    _karakterDegistir('KADIN');
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. YAPAY ZEKA HAVUZU // API YÖNETİMİ (4 KUTULU KAYAR ALAN)
                        _siberpunk3dButon(
                          baslik: "YAPAY ZEKÂ HAVUZU // API YÖNETİMİ",
                          altBaslik: "${_kayitliApiler.length} Yapay Zeka Motoru Tanımlı",
                          icon: Icons.hub_rounded,
                          vurgulu: true,
                          onTap: () {
                            Navigator.pop(context);
                            _apiHavuzuPaneliniAc();
                          },
                        ),
                        const SizedBox(height: 14),

                        // 4. KLONLANMIŞ DOĞAL SES ENTEGRASYONU
                        _siberpunk3dButon(
                          baslik: "KLONLANMIŞ SES ENTEGRASYONU",
                          altBaslik: "ElevenLabs / Özel Doğal Ses API'si Bağla",
                          icon: Icons.graphic_eq_rounded,
                          onTap: () {
                            Navigator.pop(context);
                            _klonSesPaneliniAc();
                          },
                        ),
                        const SizedBox(height: 14),

                        // 5. YAPAY ZEKA İLE SİBERPUNK YÜZ OLUŞTURMA
                        _siberpunk3dButon(
                          baslik: "SİBERPUNK YÜZ & AVATAR ÜRETİCİ",
                          altBaslik: "Kendi fotoğrafından robotik ARES avatarı üret",
                          icon: Icons.face_retouching_natural_rounded,
                          onTap: () {
                            Navigator.pop(context);
                            _yuzOlusturucuModal();
                          },
                        ),
                        const SizedBox(height: 14),

                        // 6. YANIT MODU VE DAVRANIŞ
                        _siberpunk3dButon(
                          baslik: "YANIT MODU VE TAKTİKSEL DAVRANIŞ",
                          altBaslik: "Kısa ve Net / Detaylı Analiz / Komutan Modu",
                          icon: Icons.psychology_alt_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),

                        // 7. SİSTEM & BELLEK SIFIRLAMA
                        _siberpunk3dButon(
                          baslik: "SİSTEM VE BELLEĞİ SIFIRLA",
                          altBaslik: "Önbelleği temizle veya fabrika ayarlarına dön",
                          icon: Icons.delete_sweep_rounded,
                          tehlikeli: true,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),

                        // ➕ GELECEKTEKİ EKLER İÇİN BOŞ REZERV 3D BUTON SLOTLARI
                        _siberpunk3dButon(
                          baslik: "+ ÖZEL MODÜL SLOTU 1",
                          altBaslik: "Yeni yetenek ve entegrasyonlar için ayrıldı",
                          icon: Icons.extension_outlined,
                          pasif: true,
                          onTap: () {},
                        ),
                        const SizedBox(height: 14),
                        _siberpunk3dButon(
                          baslik: "+ ÖZEL MODÜL SLOTU 2",
                          altBaslik: "Yeni yetenek ve entegrasyonlar için ayrıldı",
                          icon: Icons.extension_outlined,
                          pasif: true,
                          onTap: () {},
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

  // ============================================================
  // 🌐 YAPAY ZEKA HAVUZU // 4 BİLGİ GİRİŞ KUTULU KAYAR MODÜL
  // ============================================================
  void _apiHavuzuPaneliniAc() {
    final TextEditingController firmaCtrl = TextEditingController();
    final TextEditingController adresCtrl = TextEditingController();
    final TextEditingController anahtarCtrl = TextEditingController();
    final TextEditingController uzmanlikCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: const Color(0xFF080C14),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.8), width: 1.8),
                boxShadow: [
                  BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 25, spreadRadius: 3),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "YAPAY ZEKÂ HAVUZU // API KAYIT & YÖNETİM",
                        style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView(
                      children: [
                        // FORM GİRİŞ ALANI (4 KUTU)
                        _siberpunkGirisKutusu(
                          baslik: "1. FİRMA / YAPAY ZEKA ADI",
                          hint: "Örn: Google Gemini, OpenAI GPT-4, DeepSeek, Midjourney",
                          controller: firmaCtrl,
                          icon: Icons.business_rounded,
                        ),
                        const SizedBox(height: 12),
                        _siberpunkGirisKutusu(
                          baslik: "2. API ADRESİ (ENDPOINT)",
                          hint: "Örn: https://generativelanguage.googleapis.com/v1beta/...",
                          controller: adresCtrl,
                          icon: Icons.link_rounded,
                        ),
                        const SizedBox(height: 12),
                        _siberpunkGirisKutusu(
                          baslik: "3. API ANAHTARI (SECRET KEY)",
                          hint: "Kullanıcıya özel gizli API anahtarı",
                          controller: anahtarCtrl,
                          icon: Icons.vpn_key_rounded,
                          sifreli: true,
                        ),
                        const SizedBox(height: 12),
                        _siberpunkGirisKutusu(
                          baslik: "4. UZMANLIK ALANI",
                          hint: "Örn: Resim, Video, Metin, Kod, Ses Analizi, 3D",
                          controller: uzmanlikCtrl,
                          icon: Icons.psychology_rounded,
                        ),
                        const SizedBox(height: 18),

                        // SİSTEME KAYDET BUTONU
                        Center(
                          child: GestureDetector(
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

                              firmaCtrl.clear();
                              adresCtrl.clear();
                              anahtarCtrl.clear();
                              uzmanlikCtrl.clear();

                              setModalState(() {});
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF041C32),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.cyanAccent, width: 1.6),
                                boxShadow: [
                                  BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 14),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save_rounded, color: Colors.cyanAccent, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "YAPAY ZEKAYI HAVUZA EKLE",
                                    style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // KAYITLI YAPAY ZEKALAR LİSTESİ
                        const Text(
                          "ARES BÜNYESİNDEKİ AKTİF YAPAY ZEKALAR:",
                          style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 10),

                        if (_kayitliApiler.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                "Henüz harici bir API tanımlanmadı.\nAres varsayılan sistem beyni ile çalışıyor.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white30, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ..._kayitliApiler.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var item = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1322),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.cyan.withOpacity(0.4), width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.memory_rounded, color: Colors.cyanAccent, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item["firma"] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text("Uzmanlık: ${item["uzmanlik"] ?? "Genel"}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () async {
                                      _kayitliApiler.removeAt(idx);
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('kayitli_api_havuzu', json.encode(_kayitliApiler));
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
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

  // ============================================================
  // YARDIMCI 3D WIDGET'LAR
  // ============================================================
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
    bool pasif = false,
  }) {
    Color anaRenk = tehlikeli
        ? Colors.redAccent
        : (vurgulu ? Colors.cyanAccent : (pasif ? Colors.white38 : const Color(0xFF2684FF)));

    return GestureDetector(
      onTap: pasif ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: pasif ? Colors.white.withOpacity(0.02) : const Color(0xFF0A101D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: anaRenk.withOpacity(pasif ? 0.2 : 0.6), width: 1.5),
          boxShadow: pasif
              ? []
              : [
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
                  Text(
                    baslik,
                    style: TextStyle(
                      color: pasif ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(altBaslik, style: TextStyle(color: pasif ? Colors.white24 : Colors.white54, fontSize: 11)),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF052136),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.cyanAccent, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          metin,
          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
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

  void _profilDuzenleModal() {
    final nameCtrl = TextEditingController(text: _kullaniciAdi);
    final hitapCtrl = TextEditingController(text: _hitapSekli);

    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text("İPTAL", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF042940)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('kullanici_adi', nameCtrl.text.trim());
                await prefs.setString('hitap_sekli', hitapCtrl.text.trim());
                setState(() {
                  _kullaniciAdi = nameCtrl.text.trim();
                  _hitapSekli = hitapCtrl.text.trim();
                });
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("KAYDET", style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  void _klonSesPaneliniAc() {
    setState(() => _metin = "Klonlanmış ses API modülü açıldı $_hitapSekli.");
  }

  void _yuzOlusturucuModal() {
    setState(() => _metin = "Siberpunk avatar oluşturucu modülü devrede $_hitapSekli.");
  }

  // ============================================================
  // SİBERPUNK + MENÜSÜ
  // ============================================================
  void _artiMenusuAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                        ),
                        _listeOgesi(
                          icon: Icons.photo_library,
                          baslik: 'Fotoğraf & Galeri',
                          altBaslik: 'Kamera veya galeriden görsel yükle',
                          onTap: _galeridenSec,
                        ),
                        _listeOgesi(
                          icon: Icons.document_scanner,
                          baslik: 'OCR (Görsel Metin Taraması)',
                          altBaslik: 'Kitap, tabela veya belgedeki yazıları okut',
                          onTap: _fotografCek,
                        ),

                        _kategoriBasligi("MESAJLAŞMA & SOSYAL MEDYA"),
                        _listeOgesi(
                          icon: Icons.chat,
                          baslik: 'WhatsApp & Mesajlaşma',
                          altBaslik: 'Sohbet geçmişi yedeği veya ses kaydı yükle',
                          onTap: () => _gonderilecekMesaj("WhatsApp sohbet geçmişi yüklendi, analiz et."),
                        ),
                        _listeOgesi(
                          icon: Icons.push_pin,
                          baslik: 'Pinterest & İlham Panoları',
                          altBaslik: 'Pano veya görsel linki analiz ettir',
                          onTap: () => _gonderilecekMesaj("Pinterest panosu yüklendi, incele."),
                        ),
                        _listeOgesi(
                          icon: Icons.share,
                          baslik: 'Facebook & Instagram',
                          altBaslik: 'Gönderi, yorum dizisi veya paylaşım incele',
                          onTap: () => _gonderilecekMesaj("Sosyal medya gönderisi analize gönderildi."),
                        ),
                        _listeOgesi(
                          icon: Icons.video_library,
                          baslik: 'YouTube & TikTok',
                          altBaslik: 'Video bağlantısı verip özet al',
                          onTap: () => _gonderilecekMesaj("Video bağlantısı özet için gönderildi."),
                        ),

                        _kategoriBasligi("BULUT & DOSYA DEPOLAMA"),
                        _listeOgesi(
                          icon: Icons.cloud_queue,
                          baslik: 'Bulut Depolama Servisleri',
                          altBaslik: 'Google Drive, OneDrive, Dropbox, iCloud...',
                          onTap: _bulutServisiSec,
                        ),
                        _listeOgesi(
                          icon: Icons.insert_drive_file,
                          baslik: 'Belge & Doküman',
                          altBaslik: 'PDF, Word, TXT ve sözleşme dosyaları',
                          onTap: _dosyaSec,
                        ),

                        _kategoriBasligi("3D, YAZILIM & PROJE DOSYALARI"),
                        _listeOgesi(
                          icon: Icons.view_in_ar,
                          baslik: '3D & CAD Modelleri',
                          altBaslik: 'SKP, DAE, STL, OBJ dosyaları yükle',
                          onTap: _dosyaSec,
                        ),
                        _listeOgesi(
                          icon: Icons.code,
                          baslik: 'Kod & Proje Deposu',
                          altBaslik: 'Dart, Python, ZIP veya GitHub bağlantısı',
                          onTap: _dosyaSec,
                        ),

                        _kategoriBasligi("İŞ & ÜRETKENLİK"),
                        _listeOgesi(
                          icon: Icons.graphic_eq,
                          baslik: 'Ses & Müzik Dosyası',
                          altBaslik: 'Ses kaydını metne dök ve özetlet',
                          onTap: _dosyaSec,
                        ),
                        _listeOgesi(
                          icon: Icons.content_paste,
                          baslik: 'Panodan Yapıştır',
                          altBaslik: 'Kopyalanan metni/kodu hızlıca aktar',
                          onTap: () => _gonderilecekMesaj("Panodaki metin aktarıldı, incelensin."),
                        ),

                        if (_ozelAraclar.isNotEmpty) ...[
                          _kategoriBasligi("ÖZEL EKLENEN ARAÇLAR"),
                          ..._ozelAraclar.map((arac) => _listeOgesi(
                                icon: Icons.extension,
                                baslik: arac,
                                altBaslik: 'Kullanıcı tanımlı özel araç',
                                onTap: () => _gonderilecekMesaj("$arac aracı çalıştırıldı."),
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
      builder: (context) {
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
              _bulutOgesi(icon: Icons.add_to_drive, baslik: 'Google Drive'),
              _bulutOgesi(icon: Icons.cloud_outlined, baslik: 'Microsoft OneDrive'),
              _bulutOgesi(icon: Icons.folder_zip_outlined, baslik: 'Dropbox'),
              _bulutOgesi(icon: Icons.apple, baslik: 'iCloud Drive'),
            ],
          ),
        );
      },
    );
  }

  Widget _bulutOgesi({required IconData icon, required String baslik}) {
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
  // EKRAN YERLEŞİMİ (TAM SABİTLENMİŞ BUTONLAR VE MENÜ TETİKLEYİCİSİ)
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
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
