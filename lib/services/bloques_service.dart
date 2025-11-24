// lib/services/bloques_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer'; // Importar para logging más robusto

class BloquesService {
  // Asegúrate de usar la URL base correcta de tu backend
  static const String _baseUrl = "http://100.64.64.95:5000"; 
  static const String _tokenKey = "jwt_token"; 

  // La ruta base para la gestión de Bloques
  static const String _bloquesBaseRoute = "/bloques/"; 
  // La ruta base para la gestión de Áreas (necesario para el Dropdown en la creación)
  static const String _areasBaseRoute = "/areas"; 


  // ==========================================================
  // 🔒 OBTENER TOKEN
  // ==========================================================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ==========================================================
  // 🗺️ OBTENER TODAS LAS ÁREAS ACTIVAS (Necesario para el dropdown en la creación de Bloques)
  // ==========================================================
  Future<List<dynamic>> getAllAreas() async {
    final token = await _getToken();
    if (token == null) {
      log('Token no encontrado para getAllAreas.');
      return [];
    }
    // 🟢 AJUSTE CLAVE: Añadir query parameter 'is_active=true' para filtrar por áreas habilitadas
    Uri url = Uri.parse('$_baseUrl$_areasBaseRoute'); 
    url = url.replace(queryParameters: {'is_active': 'true'}); // Aplicación del filtro

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Asume que la API devuelve una lista directa de áreas
        if (data is List) {
          return data;
        } 
        // Si devuelve un objeto con una clave 'areas' o similar
        return data['areas'] ?? [];
      } else {
        log('Error al obtener áreas: ${response.statusCode} - ${data['mensaje'] ?? response.body}');
        return [];
      }
    } catch (e) {
      log('Error de conexión en getAllAreas: $e');
      return [];
    }
  }


  // ==========================================================
  // 📦 CREAR BLOQUE (POST /bloques)
  // Cuerpo requerido: { "idArea": 1, "numeroBloque": "10A", "is_active": true }
  // ==========================================================
  Future<Map<String, dynamic>> createBloque(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token de autenticación no encontrado'};
    }
    
    final url = Uri.parse('$_baseUrl$_bloquesBaseRoute');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      
      final dynamic dataRes = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Asumo que el backend devuelve {'bloque': {...}, 'mensaje': '...'}
        return {'success': true, 'data': dataRes['bloque'], 'message': dataRes['mensaje']};
      } else {
        // Asume que el backend devuelve un mensaje de error en 'mensaje' para 4xx/5xx
        final errorMessage = dataRes['mensaje'] ?? 'Error desconocido (${response.statusCode}) al crear el bloque';
        log('Error al crear bloque: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      log('Error de conexión en createBloque: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // 📋 LISTAR TODOS LOS BLOQUES (Soporta filtrado por idArea y estado)
  // ==========================================================
  // 💡 AJUSTE: Añadir 'isActive' con valor por defecto 'true'
  Future<List<dynamic>> getAllBloques({int? idArea, bool isActive = true}) async {
    final token = await _getToken();
    if (token == null) {
      log('Token no encontrado para getAllBloques.');
      return [];
    }
    
    // 🎯 MODIFICACIÓN CLAVE: Construir la ruta base según el estado
    // Si isActive es true -> /bloques/ (Lista Activos)
    // Si isActive es false -> /bloques/inactivos (Lista Inactivos)
    String route = isActive ? _bloquesBaseRoute : '${_bloquesBaseRoute}inactivos';
    Uri url = Uri.parse('$_baseUrl$route');
    
    Map<String, String> queryParams = {};

    if (idArea != null) {
      // Solo añadimos idArea como query parameter si está presente
      queryParams['idArea'] = idArea.toString();
    }

    // 💡 Si hay parámetros, los añadimos a la URL
    if (queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
    }

    log('Fetching bloques from: $url'); // Log para depuración

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // El endpoint GET /bloques/ devuelve una lista directa o envuelta en 'bloques'
        if (data is List) {
          return data; 
        } else {
          return data['bloques'] ?? [];
        }
      } else {
        log('Error al obtener bloques: ${response.statusCode} - ${data['mensaje'] ?? response.body}');
        return [];
      }
    } catch (e) {
      log('Error de conexión en getAllBloques: $e');
      return [];
    }
  }

  // ==========================================================
  // 🔍 DETALLE DE UN BLOQUE (GET /bloques/<idBloque>)
  // 🎯 El API devuelve: { ..., "area_padre": {...}, "finca_abuelo": {...}, "estructura_descendiente": {...} }
  // ==========================================================
  Future<Map<String, dynamic>> getBloqueDetails(int idBloque) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token de autenticación no encontrado'};
    }
    final url = Uri.parse('$_baseUrl$_bloquesBaseRoute$idBloque');
    log('Fetching bloque details from: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      final dynamic data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // El detalle devuelve el objeto Bloque con la jerarquía y el conteo de descendientes
        // 🟢 AJUSTE DE RESPUESTA: Usamos 'data' directamente ya que contiene toda la estructura
        return {'success': true, 'data': data}; 
      } else {
        final errorMessage = data['mensaje'] ?? 'Error al obtener detalles (${response.statusCode})';
        log('Error al obtener detalle de bloque $idBloque: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      log('Error de conexión en getBloqueDetails: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // ✏️ ACTUALIZAR BLOQUE (PUT /bloques/<idBloque>)
  // Cuerpo requerido: { "idArea": 1, "numeroBloque": "10A", "is_active": true/false }
  // ==========================================================
  Future<Map<String, dynamic>> updateBloque(int idBloque, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token de autenticación no encontrado'};
    }

    final url = Uri.parse('$_baseUrl$_bloquesBaseRoute$idBloque');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final dynamic dataRes = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': dataRes['bloque'], 'message': dataRes['mensaje']}; 
      } else {
        final errorMessage = dataRes['mensaje'] ?? 'Error al actualizar bloque (${response.statusCode})';
        log('Error al actualizar bloque $idBloque: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      log('Error de conexión en updateBloque: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // ⚙️ HABILITAR/INHABILITAR BLOQUE (PATCH /bloques/<idBloque>/estado)
  // Cuerpo requerido: { "is_active": true/false }
  // ==========================================================
  Future<Map<String, dynamic>> toggleBloqueStatus(int idBloque, bool newStatus) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token de autenticación no encontrado'};
    }
    final url = Uri.parse('$_baseUrl$_bloquesBaseRoute$idBloque/estado');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'is_active': newStatus}),
      ); 

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['mensaje'], 'data': data['bloque']};
      } else {
        final errorMessage = data['mensaje'] ?? 'Error al cambiar el estado del bloque (${response.statusCode})';
        log('Error al cambiar estado de bloque $idBloque: $errorMessage');
        return {
          'success': false,
          'message': errorMessage
        };
      }
    } catch (e) {
      log('Error de conexión en toggleBloqueStatus: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // 🗑️ ELIMINAR BLOQUE (DELETE /bloques/<idBloque>)
  // ==========================================================
  Future<Map<String, dynamic>> deleteBloque(int idBloque) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token de autenticación no encontrado'};
    }
    final url = Uri.parse('$_baseUrl$_bloquesBaseRoute$idBloque');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['mensaje']};
      } else {
        final errorMessage = data['mensaje'] ?? 'Error al eliminar bloque (${response.statusCode})';
        log('Error al eliminar bloque $idBloque: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      log('Error de conexión en deleteBloque: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}