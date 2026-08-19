import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SohbetEkrani extends StatefulWidget {
  const SohbetEkrani({super.key});

  @override
  State<SohbetEkrani> createState() => _SohbetEkraniState();
}

class _SohbetEkraniState extends State<SohbetEkrani> {
  String _bgImage = '';
  bool _yuklendi = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    String secim = prefs.getString('secilen_karakter') ?? 'KADIN';

    setState(() {
      _bgImage = (secim == 'KADIN')
          ? 'assets/kadin_ares_ekrani.png'
          : 'assets/erkek_ares ekrani.png';
      _yuklendi = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _bgImage,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Herhangi bir şey sor...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
