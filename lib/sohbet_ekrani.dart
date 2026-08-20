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

  late AnimationController _pulseController;
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.8,
      upperBound: 1.2,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _yukle();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    String secim = prefs.getString('secilen_karakter') ?? 'KADIN';
    String kayitliIsim = prefs.getString('kullanici_adi') ?? 'Kullanıcı';

    setState(() {
      _bgImage = (secim == 'KADIN')
          ? 'assets/kadin_ares_ekrani.png'
          : 'assets/erkek_ares ekrani.png';
      _kullaniciAdi = kayitliIsim;
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
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.remove_red_eye, color: Colors.cyan),
                title: const Text('Canlı Algıla (Kamera Modu)', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Kamerayı açıp etrafı incelemesini sağla', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _fotografCek();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.cyan),
                title: const Text('Fotoğraf Çek', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _fotografCek();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.cyan),
                title: const Text('Galeriden Görsel Seç', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _galeridenSec();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file, color: Colors.cyan),
                title: const Text('Belge / Dosya Yükle', style: TextStyle(color: Colors.white)),
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
            left: MediaQuery.of(context).size.width * 0.58,
            bottom: MediaQuery.of(context).size.height * 0.08,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _artiMenusuAc,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sessizModDegistir,
                  child: ScaleTransition(
                    scale: _dinliyor ? _pulseController : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _sessizMod 
                            ? Colors.red.withOpacity(0.2) 
                            : (_dinliyor ? Colors.cyan.withOpacity(0.3) : Colors.transparent),
                        border: Border.all(
                          color: _sessizMod 
                              ? Colors.red 
                              : (_dinliyor ? Colors.cyan : Colors.transparent),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _sessizMod ? Icons.mic_off : Icons.mic,
                        color: _sessizMod ? Colors.red : (_dinliyor ? Colors.cyan : Colors.white),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(4, (index) {
                        double height = 8;
                        if (_dinliyor || _konusuyor) {
                          height = 8 + (Random().nextDouble() * 16 * _waveController.value);
                        }
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 3,
                          height: height,
                          decoration: BoxDecoration(
                            color: (_dinliyor || _konusuyor) ? Colors.cyan : Colors.white54,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
