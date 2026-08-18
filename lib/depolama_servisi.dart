import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_bilgisi.dart';

class DepolamaServisi {
  static final _storage = const FlutterSecureStorage();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> kaydetKullaniciAdi(String kullaniciAdi) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString('kullaniciAdi', kullaniciAdi);
  }

  static Future<String?> kullaniciAdiGetir() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString('kullaniciAdi');
  }

  static Future<ApiBilgisi?> apiBilgisiGetir() async {
    _prefs ??= await SharedPreferences.getInstance();
    final url = _prefs?.getString('apiAdresi') ?? '';
    final id = _prefs?.getString('apiId') ?? 'default_id';
    return ApiBilgisi(id: id, apiAdresi: url);
  }

  Future<void> oturumAyarla(String kullaniciAdi, String sifre) async {
    await _storage.write(
      key: 'oturum',
      value: jsonEncode({'kullaniciAdi': kullaniciAdi, 'sifre': sifre}),
    );
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
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString('ayarlar', ayarlar);
  }

  Future<String?> ayarlarAl() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString('ayarlar');
  }

  Future<void> kameraAlgila(bool algila) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool('kameraAlgila', algila);
  }

  Future<bool?> kameraAlgilaDurum() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getBool('kameraAlgila');
  }

  Future<void> sesDegistir(String ses) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString('ses', ses);
  }

  Future<String?> sesAl() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString('ses');
  }

  Future<void> akilliEgitimKaydet(String egitim) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString('akilliEgitim', egitim);
  }

  Future<String?> akilliEgitimAl() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString('akilliEgitim');
  }

  Future<void> butonMenuKaydet(String menu) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString('butonMenu', menu);
  }

  Future<String?> butonMenuAl() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString('butonMenu');
  }

  Future<void> jarvisSesliUyandirmaKaydet(bool uyandirma) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool('jarvisSesliUyandirma', uyandirma);
  }

  Future<bool?> jarvisSesliUyandirmaDurum() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getBool('jarvisSesliUyandirma');
  }
}
