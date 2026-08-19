import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SohbetEkrani extends StatefulWidget {
  const SohbetEkrani({super.key});

  @override
  State<SohbetEkrani> createState() => _SohbetEkraniState();
}

class _SohbetEkraniState extends State<SohbetEkrani> {
  String _bgImage = '';
  bool _yuklendi = false;

  @override
  void initState() {
    super.initState();
    _ayarlariYukle();
  }

  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    // GirisEkrani'nda kaydedilen seçimi alıyoruz
    String secim = prefs.getString('secilen_karakter') ?? 'KADIN';
    
    setState(() {
      // Dosya isimlerini tam olarak senin gönderdiğin şekilde tanımladık
      _bgImage = (secim == 'KADIN') 
          ? 'assets/kadin_ares_ekrani.png' 
          : 'assets/erkek_ares ekrani.png';
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
          // 1. Arka plan görseli
          Positioned.fill(
            child: Image.asset(
              _bgImage, 
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Kullanıcının yazı yazacağı alan
          // Tasarımına göre "Herhangi bir şey sor" yazan yere konumlandırıldı
          Positioned(
            left: 280, 
            right: 320,
            bottom: 45, 
            height: 40,
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Herhangi bir şey sor...',
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
