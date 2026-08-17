import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiBilgisiServisi {
  final String _apiUrl = 'https://api.example.com'; // API URL'nizi buraya girin
  final String _apiKey = 'your_api_key'; // API anahtarınızı buraya girin

  Future<Map<String, dynamic>> apiBilgisiAl(String endpoint) async {
    final response = await http.get(Uri.parse('$_apiUrl/$endpoint'), headers: {
      'Authorization': 'Bearer $_apiKey',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API isteği başarısız oldu');
    }
  }

  Future<Map<String, dynamic>> apiBilgisiGonder(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$_apiUrl/$endpoint'), headers: {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    }, body: jsonEncode(data));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API isteği başarısız oldu');
    }
  }
}
