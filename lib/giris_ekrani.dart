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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              // ÜST KISIM (Karakterler ve Logo)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // KADIN SEÇENEĞİ
                    GestureDetector(
                      onTap: () => setState(() => _secilenKarakter = 'KADIN'),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            width: 220,
                            height: 90,
                            margin: const EdgeInsets.only(left: 45),
                            padding: const EdgeInsets.only(left: 55, right: 12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _secilenKarakter == 'KADIN' ? const Color(0xFF00E5FF) : Colors.white24,
                                width: _secilenKarakter == 'KADIN' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ARES', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text('KADIN', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
                                  ],
                                ),
                                Icon(
                                  _secilenKarakter == 'KADIN' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: const Color(0xFF00E5FF),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                              image: const DecorationImage(
                                image: AssetImage('assets/kadin_ares.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ORTA LOGO
                    Image.asset(
                      'assets/logo.png',
                      height: 110,
                      fit: BoxFit.contain,
                    ),

                    // ERKEK SEÇENEĞİ
                    GestureDetector(
                      onTap: () => setState(() => _secilenKarakter = 'ERKEK'),
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Container(
                            width: 220,
                            height: 90,
                            margin: const EdgeInsets.only(right: 45),
                            padding: const EdgeInsets.only(right: 55, left: 12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _secilenKarakter == 'ERKEK' ? const Color(0xFF00E5FF) : Colors.white24,
                                width: _secilenKarakter == 'ERKEK' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  _secilenKarakter == 'ERKEK' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: const Color(0xFF00E5FF),
                                  size: 20,
                                ),
                                const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('ARES', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text('ERKEK', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                              image: const DecorationImage(
                                image: AssetImage('assets/erkek_ares.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ALT KISIM (Kullanıcı Adı Girdisi)
              Container(
                width: 500,
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 12),
                    const Text('KULLANICI ADI', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _kullaniciAdiController,
                        style: const TextStyle(color: Colors.white),
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
