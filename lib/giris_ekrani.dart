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
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    _mevcutKullaniciKontrolEt();
  }

  @override
  void dispose() {
    _isimController.dispose();
    super.dispose();
  }

  // Kayıtlı kullanıcı varsa direkt sohbet ekranına yönlendir
  Future<void> _mevcutKullaniciKontrolEt() async {
    try {
      final kayitliIsim = await DepolamaServisi.kullaniciAdiGetir();
      if (kayitliIsim != null && kayitliIsim.isNotEmpty && mounted) {
        _sohbetEkraniAc(kayitliIsim);
      }
    } catch (e) {
      debugPrint('Kullanıcı okuma hatası: $e');
    }
  }

  void _girisYap() async {
    final isim = _isimController.text.trim();
    if (isim.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen isminizi girin.')),
      );
      return;
    }

    setState(() {
      _yukleniyor = true;
    });

    try {
      await DepolamaServisi.kaydetKullaniciAdi(isim);
      if (mounted) {
        _sohbetEkraniAc(isim);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

  void _sohbetEkraniAc(String isim) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SohbetEkrani(
          kullaniciAdi: isim,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Ares Asistan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hoş geldiniz! Devam etmek için bilgilerinizi girin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _isimController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Adınız veya Takma Adınız',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2196F3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Uzmanlık Alanları',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _uzmanlikSecenekleri.map((uzmanlik) {
                    final secili = seciliUzmanliklar.contains(uzmanlik);
                    return FilterChip(
                      label: Text(uzmanlik),
                      selected: secili,
                      selectedColor: const Color(0xFF2196F3),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: secili ? Colors.white : Colors.grey,
                      ),
                      backgroundColor: Colors.grey[900],
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            seciliUzmanliklar.add(uzmanlik);
                          } else {
                            seciliUzmanliklar.remove(uzmanlik);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _yukleniyor ? null : _girisYap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _yukleniyor
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Başla',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
