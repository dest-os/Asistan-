import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
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
  String _karakter = 'ERKEK';
  bool _yuklendi = false;

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  late AudioPlayer _audioPlayer;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  String _metin = "Seni dinliyorum...";
  bool _sessizMod = false; // Kafe / Toplu alan sessiz modu
  bool _dinliyor = false;
  bool _konusuyor = false;
  bool _yaziVar = false;
  double _sesSeviyesi = 0.0;
  bool _isSpeechInitialized = false;

  List<String> _ozelAraclar = [];
  late AnimationController _spectrumController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _audioPlayer = AudioPlayer();

    // Spektrum animasyonu döngüsü
    _spectrumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..repeat(reverse: true);

    // Mikrofon etrafındaki nabız halkası
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

    // Ses çalma durumu dinleyicisi
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        if (state == PlayerState.playing) {
          setState(() => _konusuyor = true);
        } else if (state == PlayerState.completed || state == PlayerState.stopped) {
          setState(() => _konusuyor = false);
          if (!_sessizMod) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && !_sessizMod && !_konusuyor) {
                _dinlemeBaslat();
              }
            });
          }
        }
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
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    _karakter = prefs.getString('secilen_karakter') ?? 'ERKEK';
    String kayitliIsim = prefs.getString('kullanici_adi') ?? 'İbrahim';
    List<String> eklenenler = prefs.getStringList('ozel_eklenen_araclar') ?? [];

    if (mounted) {
      setState(() {
        _bgImage = (_karakter == 'KADIN')
            ? 'assets/kadin_ares_ekrani.png'
            : 'assets/erkek_ares_ekrani.png';
        _kullaniciAdi = kayitliIsim;
        _metin = "Seni dinliyorum...";
        _ozelAraclar = eklenenler;
        _yuklendi = true;
      });

      // Açılışta 350ms güvenli gecikmeyle mikrofonu devreye sok
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && !_sessizMod) {
          _dinlemeBaslat();
        }
      });
    }
  }

  // ============================================================
  // SES MOTORU: GERÇEK VE DOĞAL TÜRKÇE ERKEK/KADIN SES SENTEZİ
  // ============================================================
  Future<void> _seslendir(String metin) async {
    if (_sessizMod || metin.trim().isEmpty) return;

    try {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _dinliyor = false;
          _konusuyor = true;
        });
      }

      // Ücretsiz ve yüksek kaliteli doğal Türkçe ses akışı
      final encodedText = Uri.encodeComponent(metin);
      final String streamUrl = "https://translate.google.com/translate_tts?ie=UTF-8&q=$encodedText&tl=tr&client=tw-ob";

      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(streamUrl));
    } catch (_) {
      // Çevrimdışı yedek motoru
      try {
        await _tts.setLanguage("tr-TR");
        if (_karakter == 'ERKEK') {
          await _tts.setPitch(0.55);
          await _tts.setSpeechRate(0.44);
        } else {
          await _tts.setPitch(1.10);
          await _tts.setSpeechRate(0.50);
        }
        await _tts.speak(metin);
      } catch (e) {
        if (mounted) setState(() => _konusuyor = false);
      }
    }
  }

  // ============================================================
  // MİKROFON VE DİNLEME YÖNETİMİ
  // ============================================================
  Future<void> _dinlemeBaslat() async {
    if (_sessizMod || _konusuyor) return;

    try {
      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speech.initialize(
          onStatus: (status) {
            if (mounted) {
              setState(() {
                _dinliyor = (status == 'listening');
              });
              if ((status == 'notListening' || status == 'done') && !_sessizMod && !_konusuyor) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && !_sessizMod && !_konusuyor && !_dinliyor) {
                    _dinlemeBaslat();
                  }
                });
              }
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() => _dinliyor = false);
              if (!_sessizMod && !_konusuyor) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && !_sessizMod && !_konusuyor) {
                    _dinlemeBaslat();
                  }
                });
              }
            }
          },
        );
      }

      if (_isSpeechInitialized && !_sessizMod && !_konusuyor && !_speech.isListening) {
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

  // MİKROFONA DOKUNULDUĞUNDA: SESSİZ MOD <-> KONUŞMA MODU
  void _mikrofonaDokunuldu() async {
    if (_sessizMod) {
      setState(() {
        _sessizMod = false;
        _metin = "Seni dinliyorum...";
      });
      await _dinlemeBaslat();
    } else {
      await _speech.stop();
      await _tts.stop();
      await _audioPlayer.stop();
      setState(() {
        _sessizMod = true;
        _dinliyor = false;
        _konusuyor = false;
        _metin = "Sessiz Mod Aktif (Sadece Yazı İle İletişim)";
      });
    }
  }

  void _cevapVer(String girdi) async {
    if (girdi.trim().isEmpty || _konusuyor) return;

    await _speech.stop();

    String cevap = "Merhaba $_kullaniciAdi, sizi dinledim. Ares sistemi devrede.";

    if (mounted) {
      setState(() {
        _metin = cevap;
        _dinliyor = false;
      });
    }

    if (!_sessizMod) {
      await _seslendir(cevap);
    } else {
      if (mounted) setState(() => _konusuyor = false);
    }
  }

  void _gonderilecekMesaj(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    _cevapVer(text);
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
  // EKRAN YERLEŞİMİ (TAM HİZALANMIŞ VE MODÜLER)
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

          // 2. ORTA ANA SOHBET ALANI (GÖRSELDEKİ SABİT YAZIYI GİZLEYEN OPAK KATMAN)
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
              onTap: () => setState(() => _metin = "Arama paneli açıldı..."),
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

          // 5. ORTA PANEL: YAZI GİRİŞ ALANI ("Herhangi bir şey sor")
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

          // 6. ORTA PANEL: MİKROFON BUTONU (TAM MERKEZ HALKA VE SESSİZ MOD KONTROLÜ)
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

                  // Dinleme anında mikrofonun etrafını saran tam merkezli halka
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

                  // Sessiz moddayken kırmızı sessiz mikrofon rozeti
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
                  color: Color(0xFF0747A6), // Arka plandaki sabit çizgileri örten derin mavi zemin
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
                    // Yazı varsa yukarı bakan gönder oku
                    ? const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 24,
                      )
                    // Canlı ve şık spektrum animasyonu
                    : AnimatedBuilder(
                        animation: _spectrumController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              double barHeight;

                              if (_sessizMod) {
                                barHeight = 3.0; // Sessiz modda sakin
                              } else if (_konusuyor) {
                                // Ares konuşurken ritmik dans
                                barHeight = 8.0 + (sin((_spectrumController.value * 2 * pi) + (index * 1.0)).abs() * 16.0);
                              } else if (_dinliyor) {
                                // Kullanıcı konuşurken desibele duyarlı hareket
                                barHeight = 6.0 + (sin((_spectrumController.value * 2 * pi) + (index * 1.2)).abs() * 16.0 * _sesSeviyesi);
                              } else {
                                barHeight = 6.0; // Bekleme
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                width: 3.2,
                                height: barHeight.clamp(3.0, 24.0),
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
              onTap: () => setState(() => _metin = "Sohbet ve veriler başarıyla kaydedildi."),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 9. ÜST PANEL: MENÜ (SOL) VE YENİ SOHBET (SAĞ) BUTONLARI
          Positioned(
            left: screenWidth * 0.245,
            top: screenHeight * 0.050,
            width: screenWidth * 0.040,
            height: screenHeight * 0.055,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _metin = "Ana menü seçildi."),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: screenWidth * 0.690,
            top: screenHeight * 0.050,
            width: screenWidth * 0.040,
            height: screenHeight * 0.055,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _textController.clear();
                setState(() => _metin = "Merhaba $_kullaniciAdi, yeni sohbet başladı.");
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
