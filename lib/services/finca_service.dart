import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FincaService {
  static const String _baseUrl = "http://100.64.64.95:5000"; // URL del backend
  static const String _tokenKey = "jwt_token"; // Clave del token guardado

  // Constante para la ruta base de fincas
  static const String _fincaBaseRoute = "/geo-admin/fincas";

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
    final url = Uri.parse('$_baseUrl$_fincaBaseRoute');

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
  // 📦 NUEVO: LISTAR FINCAS POR ESTADO (Habilitadas o Inhabilitadas)
  // ==========================================================
  Future<List<dynamic>> getFincasByStatus({required bool isActive}) async {
    final token = await _getToken();
    
    // Determinar el sufijo de la ruta: /habilitadas o /inhabilitadas
    final String statusSuffix = isActive ? '/habilitadas' : '/inhabilitadas';
    
    // Construir la URL completa: /geo-admin/fincas/habilitadas o /inhabilitadas
    final url = Uri.parse('$_baseUrl$_fincaBaseRoute$statusSuffix'); 

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        // En caso de error, devolvemos una lista vacía.
        print("Error fetching fincas by status (Status: ${response.statusCode}): ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error de conexión al obtener fincas por estado: $e");
      return [];
    }
  }


  // ==========================================================
  // 📋 LISTAR FINCAS (TODAS - Mantenido por compatibilidad)
  // ==========================================================
  Future<List<dynamic>> getAllFincas() async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl$_fincaBaseRoute'); // Usa la ruta base sin sufijo (lista todas)
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
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
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl$_fincaBaseRoute/$idFinca');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
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
    final url = Uri.parse('$_baseUrl$_fincaBaseRoute/$idFinca');

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
    final url = Uri.parse('$_baseUrl$_fincaBaseRoute/$idFinca/estado');

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
  // 🧑‍🌾 LISTAR TODOS LOS AGRÓNOMOS
  // ==========================================================
  Future<List<dynamic>> getAllAgronomos() async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/geo-admin/usuarios/agronomos');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['agronomos'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ==========================================================
  // 🔍 BUSCAR AGRÓNOMO POR CÉDULA O NOMBRE
  // ==========================================================
  Future<Map<String, dynamic>> searchAgronomo({String? cedula, String? nombre}) async {
    final token = await _getToken();
    final queryParams = <String, String>{};
    if (cedula != null && cedula.isNotEmpty) queryParams['cedula'] = cedula;
    if (nombre != null && nombre.isNotEmpty) queryParams['nombre'] = nombre;

    final url = Uri.parse('$_baseUrl/geo-admin/usuarios/agronomos/search')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['mensaje'] ?? 'Agrónomo no encontrado'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // 🖼️ OBTENER URL DE IMAGEN
  // ==========================================================
  String getImageUrl(String relativeOrCompleteUrl) {
    // Si Flask ya devolvió una URL completa (http://...) en el campo 'url_imagen',
    // simplemente la devolvemos sin modificar.
    if (relativeOrCompleteUrl.startsWith('http://') || relativeOrCompleteUrl.startsWith('https://')) {
        return relativeOrCompleteUrl;
    }
    
    // Si solo devolvió la ruta relativa (ej: 'fincas/1/main.jpg'), construimos la URL completa.
    final cleanPath = relativeOrCompleteUrl.startsWith('/') 
        ? relativeOrCompleteUrl.substring(1) 
        : relativeOrCompleteUrl;
        
    // La URL de acceso debería ser:
    return '$_baseUrl/uploads/$cleanPath';
  }
}