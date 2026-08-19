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

  Future<void> _devamEt(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secilen_karakter', _secilenKarakter);
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SohbetEkrani()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // KADIN RESMİ
                GestureDetector(
                  onTap: () => setState(() => _secilenKarakter = 'KADIN'),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _secilenKarakter == 'KADIN' ? 1.0 : 0.4,
                    child: Image.asset('assets/kadin_ares.png', height: 250),
                  ),
                ),
                const SizedBox(width: 40),
                // ERKEK RESMİ
                GestureDetector(
                  onTap: () => setState(() => _secilenKarakter = 'ERKEK'),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _secilenKarakter == 'ERKEK' ? 1.0 : 0.4,
                    child: Image.asset('assets/erkek_ares.png', height: 250),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            // DEVAM ET BUTONU
            ElevatedButton(
              onPressed: () => _devamEt(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                'DEVAM ET',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
