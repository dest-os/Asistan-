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
  String _secilenKarakter = 'KADIN'; // Varsayılan seçim

  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    super.dispose();
  }

  // Kullanıcı tercihlerini telefon hafızasına kaydetme fonksiyonu
  Future<void> _kaydetVeDevamEt() async {
    final kullaniciAdi = _kullaniciAdiController.text.trim();

    if (kullaniciAdi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen ARES\'in size nasıl sesleneceğini yazın.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kullanici_adi', kullaniciAdi);
    await prefs.setString('secilen_karakter', _secilenKarakter);
    await prefs.setBool('giris_yapildi', true);

    if (!mounted) return;

    // Kayıt tamamlandıktan sonra doğrudan 2. ekrana (Sohbet Ekrana) geçiş
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SohbetEkrani()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Üst Kısım: Karakter Seçimleri ve Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ARES KADIN Seçim Alanı
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _secilenKarakter = 'KADIN';
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _secilenKarakter == 'KADIN'
                                  ? const Color(0xFF00E5FF)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage('assets/images/ares_kadın.png'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _secilenKarakter == 'KADIN'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: const Color(0xFF00E5FF),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'ARES KADIN',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Orta Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.remove_red_eye,
                      color: Color(0xFF00E5FF),
                      size: 60,
                    ),
                  ),

                  // ARES ERKEK Seçim Alanı
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _secilenKarakter = 'ERKEK';
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _secilenKarakter == 'ERKEK'
                                  ? const Color(0xFF00E5FF)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage('assets/images/ares_erkek.png'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _secilenKarakter == 'ERKEK'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: const Color(0xFF00E5FF),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'ARES ERKEK',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Kullanıcı Adı Giriş Alanı (Görselinizdeki Tasarıma Sadık)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00E5FF),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _kullaniciAdiController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person, color: Color(0xFF00E5FF)),
                    hintText: 'KULLANICI ADI',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Devam Et / Başla Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _kaydetVeDevamEt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'BAŞLAT',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
