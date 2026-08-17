import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DepolamaServisi {
  final _storage = FlutterSecureStorage();
  final _prefs = SharedPreferences.getInstance();

  Future<void> oturumAyarla(String kullaniciAdi, String sifre) async {
    await _storage.write(key: 'oturum', value: jsonEncode({'kullaniciAdi': kullaniciAdi, 'sifre': sifre}));
  }

  Future<Map<String, dynamic>?> oturumBilgisiAl() async {
    final json = await _storage.read(key: 'oturum');
    if (json != null) {
      return jsonDecode(json);
    } else {
      return null;
    }
  }

  Future<void> ayarlarKaydet(String ayarlar) async {
    await _prefs.then((prefs) => prefs.setString('ayarlar', ayarlar));
  }

  Future<String?> ayarlarAl() async {
    return _prefs.then((prefs) => prefs.getString('ayarlar'));
  }

  Future<void> kameraAlgila(bool algila) async {
    await _prefs.then((prefs) => prefs.setBool('kameraAlgila', algila));
  }

  Future<bool?> kameraAlgilaDurum() async {
    return _prefs.then((prefs) => prefs.getBool('kameraAlgila'));
  }

  Future<void> sesDegistir(String ses) async {
    await _prefs.then((prefs) => prefs.setString('ses', ses));
  }

  Future<String?> sesAl() async {
    return _prefs.then((prefs) => prefs.getString('ses'));
  }

  Future<void> akilliEgitimKaydet(String egitim) async {
    await _prefs.then((prefs) => prefs.setString('akilliEgitim', egitim));
  }

  Future<String?> akilliEgitimAl() async {
    return _prefs.then((prefs) => prefs.getString('akilliEgitim'));
  }

  Future<void> butonMenuKaydet(String menu) async {
    await _prefs.then((prefs) => prefs.setString('butonMenu', menu));
  }

  Future<String?> butonMenuAl() async {
    return _prefs.then((prefs) => prefs.getString('butonMenu'));
  }

  Future<void> jarvisSesliUyandırmaKaydet(bool uyandırma) async {
    await _prefs.then((prefs) => prefs.setBool('jarvisSesliUyandırma', uyandırma));
  }

  Future<bool?> jarvisSesliUyandırmaDurum() async {
    return _prefs.then((prefs) => prefs.getBool('jarvisSesliUyandırma'));
  }
}
