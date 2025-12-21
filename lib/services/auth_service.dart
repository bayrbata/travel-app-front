import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://localhost:2000"; // iOS эсвэл physical device
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';

  // Нэвтрэх
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Token хадгалах
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token'] ?? '');
        await prefs.setString(_userIdKey, data['user']['id'].toString());
        await prefs.setString(_usernameKey, data['user']['username'] ?? '');
        await prefs.setString(_emailKey, data['user']['email'] ?? '');
        return {'success': true, 'user': data['user']};
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Нэвтрэхэд алдаа гарлаа'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Алдаа: $e'};
    }
  }

  // Бүртгүүлэх
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        // Token хадгалах
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token'] ?? '');
        await prefs.setString(_userIdKey, data['user']['id'].toString());
        await prefs.setString(_usernameKey, data['user']['username'] ?? '');
        await prefs.setString(_emailKey, data['user']['email'] ?? '');
        return {'success': true, 'user': data['user']};
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Бүртгүүлэхэд алдаа гарлаа'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Алдаа: $e'};
    }
  }

  // Гарах
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
  }

  // Нэвтэрсэн эсэхийг шалгах
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Token авах
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Хэрэглэгчийн мэдээлэл авах
  Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_userIdKey),
      'username': prefs.getString(_usernameKey),
      'email': prefs.getString(_emailKey),
    };
  }

  // Профайлын мэдээлэл авах
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'Нэвтэрээгүй байна'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'user': data};
      } else {
        return {'success': false, 'error': 'Профайл авахад алдаа гарлаа'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Алдаа: $e'};
    }
  }
}

