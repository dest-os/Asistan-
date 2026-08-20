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
  String _bgImage = '';
  String _kullaniciAdi = 'Kullanıcı';
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
    
    _initTts();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _yukle();
  }

  void _initTts() async {
    await _tts.setLanguage("tr-TR");
    
    _tts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _konusuyor = true;
        });
      }
    });
    
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _konusuyor = false;
        });
        if (!_sessizMod) _otomatikDinlemeBaslat();
      }
    });

    _tts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _konusuyor = false;
        });
      }
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
    String secim = prefs.getString('secilen_karakter') ?? 'KADIN';
    String kayitliIsim = prefs.getString('kullanici_adi') ?? 'Kullanıcı';

    if (mounted) {
      setState(() {
        // Türkçe karakter ve boşluk sorunları düzeltilmiş dosya adları
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
        onError: (errorNotification) {
          if (mounted) {
            setState(() {
              _dinliyor = false;
            });
          }
        },
      );
      
      if (available && !_sessizMod && !_konusuyor) {
        if (mounted) {
          setState(() {
            _dinliyor = true;
          });
        }
        _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              _cevapVer(result.recognizedWords);
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dinliyor = false;
        });
      }
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
      if (mounted) {
        setState(() {
          _konusuyor = false;
        });
      }
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

    // MİKROFON BUTONUNUN KOORDİNATLARI (TASARIM SABİT)
    double micLeft = MediaQuery.of(context).size.width * 0.665;
    double micBottom = MediaQuery.of(context).size.height * 0.08;
    double micWidth = 50;
    double micHeight = 50;

    return Scaffold(
      body: Stack(
        children: [
          // Arka Plan Görseli
          Positioned.fill(
            child: Image.asset(
              _bgImage, 
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                // Görsel yüklenemezse siyah ekran basıp çökmesini önler
                return Container(color: Colors.black);
              },
            ),
          ),

          // Metin Kutusu
          Positioned(
            left: MediaQuery.of(context).size.width * 0.26,
            right: MediaQuery.of(context).size.width * 0.30,
            top: MediaQuery.of(context).size.height * 0.38,
            height: 75,
            child: Container(
              color: Colors.black, 
              alignment: Alignment.center, 
              child: Text(
                _metin, 
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // MİKROFON BUTONU (TIKLANABİLİR KATMAN)
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
              child: Container(color: Colors.transparent),
            ),
          ),

          // ANİMASYON KATMANI (DİNLEME VEYA KONUŞMA ANINDA GÖRÜNÜR)
          if (_dinliyor || _konusuyor)
            Positioned(
              left: micLeft,
              bottom: micBottom,
              width: micWidth,
              height: micHeight,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Dışarıya Doğru Genişleyen Halka
                          Container(
                            width: micWidth + (_waveController.value * 25),
                            height: micHeight + (_waveController.value * 25),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyan.withOpacity((1 - _waveController.value).clamp(0.0, 1.0)), 
                                width: 2,
                              ),
                            ),
                          ),
                          // Ortadaki Ses Çizgileri
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (i) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                width: 3,
                                height: 12 + (sin((_waveController.value * 2 * pi) + (i * 0.8)).abs() * 8),
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
                ),
              ),
            ),
        ],
      ),
    );
  }
}
