import 'package:flutter/material.dart';
import 'giris_ekrani.dart';
import 'sohbet_ekrani.dart';
import 'depolama_servisi.dart';

void main() async {
  // Flutter bağlayıcılarını başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Çökme hatalarını ekrana basmak için Flutter hata yakalayıcı
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Hata: ${details.exception}');
  };

  // Depolama servisini güvenli bir şekilde başlat
  try {
    await DepolamaServisi.init();
  } catch (e) {
    debugPrint('Depolama servisi başlatılamadı: $e');
  }

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
      // Hata durumunda uygulamanın kilitlenmesini önleyen güvenli ekran yapısı
      builder: (context, widget) {
        Widget errorWidget = const Scaffold(
          body: Center(
            child: Text(
              'Uygulama yüklenirken bir sorun oluştu.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        if (widget is Scaffold || widget is Navigator) {
          errorWidget = widget;
        }
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Hata Oluştu:\n${errorDetails.exception}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        };
        return widget ?? errorWidget;
      },
      home: const GirisEkrani(),
    );
  }
}
