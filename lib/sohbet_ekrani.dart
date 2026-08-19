import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SohbetEkrani extends StatefulWidget {
  const SohbetEkrani({super.key});

  @override
  State<SohbetEkrani> createState() => _SohbetEkraniState();
}

class _SohbetEkraniState extends State<SohbetEkrani> {
  String _karakter = 'KADIN';
  bool _yuklendi = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _karakter = prefs.getString('secilen_karakter') ?? 'KADIN';
      _yuklendi = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) return const Scaffold(backgroundColor: Colors.black);

    // GÖNDERDİĞİN O GÜZEL TAM EKRAN TASARIMLARINI BURAYA YÜKLÜYORUZ
    String bgImage = _karakter == 'KADIN' ? 'assets/Kadın ares ekranı.png' : 'assets/Erkek ares ekranı.png';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. ADIM: TAM EKRAN TASARIMIN
          Positioned.fill(
            child: Image.asset(bgImage, fit: BoxFit.fill),
          ),
          
          // 2. ADIM: SADECE YAZI YAZILACAK YERİ (TextField) GÖRÜNMEZ ŞEKİLDE EKLİYORUZ
          // Bu TextField'ı, senin tasarımındaki giriş yerinin üzerine denk getirmemiz lazım.
          // Kodda 'bottom' değerini deneme yanılma ile 5-10 piksel kaydırarak tam oturtabilirsin.
          Positioned(
            left: 280, // Burayı tasarımına göre tasarımındaki giriş alanına göre sağ/sol ayarla
            right: 320,
            bottom: 40, 
            height: 50,
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
