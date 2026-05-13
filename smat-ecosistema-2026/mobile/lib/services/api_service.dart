import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estacion.dart';
import 'auth_service.dart'; 
class ApiService {
// 10.0.2.2 es el alias del localhost de la PC para emuladores Android
  final String baseUrl = "http://127.0.0.1:8000";

Future<List<Estacion>> fetchEstaciones() async {
  try{
  final response = await http.get(Uri.parse('$baseUrl/estaciones/'));
  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => Estacion.fromJson(data)).toList();
  } else {
    throw Exception('Error al conectar con el servidor SMAT');
    }
  }catch(e){
    throw Exception("No se pudo conectar con SMAT.¿Está el servidor activo?");
  }
  }
  //Crear estación
Future<bool> crearEstacion(String nombre, String ubicacion) async {
  try {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/estaciones'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'nombre': nombre, 'ubicacion': ubicacion}),
    );
    return response.statusCode == 201 || response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
  // Eliminar una estación
Future<bool> eliminarEstacion(int id) async {
  try {
    final token = await AuthService().getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/estaciones/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    
    // El servidor puede responder 200 o 204 si el borrado fue exitoso
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    print("Error al eliminar: $e");
    return false;
  }
}

// Actualizar una estación existente
Future<bool> editarEstacion(int id, String nombre, String ubicacion) async {
  try {
    final token = await AuthService().getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/estaciones/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre': nombre, 
        'ubicacion': ubicacion
      }),
    );
    
    return response.statusCode == 200;
  } catch (e) {
    print("Error al editar: $e");
    return false;
  }
}
}