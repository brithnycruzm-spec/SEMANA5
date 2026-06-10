import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estacion.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000/token";

  // ── Estaciones ──────────────────────────────────────────

  Future<List<Estacion>> fetchEstaciones() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estaciones/'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Estacion.fromJson(data)).toList();
      }
      throw Exception('Error ${response.statusCode} al obtener estaciones');
    } catch (e) {
      throw Exception('No se pudo conectar con SMAT. ¿Está el servidor activo?');
    }
  }

  Future<bool> crearEstacion(String nombre, String ubicacion) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/estaciones/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nombre': nombre, 'ubicacion': ubicacion}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al crear estación: $e');
      return false;
    }
  }

  Future<bool> eliminarEstacion(int id) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/estaciones/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error al eliminar estación: $e');
      return false;
    }
  }

  Future<bool> editarEstacion(int id, String nombre, String ubicacion) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/estaciones/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nombre': nombre, 'ubicacion': ubicacion}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error al editar estación: $e');
      return false;
    }
  }
}