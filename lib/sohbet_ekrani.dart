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
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // SOL PANEL: Seçilen Karakterin Boydan/Büst Resmi
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF005580), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          _secilenKarakter == 'KADIN' ? 'assets/kadin_ares.png' : 'assets/erkek_ares.png',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF005580)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.white70, size: 16),
                              SizedBox(width: 6),
                              Text('Arama', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // ORTA PANEL: Mesajlaşma Alanı
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF005580), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu, color: Colors.white70, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'ARES',
                                style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Icon(Icons.keyboard_arrow_down, color: Color(0xFF00E5FF), size: 20),
                            ],
                          ),
                          Icon(Icons.refresh, color: Colors.white70, size: 20),
                        ],
                      ),

                      Expanded(
                        child: Center(
                          child: Text(
                            'Merhaba $_kullaniciAdi, senin için ne yapabilirim?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050505),
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

              const SizedBox(width: 10),

              // SAĞ PANEL: Büyük Logo ve Disket Simgesi
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF005580), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF005580)),
                          ),
                          child: const Icon(Icons.save_outlined, color: Color(0xFF0066FF), size: 18),
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
