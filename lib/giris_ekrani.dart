import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sohbet_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  String _secilenKarakter = 'ERKEK'; // Varsayılan Erkek Ares
  final TextEditingController _kullaniciAdiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kullaniciAdiController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    super.dispose();
  }

  bool get _formGecerli {
    return _secilenKarakter.isNotEmpty && _kullaniciAdiController.text.trim().isNotEmpty;
  }

  Future<void> _devamEt() async {
    if (!_formGecerli) return;

    PermissionStatus status = await Permission.microphone.request();

    if (status.isGranted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('secilen_karakter', _secilenKarakter);
      await prefs.setString('kullanici_adi', _kullaniciAdiController.text.trim());

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SohbetEkrani()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Ares'in sizi duyabilmesi için mikrofon izni gereklidir.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9, // Hem telefon hem tablette tam oran koruma
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              return Stack(
                children: [
                  // 1. ARKA PLAN GÖRSELİ
                  Positioned.fill(
                    child: Image.asset(
                      'assets/giris_ekrani.png',
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => Container(color: Colors.black),
                    ),
                  ),

                  // 2. SOL KARAKTER SEÇİM ALANI (KADIN ARES PARLAYAN ÇERÇEVE)
                  Positioned(
                    left: w * 0.145,
                    top: h * 0.140,
                    width: w * 0.245,
                    height: h * 0.335,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() => _secilenKarakter = 'KADIN');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: _secilenKarakter == 'KADIN'
                              ? Border.all(color: Colors.cyanAccent, width: 2.5)
                              : Border.all(color: Colors.transparent, width: 2.5),
                          boxShadow: _secilenKarakter == 'KADIN'
                              ? [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ),

                  // 3. SAĞ KARAKTER SEÇİM ALANI (ERKEK ARES PARLAYAN ÇERÇEVE)
                  Positioned(
                    right: w * 0.145,
                    top: h * 0.140,
                    width: w * 0.245,
                    height: h * 0.335,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() => _secilenKarakter = 'ERKEK');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: _secilenKarakter == 'ERKEK'
                              ? Border.all(color: Colors.cyanAccent, width: 2.5)
                              : Border.all(color: Colors.transparent, width: 2.5),
                          boxShadow: _secilenKarakter == 'ERKEK'
                              ? [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ),

                  // 4. KULLANICI ADI GİRİŞ KUTUSU
                  Positioned(
                    left: w * 0.450,
                    top: h * 0.560,
                    width: w * 0.280,
                    height: h * 0.090,
                    child: Center(
                      child: TextField(
                        controller: _kullaniciAdiController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        cursorColor: Colors.cyanAccent,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Adınızı yazın...',
                          hintStyle: TextStyle(
                            color: Colors.white30,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onSubmitted: (_) {
                          if (_formGecerli) _devamEt();
                        },
                      ),
                    ),
                  ),

                  // 5. DEVAM ET BUTONU
                  Positioned(
                    bottom: h * 0.105,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _formGecerli ? _devamEt : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                          decoration: BoxDecoration(
                            color: _formGecerli ? const Color(0xFF041C32) : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _formGecerli ? Colors.cyanAccent : Colors.white12,
                              width: 1.8,
                            ),
                            boxShadow: _formGecerli
                                ? [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.4),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "ARES SİSTEMİNİ BAŞLAT",
                                style: TextStyle(
                                  color: _formGecerli ? Colors.cyanAccent : Colors.white24,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: _formGecerli ? Colors.cyanAccent : Colors.white24,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
