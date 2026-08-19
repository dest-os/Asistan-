import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'giris_ekrani.dart';
import 'sohbet_ekrani.dart';

void main() async {
  // Flutter alt yapısının tam başlatılmasını sağlar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Kullanıcının daha önce kayıt yapıp yapmadığını kontrol eder
  final prefs = await SharedPreferences.getInstance();
  final bool girisYapildi = prefs.getBool('giris_yapildi') ?? false;

  runApp(AresUygulamasi(girisYapildi: girisYapildi));
}

class AresUygulamasi extends StatelessWidget {
  final bool girisYapildi;

  const AresUygulamasi({super.key, required this.girisYapildi});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARES Yapay Zeka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      // Eğer daha önce giriş yapıldıysa doğrudan SohbetEkrani'na, yapılmadıysa GirisEkrani'na yönlendirir
      home: girisYapildi ? const SohbetEkrani() : const GirisEkrani(),
    );
  }
}
