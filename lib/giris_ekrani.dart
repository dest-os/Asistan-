import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sohbet_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  String _secilen = 'KADIN';

  Future<void> _devamEt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secilen_karakter', _secilen);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SohbetEkrani()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // KADIN SEÇİMİ
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _secilen = 'KADIN'),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _secilen == 'KADIN' ? Colors.cyanAccent : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Image.asset('assets/kadin_ares.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  // ERKEK SEÇİMİ
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _secilen = 'ERKEK'),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _secilen == 'ERKEK' ? Colors.cyanAccent : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Image.asset('assets/erkek_ares.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _devamEt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('DEVAM ET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
