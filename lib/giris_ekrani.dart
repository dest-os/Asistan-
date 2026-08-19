import 'package:flutter/material.dart';

class GirisEkrani extends StatelessWidget {
  const GirisEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red, // <--- Sadece bu satırı ekledim
      body: const Center(child: Text("Test Başarılı", style: TextStyle(color: Colors.white, fontSize: 30))),
    );
  }
}
