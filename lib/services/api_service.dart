import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class ApiService {
  static const String _baseUrl = "http://100.64.64.95:5000";
  static const String _tokenKey = "jwt_token";
  static const String _roleKey = "user_role";
  static const String _nameKey = "user_name"; // 🔥 1. NUEVA CLAVE PARA EL NOMBRE

  // ==========================================================
  // TOKEN & SESIÓN & CACHE DE DATOS
  // ==========================================================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  // 🔥 2. NUEVO MÉTODO: Guardar el nombre
  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  Future<void> _deleteSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey); // 🔥 4. LIMPIAR NOMBRE al cerrar sesión
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }
  
  // 🔥 3. NUEVO MÉTODO: Obtener el nombre
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  // ==========================================================
  // AUTENTICACIÓN
  // ==========================================================
  Future<Map<String, dynamic>> login(String correo, String password) async {
    final url = Uri.parse('$_baseUrl/user-auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        final user = User.fromJson(data['usuario']);

        await _saveToken(token);
        await _saveRole(user.rol);
        await _saveName(user.nombre); // 🔥 5. GUARDAR EL NOMBRE DEL USUARIO

        return {
          'success': true,
          'user': user,
          'role': user.rol,
        };
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Error de autenticación',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Error de conexión: asegúrate de que Flask esté corriendo en $_baseUrl',
      };
    }
  }

  // ... (El resto de tus métodos: register, getProfile, getAllUsers, etc. se mantienen igual)
  
  // ==========================================================
  // REGISTRO DE USUARIO (con validación y corrección de rol)
  // ==========================================================
  Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    final url = Uri.parse('$_baseUrl/user-auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // ✅ Registro exitoso
        final cedula = userData['cedula'];
        final rolEnviado = userData['rol'];

        // Obtener el usuario recién creado
        final userResponse = await getUserByCedula(cedula!);
        if (userResponse['success'] == true) {
          final usuario = userResponse['user'] as User;

          // Si el rol real no coincide, lo actualizamos
          if (usuario.rol != rolEnviado) {
            print("⚠️ Rol corregido automáticamente: ${usuario.rol}");
            await updateUser(cedula, {"rol": usuario.rol});
          }
        }

        return {
          'success': true,
          'message': data['mensaje'] ?? 'Registro exitoso',
        };
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Error de registro',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Error de conexión con el servidor. Revisa la red o el puerto 5000.',
      };
    }
  }

  // ==========================================================
  // PERFIL DE USUARIO
  // ==========================================================
  Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'No hay sesión activa'};
    }

    final url = Uri.parse('$_baseUrl/user/perfil');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(data['usuario']);
        // OPCIONAL: Si el perfil se actualiza, también podrías guardar el rol y el nombre aquí
        // await _saveRole(user.rol); 
        // await _saveName(user.nombre);

        return {'success': true, 'user': user};
      } else if (response.statusCode == 401) {
        await _deleteSession();
        return {'success': false, 'message': 'Sesión expirada'};
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Error al obtener perfil'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión. No se pudo obtener el perfil.',
      };
    }
  }

  Future<void> logout() async => await _deleteSession();

  // ==========================================================
  // ADMINISTRADOR - GESTIÓN DE USUARIOS
  // ==========================================================
  Future<Map<String, dynamic>> getAllUsers() async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/admin/users');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<User> users = (data['usuarios'] as List)
            .map((u) => User.fromJson(u))
            .toList();
        return {'success': true, 'users': users};
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Error al obtener usuarios'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al conectar con la API de usuarios administrativos',
      };
    }
  }

  Future<Map<String, dynamic>> getUserByCedula(String cedula) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/admin/user/$cedula');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'user': User.fromJson(data['usuario'])};
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Usuario no encontrado'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión al consultar usuario',
      };
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String cedula, Map<String, dynamic> updates) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/admin/user/edit/$cedula');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': User.fromJson(data['usuario']),
          'message': data['mensaje'],
        };
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Error al actualizar usuario'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión al editar usuario'};
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(
      String cedula, bool activar) async {
    final token = await _getToken();
    final endpoint = activar ? 'recover' : 'delete';
    final url = Uri.parse('$_baseUrl/admin/user/$endpoint/$cedula');

    try {
      final response = activar
          ? await http.put(url, headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            })
          : await http.delete(url, headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['mensaje']};
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Error al cambiar estado'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con la API'};
    }
  }

  Future<List<String>> getRoles() async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/admin/roles');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['roles']);
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  // ==========================================================
  // 🔥 ELIMINACIÓN DEFINITIVA
  // ==========================================================
  Future<Map<String, dynamic>> deleteUserPermanent(String cedula) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/admin/user/hard-delete/$cedula');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['mensaje'] ?? 'Usuario eliminado definitivamente'
        };
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Error al eliminar usuario'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con la API'};
    }
  }
    // ==========================================================
  // ✏️ EDITAR USUARIO (alias flexible para updateUser)
  // ==========================================================
  Future<Map<String, dynamic>> editUser(String cedula, Map<String, dynamic> updates) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/user-auth/edit/$cedula');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ Rol actualizado correctamente en backend");
        return {
          'success': true,
          'message': data['mensaje'] ?? 'Usuario editado correctamente',
          'user': data.containsKey('usuario') ? User.fromJson(data['usuario']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['mensaje'] ?? 'Error al editar usuario',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión al editar usuario: $e',
      };
    }
  }

}