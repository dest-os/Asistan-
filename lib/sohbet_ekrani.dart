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
  String _bgImage = '';
  String _kullaniciAdi = 'Kullanıcı';
  bool _yuklendi = false;

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  final ImagePicker _picker = ImagePicker();

  String _metin = "Seni dinliyorum...";
  bool _sessizMod = false;
  bool _dinliyor = false;
  bool _konusuyor = false;

  List<String> _ozelAraclar = [];

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _tts.setLanguage("tr-TR");

    _tts.setCompletionHandler(() {
      setState(() => _konusuyor = false);
      if (!_sessizMod) {
        _otomatikDinlemeBaslat();
      }
    });

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _yukle();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    String secim = prefs.getString('secilen_karakter') ?? 'KADIN';
    String kayitliIsim = prefs.getString('kullanici_adi') ?? 'Kullanıcı';
    List<String> eklenenler = prefs.getStringList('ozel_eklenen_araclar') ?? [];

    setState(() {
      _bgImage = (secim == 'KADIN')
          ? 'assets/kadin_ares_ekrani.png'
          : 'assets/erkek_ares ekrani.png';
      _kullaniciAdi = kayitliIsim;
      _ozelAraclar = eklenenler;
      _yuklendi = true;
    });

    _otomatikDinlemeBaslat();
  }

  void _otomatikDinlemeBaslat() async {
    if (_sessizMod || _konusuyor) return;

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'listening') {
          setState(() => _dinliyor = true);
        } else if (status == 'notListening' || status == 'done') {
          setState(() => _dinliyor = false);
        }
      },
    );

    if (available && !_sessizMod && !_konusuyor) {
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _cevapVer(result.recognizedWords);
          }
        },
      );
    }
  }

  void _cevapVer(String girdi) async {
    if (girdi.trim().isEmpty || _konusuyor) return;

    await _speech.stop();

    String cevap = "Merhaba $_kullaniciAdi, ben Ares. Sana nasıl yardımcı olabilirim?";

    setState(() {
      _metin = cevap;
      _konusuyor = !_sessizMod;
      _dinliyor = false;
    });

    if (!_sessizMod) {
      await _tts.speak(cevap);
    } else {
      _otomatikDinlemeBaslat();
    }
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

  void _artiMenusuAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.black90,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: Colors.cyan, width: 1.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(3),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(right: 12),
                        children: [
                          _kategoriBasligi("GÖRSEL & KAMERA ALGILAMA"),
                          _listeOgesi(
                            icon: Icons.remove_red_eye,
                            baslik: 'Canlı Algıla (Kamera Modu)',
                            altBaslik: 'Ortamı ve nesneleri anlık incelet',
                            onTap: () => _fotografCek(),
                          ),
                          _listeOgesi(
                            icon: Icons.photo_library,
                            baslik: 'Fotoğraf & Galeri',
                            altBaslik: 'Kamera veya galeriden görsel yükle',
                            onTap: () => _galeridenSec(),
                          ),
                          _listeOgesi(
                            icon: Icons.document_scanner,
                            baslik: 'OCR (Görsel Metin Taraması)',
                            altBaslik: 'Kitap, tabela veya belgedeki yazıları okut',
                            onTap: () => _fotografCek(),
                          ),

                          _kategoriBasligi("MESAJLAŞMA & SOSYAL MEDYA"),
                          _listeOgesi(
                            icon: Icons.chat,
                            baslik: 'WhatsApp & Mesajlaşma',
                            altBaslik: 'Sohbet geçmişi yedeği veya ses kaydı yükle',
                            onTap: () => _sosyalMedyaSec('WhatsApp'),
                          ),
                          _listeOgesi(
                            icon: Icons.push_pin,
                            baslik: 'Pinterest & İlham Panoları',
                            altBaslik: 'Pano veya görsel linki analiz ettir',
                            onTap: () => _sosyalMedyaSec('Pinterest'),
                          ),
                          _listeOgesi(
                            icon: Icons.share,
                            baslik: 'Facebook & Instagram',
                            altBaslik: 'Gönderi, yorum dizisi veya paylaşım incele',
                            onTap: () => _sosyalMedyaSec('SocialMedia'),
                          ),
                          _listeOgesi(
                            icon: Icons.video_library,
                            baslik: 'YouTube & TikTok',
                            altBaslik: 'Video bağlantısı verip özet al',
                            onTap: () => _sosyalMedyaSec('Video'),
                          ),

                          _kategoriBasligi("BULUT & DOSYA DEPOLAMA"),
                          _listeOgesi(
                            icon: Icons.cloud_queue,
                            baslik: 'Bulut Depolama Servisleri',
                            altBaslik: 'Google Drive, OneDrive, Dropbox, iCloud...',
                            onTap: () => _bulutServisiSec(),
                          ),
                          _listeOgesi(
                            icon: Icons.insert_drive_file,
                            baslik: 'Belge & Doküman',
                            altBaslik: 'PDF, Word, TXT ve sözleşme dosyaları',
                            onTap: () => _dosyaSec(),
                          ),

                          _kategoriBasligi("3D, YAZILIM & PROJE DOSYALARI"),
                          _listeOgesi(
                            icon: Icons.view_in_ar,
                            baslik: '3D & CAD Modelleri',
                            altBaslik: 'SKP, DAE, STL, OBJ dosyaları yükle',
                            onTap: () => _dosyaSec(),
                          ),
                          _listeOgesi(
                            icon: Icons.code,
                            baslik: 'Kod & Proje Deposu',
                            altBaslik: 'Dart, Python, ZIP veya GitHub bağlantısı',
                            onTap: () => _dosyaSec(),
                          ),

                          _kategoriBasligi("İŞ, İÇERİK & ÜRETKENLİK"),
                          _listeOgesi(
                            icon: Icons.graphic_eq,
                            baslik: 'Ses & Müzik Dosyası',
                            altBaslik: 'Ses kaydını metne dök ve özetlet',
                            onTap: () => _dosyaSec(),
                          ),
                          _listeOgesi(
                            icon: Icons.content_paste,
                            baslik: 'Panodan Yapıştır',
                            altBaslik: 'Kopyalanan metni/kodu hızlıca aktar',
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _metin = "Panodaki metin aktarıldı.");
                            },
                          ),
                          _listeOgesi(
                            icon: Icons.link,
                            baslik: 'Web Adresi / Link İncele',
                            altBaslik: 'Bir web sitesi linkini analiz ettir',
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _metin = "Web adresi bekleniyor...");
                            },
                          ),

                          if (_ozelAraclar.isNotEmpty) ...[
                            _kategoriBasligi("ÖZEL EKLENEN ARAÇLAR"),
                            ..._ozelAraclar.map((arac) => _listeOgesi(
                                  icon: Icons.extension,
                                  baslik: arac,
                                  altBaslik: 'Kullanıcı tanımlı özel araç',
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() => _metin = "$arac aracı çalıştırıldı.");
                                  },
                                )),
                          ],
                        ],
                      ),
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
          letterSpacing: 1.1,
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
      leading: Icon(icon, color: Colors.cyan),
      title: Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(altBaslik, style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
          backgroundColor: Colors.black90,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.cyan, width: 1),
          ),
          title: const Text('Bulut Servisi Seçin', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_to_drive, color: Colors.cyan),
                title: const Text('Google Drive', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _dosyaSec();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_outlined, color: Colors.cyan),
                title: const Text('Microsoft OneDrive', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _dosyaSec();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_zip_outlined, color: Colors.cyan),
                title: const Text('Dropbox', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _dosyaSec();
                },
              ),
              ListTile(
                leading: const Icon(Icons.apple, color: Colors.cyan),
                title: const Text('iCloud Drive', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _dosyaSec();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sosyalMedyaSec(String tür) {
    setState(() {
      _metin = "$tür verisi aktarımı bekleniyor...";
    });
  }

  Future<void> _fotografCek() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _metin = "Görsel alındı, inceleniyor...";
      });
    }
  }

  Future<void> _galeridenSec() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _metin = "Görsel galeriden yüklendi.";
      });
    }
  }

  Future<void> _dosyaSec() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _metin = "Dosya yüklendi: ${result.files.first.name}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_bgImage, fit: BoxFit.fill),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.26,
            right: MediaQuery.of(context).size.width * 0.30,
            top: MediaQuery.of(context).size.height * 0.38,
            height: 75,
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _metin,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.265,
            bottom: MediaQuery.of(context).size.height * 0.08,
            width: 45,
            height: 45,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _artiMenusuAc,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.605,
            bottom: MediaQuery.of(context).size.height * 0.08,
            width: 40,
            height: 45,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _sessizModDegistir,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.665,
            bottom: MediaQuery.of(context).size.height * 0.08,
            width: 45,
            height: 45,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _otomatikDinlemeBaslat,
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
