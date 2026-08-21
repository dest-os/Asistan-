import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'giris_ekrani.dart';
import 'sohbet_ekrani.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ARES JARVIS Arayüzü İçin Yatay Ekran ve Tam Ekran Kilitlemesi
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Durum çubuklarını gizleyip tam ekran siberpunk deneyimi sağlama
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final prefs = await SharedPreferences.getInstance();
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
      title: 'Ares JARVIS Asistan',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto',
      ),
      home: baslangicEkrani,
    );
  }
}
