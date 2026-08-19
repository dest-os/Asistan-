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
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              // SOL PANEL: Karakter Görseli (Kayma Olmadan Tam Sığdırma)
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF005580), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            _secilenKarakter == 'KADIN' ? 'assets/kadin_ares.png' : 'assets/erkek_ares.png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF005580)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.white70, size: 14),
                              SizedBox(width: 6),
                              Text('Arama', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ORTA PANEL: Sohbet
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF005580), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu, color: Colors.white70, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'ARES',
                                style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Icon(Icons.keyboard_arrow_down, color: Color(0xFF00E5FF), size: 18),
                            ],
                          ),
                          Icon(Icons.refresh, color: Colors.white70, size: 18),
                        ],
                      ),

                      Expanded(
                        child: Center(
                          child: Text(
                            'Merhaba $_kullaniciAdi, senin için ne yapabilirim?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050505),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF003355)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: Colors.white54, size: 18),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Herhangi bir şey sor',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ),
                            const Icon(Icons.mic_none, color: Colors.white70, size: 18),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0066FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // SAĞ PANEL: Logo
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF005580), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF005580)),
                          ),
                          child: const Icon(Icons.save_outlined, color: Color(0xFF0066FF), size: 16),
                        ),
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
