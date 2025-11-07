import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FincaService {
  static const String _baseUrl = "http://100.99.89.55:5000"; // URL del backend
  static const String _tokenKey = "jwt_token"; // Clave del token guardado

  // ==========================================================
  // 🔒 OBTENER TOKEN
  // ==========================================================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }


  // ==========================================================
  // 🌱 CREAR FINCA
  // ==========================================================
  Future<Map<String, dynamic>> createFinca(
      Map<String, String> data, [
        File? imagen,
      ]) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/geo-admin/fincas');

    try {
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token';

      data.forEach((key, value) => request.fields[key] = value);

      if (imagen != null) {
        final fileStream = http.ByteStream(imagen.openRead());
        final length = await imagen.length();
        final multipartFile = http.MultipartFile(
          'imagen',
          fileStream,
          length,
          filename: imagen.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final response = await http.Response.fromStream(await request.send());
      final dataRes = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': dataRes};
      } else {
        return {'success': false, 'message': dataRes['mensaje'] ?? 'Error al crear la finca'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // 📋 LISTAR FINCAS
  // ==========================================================
  Future<List<dynamic>> getAllFincas() async {
    final url = Uri.parse('$_baseUrl/geo-admin/fincas');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ==========================================================
  // 🔍 OBTENER DETALLES DE UNA FINCA
  // ==========================================================
  Future<Map<String, dynamic>> getFincaDetails(int idFinca) async {
    final url = Uri.parse('$_baseUrl/geo-admin/fincas/$idFinca');
    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['mensaje'] ?? 'Error al obtener detalles'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // ✏️ ACTUALIZAR FINCA
  // ==========================================================
  Future<Map<String, dynamic>> updateFinca(
      int idFinca,
      Map<String, String> data, [
        File? imagen,
      ]) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/geo-admin/fincas/$idFinca');

    try {
      final request = http.MultipartRequest('PUT', url)
        ..headers['Authorization'] = 'Bearer $token';

      data.forEach((key, value) => request.fields[key] = value);

      if (imagen != null) {
        final fileStream = http.ByteStream(imagen.openRead());
        final length = await imagen.length();
        final multipartFile = http.MultipartFile(
          'imagen',
          fileStream,
          length,
          filename: imagen.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final response = await http.Response.fromStream(await request.send());
      final dataRes = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': dataRes};
      } else {
        return {'success': false, 'message': dataRes['mensaje'] ?? 'Error al actualizar finca'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // 🔄 CAMBIAR ESTADO (ACTIVAR / DESACTIVAR)
  // ==========================================================
  Future<Map<String, dynamic>> toggleFincaStatus(int idFinca, bool isActive) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/geo-admin/fincas/$idFinca/estado');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'is_active': isActive}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Error al cambiar el estado de la finca'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // 🖼️ OBTENER URL DE IMAGEN
  // ==========================================================
  String getImageUrl(String relativePath) {
    return '$_baseUrl/geo-admin/uploads/$relativePath';
  }
}
