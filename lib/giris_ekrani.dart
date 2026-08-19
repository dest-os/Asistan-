import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sohbet_ekrani.dart';

class GirisEkrani extends StatelessWidget {
  const GirisEkrani({super.key});

  Future<void> _secimYap(BuildContext context, String karakter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secilen_karakter', karakter);
    
    if(!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SohbetEkrani()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // KADIN
          Expanded(
            child: GestureDetector(
              onTap: () => _secimYap(context, 'KADIN'),
              child: Image.asset(
                'assets/kadin_ares.png', 
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // ERKEK
          Expanded(
            child: GestureDetector(
              onTap: () => _secimYap(context, 'ERKEK'),
              child: Image.asset(
                'assets/erkek_ares.png', 
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
