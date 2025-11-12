import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:newsapp/models/news_model.dart';

class ApiService {
  // 🔥 Хэрэв Flutter апп нь эмулятор дээр ажиллаж байгаа бол:
  // Android → 10.0.2.2
  // iOS → localhost
  static const String baseUrl = "http://localhost:2000";

  // --- GET: Мэдээ татах ---
  Future<List<News>> fetchNews() async {
    final response = await http.get(Uri.parse('$baseUrl/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((news) => News.fromJson(news)).toList();
    } else {
      throw Exception('Мэдээ татахад алдаа гарлаа');
    }
  }

  // --- POST: Мэдээ нэмэх ---
  Future<void> postNews(int id, String type, String imageBase64) async {
    final response = await http.post(
      Uri.parse('$baseUrl/postNews'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'type': type, 'imageBase64': imageBase64}),
    );

    if (response.statusCode != 200) {
      throw Exception('Мэдээ нэмэхэд алдаа гарлаа');
    }
  }
}
