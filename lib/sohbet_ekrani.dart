import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SohbetEkrani extends StatefulWidget {
  const SohbetEkrani({super.key});

  @override
  State<SohbetEkrani> createState() => _SohbetEkraniState();
}

class _SohbetEkraniState extends State<SohbetEkrani> {
  String _bgImage = '';
  String _kullaniciAdi = 'Kullanıcı';
  bool _yuklendi = false;

  @override
  void initState() {
    super.initState();
    _yukle();
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
            child: Image.asset(
              _bgImage,
              fit: BoxFit.fill,
            ),
          ),
          // Resimdeki Sabit Yazıyı Kapatıp Tam Ortalanmış Dinamik Metin Alanı
          Positioned(
            left: MediaQuery.of(context).size.width * 0.26,
            right: MediaQuery.of(context).size.width * 0.30,
            top: MediaQuery.of(context).size.height * 0.38,
            height: 70,
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Merhaba $_kullaniciAdi, senin için ne yapabilirim?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
