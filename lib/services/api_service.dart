import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travelapp/models/travel_model.dart';

class ApiService {
  // Android эмулятор дээр: 10.0.2.2 ашиглана
  // iOS эмулятор эсвэл physical device дээр: localhost эсвэл IP хаяг ашиглана
  static const String baseUrl = "http://10.0.2.2:2000"; // Android эмулятор
  // static const String baseUrl = "http://localhost:2000"; // iOS эсвэл physical device

  // --- GET: Бүх аяллын зургуудыг авах (эрэмбэлэх, хайлттай) ---
  Future<List<Travel>> fetchTravels({
    String? sortBy,
    String? order,
    String? search,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl/api/travels');
      Map<String, String> queryParams = {};
      
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (order != null) queryParams['order'] = order;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((travel) => Travel.fromJson(travel)).toList();
      } else {
        throw Exception('Аяллын зургуудыг татахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Алдаа: $e');
    }
  }

  // --- GET: ID-аар нэг аяллын зураг авах ---
  Future<Travel> fetchTravelById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/travels/$id'));
      
      if (response.statusCode == 200) {
        return Travel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Аяллын зураг олдсонгүй');
      } else {
        throw Exception('Аяллын зураг татахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Алдаа: $e');
    }
  }

  // --- POST: Шинэ аяллын зураг нэмэх ---
  Future<Travel> createTravel({
    required String title,
    String? description,
    required String location,
    String? country,
    String? city,
    String? imageBase64,
    String? travelDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/travels'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'location': location,
          'country': country,
          'city': city,
          'imageBase64': imageBase64,
          'travelDate': travelDate,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return Travel.fromJson(responseData['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Аяллын зураг нэмэхэд алдаа гарлаа');
      }
    } catch (e) {
      throw Exception('Алдаа: $e');
    }
  }

  // --- PUT: Аяллын зургийг засах ---
  Future<Travel> updateTravel({
    required int id,
    String? title,
    String? description,
    String? location,
    String? country,
    String? city,
    String? imageBase64,
    String? travelDate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/travels/$id'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'location': location,
          'country': country,
          'city': city,
          'imageBase64': imageBase64,
          'travelDate': travelDate,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Travel.fromJson(responseData['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Аяллын зураг олдсонгүй');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Аяллын зураг засахад алдаа гарлаа');
      }
    } catch (e) {
      throw Exception('Алдаа: $e');
    }
  }

  // --- DELETE: Аяллын зургийг устгах ---
  Future<void> deleteTravel(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/travels/$id'));

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Аяллын зураг олдсонгүй');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Аяллын зураг устгахад алдаа гарлаа');
      }
    } catch (e) {
      throw Exception('Алдаа: $e');
    }
  }

  // --- GET: Тэмдэгтээр хайх ---
  Future<List<Travel>> searchTravels(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/travels/search/$keyword'),
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((travel) => Travel.fromJson(travel)).toList();
      } else {
        throw Exception('Хайлтын алдаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Алдаа: $e');
    }
  }
}
