import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// MİKROFON ANİMASYON WIDGET'I (HALKA + ÇUBUKLAR)
class MicVisualizer extends StatelessWidget {
  final Animation<double> animation;
  final bool isActive;

  const MicVisualizer({super.key, required this.animation, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Büyüyen Halka (Pulse)
            Container(
              width: 50 + (animation.value * 20),
              height: 50 + (animation.value * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.cyan.withOpacity(1 - animation.value), width: 2),
              ),
            ),
            // Ses Çubukları (Frekans)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 3,
                  height: 10 + (sin(animation.value * 10 + index) * 10).abs(),
                  color: Colors.cyan,
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

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
    )..repeat(); // Animasyon sürekli dönsün

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

  void _sessizModDegistir() {
    setState(() => _sessizMod = !_sessizMod);
    if (_sessizMod) {
      _speech.stop();
      _tts.stop();
      setState(() => _konusuyor = _dinliyor = false);
    } else {
      _otomatikDinlemeBaslat();
    }
  }

  // ... (Menü metotları ve diğer kısımlar aynı kalıyor) ...
  // [Kısalık adına menü metotlarını atladım, önceki kodun aynısıdır]

  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) return const Scaffold(backgroundColor: Colors.black);

    // Mikrofon butonunun bulunduğu koordinatlar
    double micLeft = MediaQuery.of(context).size.width * 0.665;
    double micBottom = MediaQuery.of(context).size.height * 0.08;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(_bgImage, fit: BoxFit.fill)),

          // --- SES ANİMASYONUNUN YERİ ---
          Positioned(
            left: micLeft - 2, // Butonla tam hizalı
            bottom: micBottom + 3,
            child: MicVisualizer(
              animation: _waveController,
              isActive: _dinliyor || _konusuyor,
            ),
          ),

          // ... Metin alanı ve butonlar aynı yerlerinde ...
          // Positioned(left: MediaQuery.of(context).size.width * 0.26 ...
          // Positioned(left: micLeft, bottom: micBottom ... [Butonlar]
        ],
      ),
    );
  }
}
