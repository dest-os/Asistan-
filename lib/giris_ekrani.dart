import 'package:flutter/material.dart';
import 'sohbet_ekrani.dart';
import 'depolama_servisi.dart';
import 'api_bilgisi.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _isimController = TextEditingController();
  final List<String> _uzmanlikSecenekleri = [
    'Yazılım',
    'Tasarım',
    'Pazarlama',
    'Finans',
    'Genel Asistan'
  ];
  List<String> seciliUzmanliklar = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ares Asistan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _isimController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'İsminiz',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2196F3)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Uzmanlik Alani (birden fazla secilebilir):',
                  style: TextStyle(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _uzmanlikSecenekleri.map((alan) {
                  final seciliMi = seciliUzmanliklar.contains(alan);
                  return FilterChip(
                    label: Text(alan),
                    selected: seciliMi,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          seciliUzmanliklar.add(alan);
                        } else {
                          seciliUzmanliklar.remove(alan);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_isimController.text.trim().isNotEmpty) {
                    await DepolamaServisi.kaydetKullaniciAdi(
                      _isimController.text.trim(),
                    );
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SohbetEkrani(),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
