import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SohbetEkrani extends StatefulWidget {
  const SohbetEkrani({super.key});

  @override
  State<SohbetEkrani> createState() => _SohbetEkraniState();
}

class _SohbetEkraniState extends State<SohbetEkrani> {
  String _kullaniciAdi = '';
  String _secilenKarakter = 'KADIN';
  bool _yuklendi = false;

  @override
  void initState() {
    super.initState();
    _tercihleriYukle();
  }

  // Giriş ekranında kaydedilen verileri okuma
  Future<void> _tercihleriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _kullaniciAdi = prefs.getString('kullanici_adi') ?? 'Kullanıcı';
      _secilenKarakter = prefs.getString('secilen_karakter') ?? 'KADIN';
      _yuklendi = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // 1. SOL PANEL (Seçilen Karakter Görseli ve Arama)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF005580), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: Image.asset(
                            _secilenKarakter == 'KADIN'
                                ? 'assets/images/ares_kadın.png'
                                : 'assets/images/ares_erkek.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person,
                              size: 80,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF005580)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: Colors.white54, size: 16),
                            SizedBox(width: 4),
                            Text('Arama', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 2. ORTA PANEL (Ana Sohbet Alanı)
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF005580), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      // Üst Başlık Barı
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu, color: Colors.white70, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'ARES',
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down, color: Color(0xFF00E5FF), size: 20),
                            ],
                          ),
                          Icon(Icons.refresh, color: Colors.white70, size: 20),
                        ],
                      ),

                      // Orta Karşılama Alanı
                      Expanded(
                        child: Center(
                          child: Text(
                            'Merhaba $_kullaniciAdi, senin için ne yapabilirim?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      // Alt Giriş ve Butonlar Barı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF003355)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: Colors.white54, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Herhangi bir şey sor',
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ),
                            const Icon(Icons.mic_none, color: Colors.white70, size: 20),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0066FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 3. SAĞ PANEL (Logo ve Kaydet Butonu)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF005580), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 100,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.remove_red_eye,
                              size: 60,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF005580)),
                        ),
                        child: const Icon(Icons.save_outlined, color: Color(0xFF0066FF), size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
