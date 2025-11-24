// lib/services/area_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AreaService {
  // Asegúrate de usar la URL base correcta de tu backend
  static const String _baseUrl = "http://100.64.64.95:5000"; 
  static const String _tokenKey = "jwt_token"; 

  // CORRECCIÓN: Asumo que el endpoint completo es /geo-admin/finca/areas/
  static const String _areaBaseRoute = "/areas"; 

  // ==========================================================
  // 🔒 OBTENER TOKEN
  // ==========================================================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ==========================================================
  // 📦 CREAR ÁREA (POST /geo-admin/finca/areas)
  // ==========================================================
  Future<Map<String, dynamic>> createArea(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token de autenticación no encontrado'};
    }
    
    final url = Uri.parse('$_baseUrl$_areaBaseRoute');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      
      final dataRes = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': dataRes['area'], 'message': dataRes['mensaje']};
      } else {
        // Asume que el backend devuelve un mensaje de error en 'mensaje' para 4xx/5xx
        return {'success': false, 'message': dataRes['mensaje'] ?? 'Error desconocido al crear el área'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // 📋 LISTAR TODAS LAS ÁREAS (Soporta filtrado por idFinca y Estado)
  // ==========================================================
  Future<List<dynamic>> getAllAreas({
    int? idFinca, 
    // Parámetro para filtrar por estado, por defecto true
    bool onlyActive = true, 
  }) async { 
    final token = await _getToken();
    
    // 1. Construir la URL base
    Uri url = Uri.parse('$_baseUrl$_areaBaseRoute');
    
    // 2. Definir los query parameters
    final Map<String, String> queryParams = {};

    // Agregar filtro por Finca si está presente
    if (idFinca != null) {
      queryParams['idFinca'] = idFinca.toString(); 
    }
    
    // Agregar filtro por Estado (is_active)
    queryParams['is_active'] = onlyActive.toString(); 

    // 3. Reemplazar la URL con todos los parámetros
    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }
    
    // Ejemplo de URL final: /areas?idFinca=123&is_active=true

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Lógica para manejar diferentes formatos de respuesta 200 (lista directa o {areas: []})
        if (data is List) {
          return data; 
        } else if (data is Map && data.containsKey('areas')) {
          return data['areas'] ?? [];
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  // ==========================================================
  // 📋 NUEVA FUNCIÓN: LISTAR ÁREAS POR ESTADO (Wrapper para la pantalla)
  // ==========================================================
  Future<List<dynamic>> getAreasByStatus({
    required int idFinca, 
    required bool isActive, // <-- Recibe el estado de forma obligatoria
  }) async { 
    // Reutiliza la función principal getAllAreas con el filtro de estado y finca.
    return await getAllAreas(idFinca: idFinca, onlyActive: isActive);
  }

  // ==========================================================
  // 🔍 DETALLE DE UN ÁREA (GET /geo-admin/finca/areas/<idArea>)
  // ==========================================================
  Future<Map<String, dynamic>> getAreaDetails(int idArea) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl$_areaBaseRoute/$idArea');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // AJUSTE: Retorna 'data' directamente
        return {'success': true, 'data': data}; 
      } else {
        return {'success': false, 'message': data['mensaje'] ?? 'Error al obtener detalles'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // ✏️ ACTUALIZAR ÁREA (PUT /geo-admin/finca/areas/<idArea>)
  // ==========================================================
  Future<Map<String, dynamic>> updateArea(int idArea, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token de autenticación no encontrado'};
    }

    final url = Uri.parse('$_baseUrl$_areaBaseRoute/$idArea');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final dataRes = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // El objeto 'area' devuelto también debe contener 'jefeDeArea_nombre'
        return {'success': true, 'data': dataRes['area'], 'message': dataRes['mensaje']}; 
      } else {
        return {'success': false, 'message': dataRes['mensaje'] ?? 'Error al actualizar área'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // 🚫 INHABILITAR / HABILITAR ÁREA (PATCH /geo-admin/finca/areas/<idArea>/status)
  // ==========================================================
  Future<Map<String, dynamic>> toggleAreaStatus(int idArea) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl$_areaBaseRoute/$idArea/status');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ); // PATCH sin body

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['mensaje']};
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Error al cambiar el estado del área'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  // 📍 OBTENER LISTA DE FINCAS
  // ==========================================================
  Future<List<dynamic>> getAllFincas() async {
    final token = await _getToken();
    //el endpoint de Fincas es /geo-admin/fincas
    final url = Uri.parse('$_baseUrl/geo-admin/fincas'); 
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
  // 🧑‍💼 BÚSQUEDA DE JEFES DE ÁREA (Endpoint: /jefes-area/search)
  // ==========================================================
  Future<List<dynamic>> searchJefesArea(String query) async {
    final token = await _getToken();
    // Uso de la ruta de búsqueda con el query parameter 'query'
    final url = Uri.parse('$_baseUrl$_areaBaseRoute/jefes-area/search').replace(queryParameters: {
      'query': query,
    }); 

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && (data['success'] ?? false)) {
        // Esperamos una lista dentro de la propiedad 'resultados'
        return data['resultados'] ?? [];
      } else {
        // Maneja 404/otros errores o success=false
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}