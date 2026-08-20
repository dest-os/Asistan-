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
    _tts.setStartHandler(() => setState(() => _konusuyor = true));
    _tts.setCompletionHandler(() {
      setState(() => _konusuyor = false);
      if (!_sessizMod) _otomatikDinlemeBaslat();
    });

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

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
      _bgImage = (secim == 'KADIN') ? 'assets/kadin_ares_ekrani.png' : 'assets/erkek_ares ekrani.png';
      _kullaniciAdi = kayitliIsim;
      _ozelAraclar = eklenenler;
      _yuklendi = true;
    });
    _otomatikDinlemeBaslat();
  }

  void _otomatikDinlemeBaslat() async {
    if (_sessizMod || _konusuyor) return;
    bool available = await _speech.initialize(
      onStatus: (status) => setState(() => _dinliyor = (status == 'listening')),
    );
    if (available && !_sessizMod && !_konusuyor) {
      _speech.listen(onResult: (result) {
        if (result.finalResult) _cevapVer(result.recognizedWords);
      });
    }
  }

  void _cevapVer(String girdi) async {
    await _speech.stop();
    setState(() => _konusuyor = true);
    String cevap = "Merhaba $_kullaniciAdi, ben Ares.";
    setState(() => _metin = cevap);
    if (!_sessizMod) await _tts.speak(cevap);
  }

  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) return const Scaffold(backgroundColor: Colors.black);

    // MİKROFON BUTONUNUN KOORDİNATLARI (TASARIM SABİT)
    double micLeft = MediaQuery.of(context).size.width * 0.665;
    double micBottom = MediaQuery.of(context).size.height * 0.08;
    double micWidth = 45;
    double micHeight = 45;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(_bgImage, fit: BoxFit.fill)),

          Positioned(
            left: MediaQuery.of(context).size.width * 0.26,
            right: MediaQuery.of(context).size.width * 0.30,
            top: MediaQuery.of(context).size.height * 0.38,
            height: 75,
            child: Container(
              color: Colors.black, 
              alignment: Alignment.center, 
              child: Text(_metin, style: const TextStyle(color: Colors.white))
            ),
          ),

          // MİKROFON BUTONU (ALT KATMAN)
          Positioned(
            left: micLeft,
            bottom: micBottom,
            width: micWidth,
            height: micHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _otomatikDinlemeBaslat,
              child: Container(color: Colors.transparent),
            ),
          ),

          // ANİMASYON KATMANI (ÜST KATMAN - TASARIMI BOZMADAN)
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
                          Container(
                            width: 30 + (_waveController.value * 20),
                            height: 30 + (_waveController.value * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyan.withOpacity(1 - _waveController.value), 
                                width: 2
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [1, 2, 3].map((i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 3,
                              height: 10 + (sin(_waveController.value * 10 + i) * 8).abs(),
                              color: Colors.cyan,
                            )).toList(),
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
