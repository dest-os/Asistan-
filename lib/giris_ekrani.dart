import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sohbet_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  String? _secilenKarakter;
  final TextEditingController _kullaniciAdiController = TextEditingController();

  bool get _formGecerli {
    return _secilenKarakter != null && _kullaniciAdiController.text.trim().isNotEmpty;
  }

  Future<void> _devamEt() async {
    if (!_formGecerli) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secilen_karakter', _secilenKarakter!);
    await prefs.setString('kullanici_adi', _kullaniciAdiController.text.trim());

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SohbetEkrani()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka Plan Görseli
          Positioned.fill(
            child: Image.asset(
              'assets/giris_ekrani.png',
              fit: BoxFit.fill,
            ),
          ),

          // Sol Karakter (KADIN) Seçim Alanı
          Positioned(
            left: 0,
            top: 0,
            width: MediaQuery.of(context).size.width * 0.35,
            height: MediaQuery.of(context).size.height * 0.5,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() => _secilenKarakter = 'KADIN');
              },
              child: Container(
                decoration: BoxDecoration(
                  border: _secilenKarakter == 'KADIN'
                      ? Border.all(color: Colors.cyanAccent, width: 2)
                      : null,
                ),
              ),
            ),
          ),

          // Sağ Karakter (ERKEK) Seçim Alanı
          Positioned(
            right: 0,
            top: 0,
            width: MediaQuery.of(context).size.width * 0.35,
            height: MediaQuery.of(context).size.height * 0.5,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() => _secilenKarakter = 'ERKEK');
              },
              child: Container(
                decoration: BoxDecoration(
                  border: _secilenKarakter == 'ERKEK'
                      ? Border.all(color: Colors.cyanAccent, width: 2)
                      : null,
                ),
              ),
            ),
          ),

          // Kullanıcı Adı Giriş Kutusu
          Positioned(
            left: MediaQuery.of(context).size.width * 0.42,
            top: MediaQuery.of(context).size.height * 0.53,
            width: MediaQuery.of(context).size.width * 0.31,
            height: 40,
            child: TextField(
              controller: _kullaniciAdiController,
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold),
              cursorColor: Colors.cyanAccent,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '',
              ),
            ),
          ),

          // Alt İleri Ok Butonu (Yalnızca seçimler yapılınca aktif olur)
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Center(
              child: InkWell(
                onTap: _formGecerli ? _devamEt : null,
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    color: _formGecerli ? Colors.cyanAccent.withOpacity(0.2) : Colors.white10,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _formGecerli ? Colors.cyanAccent : Colors.white24,
                      width: 2,
                    ),
                    boxShadow: _formGecerli
                        ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 10)]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "DEVAM ET",
                        style: TextStyle(
                          color: _formGecerli ? Colors.cyanAccent : Colors.white38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: _formGecerli ? Colors.cyanAccent : Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
