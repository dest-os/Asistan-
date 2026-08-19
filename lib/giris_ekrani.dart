import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sohbet_ekrani.dart';

class GirisEkrani extends StatelessWidget {
  const GirisEkrani({super.key});

  Future<void> _secimYap(BuildContext context, String karakter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secilen_karakter', karakter);
    
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SohbetEkrani()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            // KADIN ARES
            Expanded(
              child: GestureDetector(
                onTap: () => _secimYap(context, 'KADIN'),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    'assets/kadin_ares.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // ERKEK ARES
            Expanded(
              child: GestureDetector(
                onTap: () => _secimYap(context, 'ERKEK'),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    'assets/erkek_ares.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
