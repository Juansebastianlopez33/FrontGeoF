// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class ApiService {
  // 🚨 Usando la IP local proporcionada y el puerto 5000 de tu API Flask
  static const String _baseUrl = "http://100.68.144.119:5000"; 
  static const String _tokenKey = "jwt_token";

  /// Obtiene el token JWT almacenado localmente.
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Guarda el token JWT después de un login exitoso.
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Borra el token (Logout local).
  Future<void> _deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Verifica si hay un token almacenado (usuario autenticado).
  Future<bool> isAuthenticated() async {
    return await _getToken() != null;
  }

  // ------------------------------------------------------------------
  //  MÉTODOS DE LA API
  // ------------------------------------------------------------------

  /// Petición de Login (POST a /user-auth/login)
  Future<Map<String, dynamic>> login(String correo, String password) async {
    final url = Uri.parse('$_baseUrl/user-auth/login');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'password': password}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Éxito: Guardar token y devolver datos del usuario
        await _saveToken(responseBody['token']);
        return {
          'success': true,
          'user': User.fromJson(responseBody['usuario'])
        };
      } else {
        // Error de la API (ej: 401, 404, 400)
        return {
          'success': false,
          'message': responseBody['mensaje'] ?? 'Error de autenticación'
        };
      }
    } catch (e) {
      // Error de red (ej: IP incorrecta, API no corriendo, puerto bloqueado)
      return {
        'success': false,
        'message': 'Error de conexión: No se pudo conectar con la API en $_baseUrl. Asegúrate que Flask esté corriendo con host="0.0.0.0".'
      };
    }
  }

  /// Petición de Registro (POST a /user-auth/register)
  Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    final url = Uri.parse('$_baseUrl/user-auth/register');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseBody['mensaje'] ?? 'Registro exitoso'
        };
      } else {
        // Error de la API (ej: 400, 409)
        return {
          'success': false,
          'message': responseBody['mensaje'] ?? 'Error de registro'
        };
      }
    } catch (e) {
      // Error de red
      return {
        'success': false,
        'message': 'Error de conexión: No se pudo conectar con la API en $_baseUrl. Revisa la red.'
      };
    }
  }

  /// Petición para obtener perfil de usuario (GET a /user/perfil)
  Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'No hay token almacenado'};
    }

    final url = Uri.parse('$_baseUrl/user/perfil');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Enviar el token en el header
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': User.fromJson(responseBody['usuario'])
        };
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        // Token expirado o inválido, forzar logout
        await _deleteToken(); 
        return {
          'success': false,
          'message': responseBody['mensaje'] ?? 'Sesión expirada o token inválido'
        };
      } else {
        // Otros errores del servidor
        return {
          'success': false,
          'message': responseBody['mensaje'] ?? 'Error al obtener perfil'
        };
      }
    } catch (e) {
      // Error de red
      return {
        'success': false,
        'message': 'Error de conexión al obtener el perfil. Revisa la red.'
      };
    }
  }

  /// Petición de Logout (solo borra el token localmente)
  Future<void> logout() async {
    await _deleteToken();
  }
}