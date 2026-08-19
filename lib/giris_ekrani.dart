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
    
    // Girilen ismi kaydet, boş bırakılırsa varsayılan Kullanıcı yap
    String girilenIsim = _kullaniciAdiController.text.trim();
    if (girilenIsim.isEmpty) {
      girilenIsim = 'Kullanıcı';
    }
    await prefs.setString('kullanici_adi', girilenIsim);

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
          // Arka Plan Görseli
          Positioned.fill(
            child: Image.asset(
              'assets/giris_ekrani.png',
              fit: BoxFit.fill,
            ),
          ),

          // Kadın Ares Tıklama Alanı (Sol)
          Positioned(
            left: 0,
            top: 0,
            width: MediaQuery.of(context).size.width * 0.35,
            height: MediaQuery.of(context).size.height * 0.5,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() => _secilenKarakter = 'KADIN');
                _devamEt();
              },
            ),
          ),

          // Erkek Ares Tıklama Alanı (Sağ)
          Positioned(
            right: 0,
            top: 0,
            width: MediaQuery.of(context).size.width * 0.35,
            height: MediaQuery.of(context).size.height * 0.5,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() => _secilenKarakter = 'ERKEK');
                _devamEt();
              },
            ),
          ),

          // Kullanıcı Adı Yazma Kutusu
          Positioned(
            left: MediaQuery.of(context).size.width * 0.42,
            top: MediaQuery.of(context).size.height * 0.53,
            width: MediaQuery.of(context).size.width * 0.33,
            height: 45,
            child: TextField(
              controller: _kullaniciAdiController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
