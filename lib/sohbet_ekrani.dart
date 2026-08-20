import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

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
    
    // Erkek/Kadın ses tonu uyarlaması
    if (karakter == 'ERKEK') {
      await _tts.setPitch(0.8);  // Kalın erkek tonu
      await _tts.setSpeechRate(0.45);
    } else {
      await _tts.setPitch(1.1);  // İnce kadın tonu
      await _tts.setSpeechRate(0.5);
    }

    try {
      List<dynamic> voices = await _tts.getVoices;
      for (var voice in voices) {
        if (voice is Map) {
          String name = voice["name"].toString().toLowerCase();
          String locale = voice["locale"].toString().toLowerCase();
          
          if (locale.contains("tr")) {
            if (karakter == 'ERKEK' && (name.contains("male") || name.contains("erkek") || name.contains("tr-x-android"))) {
              await _tts.setVoice({"name": voice["name"], "locale": voice["locale"]});
              break;
            } else if (karakter == 'KADIN' && (name.contains("female") || name.contains("kadin"))) {
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

  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }

    // Ekran boyutuna göre orantılı mikrofon konumlandırması
    double micLeft = MediaQuery.of(context).size.width * 0.612;
    double micBottom = MediaQuery.of(context).size.height * 0.115;
    double micWidth = 46;
    double micHeight = 46;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ARKA PLAN
          Positioned.fill(
            child: Image.asset(
              _bgImage,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),

          // YAZI ALANI
          Positioned(
            left: MediaQuery.of(context).size.width * 0.28,
            right: MediaQuery.of(context).size.width * 0.32,
            top: MediaQuery.of(context).size.height * 0.42,
            height: 80,
            child: Container(
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Text(
                _metin,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
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
                  
                  // Dinlerken veya Konuşurken Oluşan Halka ve Dalga
                  if (_dinliyor || _konusuyor)
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Dış Halka
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
                            // İç Çizgiler
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
