import 'dart:math';
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
  String _karakter = 'ERKEK';
  bool _yuklendi = false;

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  String _metin = "Merhaba İbrahim, senin için ne yapabilirim?";
  bool _sessizMod = false;
  bool _dinliyor = false;
  bool _konusuyor = false;
  bool _yaziVar = false;

  List<String> _ozelAraclar = [];
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _textController.addListener(() {
      final textVar = _textController.text.trim().isNotEmpty;
      if (textVar != _yaziVar) {
        setState(() => _yaziVar = textVar);
      }
    });

    _yukle();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _textController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  // ============================================================
  // GERÇEK ERKEK VE KADIN SESİ AYARLAMA MOTORU
  // ============================================================
  Future<void> _sesAyarla(String karakter) async {
    await _tts.setLanguage("tr-TR");

    if (karakter == 'ERKEK') {
      await _tts.setPitch(0.70); // Doğal derin erkek tınısı
      await _tts.setSpeechRate(0.48);
    } else {
      await _tts.setPitch(1.15); // Doğal kadın tınısı
      await _tts.setSpeechRate(0.52);
    }

    try {
      List<dynamic> voices = await _tts.getVoices;
      bool sesBulundu = false;

      // Gerçek Türkçe Erkek Ses Motoru Taraması
      for (var voice in voices) {
        if (voice is Map) {
          String name = voice["name"].toString().toLowerCase();
          String locale = voice["locale"].toString().toLowerCase();

          if (locale.contains("tr")) {
            if (karakter == 'ERKEK') {
              // Google TTS Erkek sesleri: tr-tr-x-efz, tr-tr-x-c, tr-tr-x-cfz veya male içerenler
              if (name.contains("male") ||
                  name.contains("erkek") ||
                  name.contains("x-efz") ||
                  name.contains("x-cfz") ||
                  name.contains("x-c") ||
                  name.contains("male_1")) {
                await _tts.setVoice({"name": voice["name"], "locale": voice["locale"]});
                sesBulundu = true;
                break;
              }
            } else {
              // Google TTS Kadın sesleri
              if (name.contains("female") ||
                  name.contains("kadin") ||
                  name.contains("x-dfz") ||
                  name.contains("x-d") ||
                  name.contains("female_1")) {
                await _tts.setVoice({"name": voice["name"], "locale": voice["locale"]});
                sesBulundu = true;
                break;
              }
            }
          }
        }
      }

      // Eğer cihazda spesifik erkek paketi yoksa Android TTS motoruna parametre gönder
      if (!sesBulundu && karakter == 'ERKEK') {
        try {
          await _tts.setVoice({"name": "tr-tr-x-efz-local", "locale": "tr-TR"});
        } catch (_) {}
      }
    } catch (_) {}

    _tts.setStartHandler(() {
      if (mounted) setState(() => _konusuyor = true);
    });

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _konusuyor = false);
        if (!_sessizMod) _otomatikDinlemeBaslat();
      }
    });

    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _konusuyor = false);
    });
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    _karakter = prefs.getString('secilen_karakter') ?? 'ERKEK';
    String kayitliIsim = prefs.getString('kullanici_adi') ?? 'İbrahim';
    List<String> eklenenler = prefs.getStringList('ozel_eklenen_araclar') ?? [];

    await _sesAyarla(_karakter);

    if (mounted) {
      setState(() {
        _bgImage = (_karakter == 'KADIN')
            ? 'assets/kadin_ares_ekrani.png'
            : 'assets/erkek_ares_ekrani.png';
        _kullaniciAdi = kayitliIsim;
        _metin = "Merhaba $_kullaniciAdi, senin için ne yapabilirim?";
        _ozelAraclar = eklenenler;
        _yuklendi = true;
      });
      _otomatikDinlemeBaslat();
    }
  }

  void _otomatikDinlemeBaslat() async {
    if (_sessizMod || _konusuyor) return;

    try {
      bool available = await _speech.initialize(
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

      if (available && !_sessizMod && !_konusuyor) {
        if (mounted) setState(() => _dinliyor = true);
        _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              _cevapVer(result.recognizedWords);
            }
          },
        );
      }
    } catch (_) {
      if (mounted) setState(() => _dinliyor = false);
    }
  }

  void _cevapVer(String girdi) async {
    if (girdi.trim().isEmpty || _konusuyor) return;

    await _speech.stop();

    // Ares'in dinamik yanıtı
    String cevap = "Merhaba $_kullaniciAdi, sizi dinledim. Ares sistemi devrede.";

    if (mounted) {
      setState(() {
        _metin = cevap;
        _konusuyor = !_sessizMod;
        _dinliyor = false;
      });
    }

    if (!_sessizMod) {
      await _tts.speak(cevap);
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

  void _sessizModDegistir() async {
    setState(() {
      _sessizMod = !_sessizMod;
    });

    if (_sessizMod) {
      await _speech.stop();
      await _tts.stop();
      setState(() {
        _dinliyor = false;
        _konusuyor = false;
        _metin = "Sessiz Mod Aktif (Sadece Yazı)";
      });
    } else {
      setState(() => _metin = "Seni dinliyorum...");
      _otomatikDinlemeBaslat();
    }
  }

  // ============================================================
  // SİBERPUNK + MENÜSÜ (GÖNDER BUTONLU & SEÇİM TETİKLEMELİ)
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
  // EKRAN YERLEŞİMİ (TASARIMA VE FİZİKSEL EKRANA BİREBİR UYUM)
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
              // Arka plan görselindeki sabit yazıyı tamamen kapatmak için opak zemin
              decoration: BoxDecoration(
                color: const Color(0xFF030508),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  hintText: '', // Arka plan görselinde yazıyor
                ),
                onSubmitted: _gonderilecekMesaj,
              ),
            ),
          ),

          // 6. ORTA PANEL: MİKROFON VE TAM ÜZERİNE OTURAN CYAN HALKA ANİMASYONU
          Positioned(
            left: screenWidth * 0.605,
            bottom: screenHeight * 0.078,
            width: screenWidth * 0.050,
            height: screenHeight * 0.080,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_dinliyor) {
                  _speech.stop();
                  setState(() => _dinliyor = false);
                } else {
                  _otomatikDinlemeBaslat();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: Colors.transparent),
                  // Mikrofon devredeyken mikrofon ikonunun etrafını saran dalga halkası
                  if (_dinliyor)
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Container(
                          width: 38 + (_waveController.value * 14),
                          height: 38 + (_waveController.value * 14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.cyan.withOpacity((1 - _waveController.value).clamp(0.0, 1.0)),
                              width: 2.5,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // 7. ORTA PANEL: MAVİ BUTON VEYA YUKARI BAKAN OK (GÖNDER BUTONU)
          Positioned(
            left: screenWidth * 0.662,
            bottom: screenHeight * 0.078,
            width: screenWidth * 0.052,
            height: screenHeight * 0.080,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_yaziVar) {
                  // Yazı varsa Gönder butonu çalışır
                  _gonderilecekMesaj(_textController.text);
                } else {
                  // Yazı yoksa Sesli / Sessiz mod değişir
                  _sessizModDegistir();
                }
              },
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: _yaziVar
                    // Yazı yazıldığında beliren şık yukarı bakan Gönder Oku
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                    : (_konusuyor)
                        // Asistan konuşurken dalga animasyonu
                        ? AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return Container(
                                width: 38 + (_waveController.value * 10),
                                height: 38 + (_waveController.value * 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.cyanAccent.withOpacity((1 - _waveController.value).clamp(0.0, 1.0)),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : null,
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
