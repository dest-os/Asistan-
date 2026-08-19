import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sohbet_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _kullaniciAdiController = TextEditingController();
  String _secilenKarakter = 'KADIN';

  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    super.dispose();
  }

  Future<void> _kaydetVeDevamEt() async {
    final kullaniciAdi = _kullaniciAdiController.text.trim();

    if (kullaniciAdi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir kullanıcı adı girin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kullanici_adi', kullaniciAdi);
    await prefs.setString('secilen_karakter', _secilenKarakter);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SohbetEkrani()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              // ÜST KISIM: Kartlar ve Logo
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // KADIN BUTONU (Orijinal Görsel)
                    GestureDetector(
                      onTap: () => setState(() => _secilenKarakter = 'KADIN'),
                      child: Opacity(
                        opacity: _secilenKarakter == 'KADIN' ? 1.0 : 0.5,
                        child: Image.asset(
                          'assets/kadin_ares.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    // ORTA LOGO
                    Image.asset(
                      'assets/logo.png',
                      height: 130,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(width: 15),

                    // ERKEK BUTONU (Orijinal Görsel)
                    GestureDetector(
                      onTap: () => setState(() => _secilenKarakter = 'ERKEK'),
                      child: Opacity(
                        opacity: _secilenKarakter == 'ERKEK' ? 1.0 : 0.5,
                        child: Image.asset(
                          'assets/erkek_ares.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ALT KISIM: Kullanıcı Adı Giriş Kutusu
              Container(
                width: 480,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF00E5FF), size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'KULLANICI ADI',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _kullaniciAdiController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _kaydetVeDevamEt(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
