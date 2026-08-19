import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sohbet_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  
  Future<void> _secimYap(String karakter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secilen_karakter', karakter);
    
    if(!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SohbetEkrani()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SOL TARAF: KADIN ARES
          Expanded(
            child: GestureDetector(
              onTap: () => _secimYap('KADIN'),
              child: Image.asset(
                'assets/kadin_ares.png', 
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // SAĞ TARAF: ERKEK ARES
          Expanded(
            child: GestureDetector(
              onTap: () => _secimYap('ERKEK'),
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
