import 'package:flutter/material.dart';
import 'ekranlar/giris_ekrani.dart';
import 'ekranlar/sohbet_ekrani.dart';
import 'servisler/depolama_servisi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DepolamaServisi.init();
  runApp(const AresUygulamasi());
}

class AresUygulamasi extends StatelessWidget {
  const AresUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ares Asistan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF2196F3),
      ),
      home: const GirisEkrani(),
    );
  }
}
