import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sohbet_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  String _secilenKarakter = 'KADIN';
  final TextEditingController _kullaniciAdiController = TextEditingController();

  Future<void> _devamEt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secilen_karakter', _secilenKarakter);
    if (_kullaniciAdiController.text.isNotEmpty) {
      await prefs.setString('kullanici_adi', _kullaniciAdiController.text);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SohbetEkrani()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Orijinal Giriş Ekranı Görseli
          Positioned.fill(
            child: Image.asset(
              'assets/giris_ekrani.png',
              fit: BoxFit.fill,
            ),
          ),

          // 2. Sol Taraf (KADIN ARES Tıklama Alanı)
          Positioned(
            left: 0,
            top: 0,
            width: MediaQuery.of(context).size.width * 0.35,
            height: MediaQuery.of(context).size.height * 0.6,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _secilenKarakter = 'KADIN'),
            ),
          ),

          // 3. Sağ Taraf (ERKEK ARES Tıklama Alanı)
          Positioned(
            right: 0,
            top: 0,
            width: MediaQuery.of(context).size.width * 0.35,
            height: MediaQuery.of(context).size.height * 0.6,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _secilenKarakter = 'ERKEK'),
            ),
          ),

          // 4. Kullanıcı Adı Giriş Kutusu
          Positioned(
            left: MediaQuery.of(context).size.width * 0.42,
            top: MediaQuery.of(context).size.height * 0.53,
            width: MediaQuery.of(context).size.width * 0.33,
            height: 45,
            child: TextField(
              controller: _kullaniciAdiController,
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 16),
              cursorColor: Colors.cyanAccent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '',
              ),
              onSubmitted: (_) => _devamEt(),
            ),
          ),
        ],
      ),
    );
  }
}
