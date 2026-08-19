import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sohbet_ekrani.dart';

class GirisEkrani extends StatelessWidget {
  const GirisEkrani({super.key});

  Future<void> _devamEt(BuildContext context, String karakter, String isim) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kullanici_adi', isim.isEmpty ? 'İbrahim' : isim);
    await prefs.setString('secilen_karakter', karakter);
    
    if(!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SohbetEkrani()),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // KARTLAR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _devamEt(context, 'KADIN', controller.text),
                  child: Image.asset('assets/kadin_ares.png', height: 250),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _devamEt(context, 'ERKEK', controller.text),
                  child: Image.asset('assets/erkek_ares.png', height: 250),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // GİRİŞ KUTUSU
            SizedBox(
              width: 500,
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Kullanıcı Adı Girin',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black,
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00E5FF))),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00E5FF))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
