import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'giris_ekrani.dart';
import 'sohbet_ekrani.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  // Kayıtlı isim var mı kontrol et
  final String? kullaniciAdi = prefs.getString('kullanici_adi');

  runApp(AresAsistanApp(
    baslangicEkrani: (kullaniciAdi != null && kullaniciAdi.isNotEmpty)
        ? const SohbetEkrani()
        : const GirisEkrani(),
  ));
}

class AresAsistanApp extends StatelessWidget {
  final Widget baslangicEkrani;
  const AresAsistanApp({super.key, required this.baslangicEkrani});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ares Asistan',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: baslangicEkrani,
    );
  }
}
