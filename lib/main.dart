import 'package:flutter/material.dart';
import 'giris_ekrani.dart';
import 'depolama_servisi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Çökme hatalarını konsola aktar
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Hata: ${details.exception}');
  };

  // Depolama servisini başlat
  try {
    await DepolamaServisi.init();
  } catch (e) {
    debugPrint('Depolama servisi hatası: $e');
  }

  runApp(const AresUygulamasi());
}

class AresUygulamasi extends StatelessWidget {
  const AresUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ares',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF2196F3),
      ),
      home: const GirisEkrani(),
    );
  }
}
