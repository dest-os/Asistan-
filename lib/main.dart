import 'package:flutter/material.dart';
import 'giris_ekrani.dart';

void main() {
  runApp(const AresAsistanApp());
}

class AresAsistanApp extends StatelessWidget {
  const AresAsistanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ares Asistan',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const GirisEkrani(),
    );
  }
}
