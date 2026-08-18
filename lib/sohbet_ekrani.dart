import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'api_bilgisi.dart';
import 'api_bilgisi_servisi.dart';
import 'depolama_servisi.dart';

class SohbetEkrani extends StatefulWidget {
  final String kullaniciAdi;

  const SohbetEkrani({super.key, this.kullaniciAdi = 'Kullanıcı'});

  @override
  State<SohbetEkrani> createState() => _SohbetEkraniState();
}

class _SohbetEkraniState extends State<SohbetEkrani> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ApiBilgisiServisi _apiBilgisiServisi = ApiBilgisiServisi();
  String _konustuguMetin = '';

  Future<void> _apiyeGonder() async {
    ApiBilgisi? api = await DepolamaServisi.apiBilgisiGetir();
    if (api != null && api.apiAdresi.isNotEmpty) {
      final sonuc = await _apiBilgisiServisi.apiBilgisiGonder(api.apiAdresi, {
        'metin': _konustuguMetin,
      });
      if (sonuc != null) {
        setState(() {
          _konustuguMetin = sonuc['cevap'] ?? '';
        });
      }
    }
  }

  Future<void> _paylas() async {
    final dosyaYolu = await _screenshotController.capture();
    if (dosyaYolu != null) {
      await Share.shareXFiles([XFile(dosyaYolu.path)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Screenshot(
        controller: _screenshotController,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Merhaba ${widget.kullaniciAdi}, senin icin ne yapabilirim?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Text(
                    _konustuguMetin.isEmpty
                        ? 'Dinliyorum...'
                        : _konustuguMetin,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _apiyeGonder,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.green),
                    onPressed: _paylas,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
