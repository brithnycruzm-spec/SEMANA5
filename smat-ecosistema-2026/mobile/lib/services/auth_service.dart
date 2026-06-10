import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "http://127.0.0.1:8000/token";

  Future<bool> login(String email, String password) async {

  if (email.trim().isEmpty || password.trim().isEmpty) {
    return false;
  }

  try {

    final response = await http.post(
      Uri.parse('$baseUrl/token'),

      headers: {
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),

    ).timeout(const Duration(seconds: 10));

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      final token = data['access_token'];

      if (token == null || token.toString().isEmpty) {
        return false;
      }

      await saveToken(token.toString());

      return true;
    }

    return false;

  } catch (e) {

    print('Error de login: $e');

    return false;
  }
}

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}