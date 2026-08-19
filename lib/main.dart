import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'giris_ekrani.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ekranı tamamen YATAY moda kilitliyoruz
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const AresApp());
  });
}

class AresApp extends StatelessWidget {
  const AresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARES Asistan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const GirisEkrani(),
    );
  }
}
