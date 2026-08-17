// Bu dosya, kullanicinin kaydettigi her bir yapay zeka API'sinin
// bilgilerini tasiyan veri kalibidir (model).

class ApiBilgisi {
  final String id;
  final String firmaAdi;
  final String apiAdresi;
  final String apiAnahtari;
  final List<String> uzmanlikAlanlari;
  // Ornek: ["Metin", "Resim", "Kod"]
  bool gunlukLimitDoldu;
  // Kota uyarisi icin

  ApiBilgisi({
    required this.id,
    required this.firmaAdi,
    required this.apiAdresi,
    required this.apiAnahtari,
    required this.uzmanlikAlanlari,
    this.gunlukLimitDoldu = false,
  });

  // Kayit icin veriyi JSON (metin) haline cevirir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firmaAdi': firmaAdi,
      'apiAdresi': apiAdresi,
      'apiAnahtari': apiAnahtari,
      'uzmanlikAlanlari': uzmanlikAlanlari,
      'gunlukLimitDoldu': gunlukLimitDoldu,
    };
  }

  // Kayitli JSON metnini tekrar kullanilabilir hale getirir
  factory ApiBilgisi.fromJson(Map<String, dynamic> json) {
    return ApiBilgisi(
      id: json['id'] as String,
      firmaAdi: json['firmaAdi'] as String,
      apiAdresi: json['apiAdresi'] as String,
      apiAnahtari: json['apiAnahtari'] as String,
      uzmanlikAlanlari: List<String>.from(json['uzmanlikAlanlari'] as List),
      gunlukLimitDoldu: json['gunlukLimitDoldu'] as bool? ?? false,
    );
  }

  // Firma adina bakarak hangi konusma formatini kullanacagini tahmin eder.
  // Boylece kullanicidan ekstra bir "format" alani istemeye gerek kalmaz.
  String formatTuruBul() {
    final ad = firmaAdi.toLowerCase();
    if (ad.contains('google') || ad.contains('gemini')) {
      return 'gemini';
    } else if (ad.contains('anthropic') || ad.contains('claude')) {
      return 'anthropic';
    } else {
      // OpenAI, Mistral, Groq, DeepSeek gibi cogu servis bu ortak
      // formata uyumludur, bilinmeyen firmalarda varsayilan budur.
      return 'openai_uyumlu';
    }
  }
}
