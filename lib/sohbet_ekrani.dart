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
  bool _yuklendi = false;

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  final ImagePicker _picker = ImagePicker();

  String _metin = "Seni dinliyorum...";
  bool _sessizMod = false;
  bool _dinliyor = false;
  bool _konusuyor = false;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _yukle();
  }

  Future<void> _sesAyarla(String karakter) async {
    await _tts.setLanguage("tr-TR");
    
    // Kadın sesini tamamen yok eden kalın erkek bas frekansı
    if (karakter == 'ERKEK') {
      await _tts.setPitch(0.55); // Derin Erkek/Derin Robot Tonu
      await _tts.setSpeechRate(0.42);
    } else {
      await _tts.setPitch(1.2);
      await _tts.setSpeechRate(0.5);
    }

    try {
      List<dynamic> voices = await _tts.getVoices;
      for (var voice in voices) {
        if (voice is Map) {
          String name = voice["name"].toString().toLowerCase();
          String locale = voice["locale"].toString().toLowerCase();
          
          if (locale.contains("tr") && karakter == 'ERKEK') {
            if (name.contains("male") || name.contains("erkek") || name.contains("tr-x")) {
              await _tts.setVoice({"name": voice["name"], "locale": voice["locale"]});
              break;
            }
          }
        }
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

  @override
  void dispose() {
    _waveController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    String secim = prefs.getString('secilen_karakter') ?? 'ERKEK';
    String kayitliIsim = prefs.getString('kullanici_adi') ?? 'İbrahim';

    await _sesAyarla(secim);

    if (mounted) {
      setState(() {
        _bgImage = (secim == 'KADIN') ? 'assets/kadin_ares_ekrani.png' : 'assets/erkek_ares_ekrani.png';
        _kullaniciAdi = kayitliIsim;
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
    await _speech.stop();
    if (mounted) {
      setState(() {
        _dinliyor = false;
        _konusuyor = true;
        _metin = "Düşünüyor...";
      });
    }

    String cevap = "Merhaba $_kullaniciAdi, ben Ares.";

    if (mounted) {
      setState(() {
        _metin = cevap;
      });
    }

    if (!_sessizMod) {
      await _tts.speak(cevap);
    } else {
      if (mounted) setState(() => _konusuyor = false);
    }
  }

  // SİBERPUNK TEMALI + MENÜSÜ
  void _artibutonIslevi() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0E15).withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _eklemeSecenegi(
                icon: Icons.image_search_rounded,
                label: "Galeri",
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null && mounted) {
                      setState(() => _metin = "Görsel seçildi: ${image.name}");
                    }
                  } catch (_) {}
                },
              ),
              _eklemeSecenegi(
                icon: Icons.camera_enhance_rounded,
                label: "Kamera",
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                    if (photo != null && mounted) {
                      setState(() => _metin = "Fotoğraf çekildi.");
                    }
                  } catch (_) {}
                },
              ),
              _eklemeSecenegi(
                icon: Icons.folder_zip_rounded,
                label: "Dosya",
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                    if (result != null && mounted) {
                      setState(() => _metin = "Dosya yüklendi: ${result.files.single.name}");
                    }
                  } catch (_) {}
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _eklemeSecenegi({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: Colors.cyan, width: 1.5),
            ),
            child: Icon(icon, color: Colors.cyan, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }

    double micLeft = MediaQuery.of(context).size.width * 0.612;
    double micBottom = MediaQuery.of(context).size.height * 0.115;
    double micWidth = 46;
    double micHeight = 46;

    double plusLeft = MediaQuery.of(context).size.width * 0.278;
    double plusBottom = MediaQuery.of(context).size.height * 0.115;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ARKA PLAN GÖRSELİ
          Positioned.fill(
            child: Image.asset(
              _bgImage,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),

          // YAZI ALANI
          Positioned(
            left: MediaQuery.of(context).size.width * 0.27,
            right: MediaQuery.of(context).size.width * 0.31,
            top: MediaQuery.of(context).size.height * 0.36,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                _metin,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // + (ARTI) BUTONU ISLEVI
          Positioned(
            left: plusLeft,
            bottom: plusBottom,
            width: micWidth,
            height: micHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _artibutonIslevi,
              child: Container(color: Colors.transparent),
            ),
          ),

          // MİKROFON VE ANİMASYON KATMANI
          Positioned(
            left: micLeft,
            bottom: micBottom,
            width: micWidth,
            height: micHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!_dinliyor && !_konusuyor) {
                  _otomatikDinlemeBaslat();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: Colors.transparent),
                  
                  if (_dinliyor || _konusuyor)
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: micWidth + (_waveController.value * 18),
                              height: micHeight + (_waveController.value * 18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.cyan.withOpacity((1 - _waveController.value).clamp(0.0, 1.0)),
                                  width: 2.5,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(3, (i) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                  width: 3,
                                  height: 10 + (sin((_waveController.value * 2 * pi) + (i * 0.8)).abs() * 8),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
