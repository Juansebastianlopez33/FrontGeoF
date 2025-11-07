import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminUserFormScreen extends StatefulWidget {
  const AdminUserFormScreen({super.key});

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _tipoDocumento = 'CC';
  String _rolSeleccionado = 'user';
  List<String> _rolesDisponibles = [];
  bool _guardando = false;
  bool _cargandoRoles = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _api.getRoles();

      const backendRoles = [
        'user',
        'dbAdmin',
        'UserAdmin',
        'AnalistDB',
        'AgronomoFinca',
      ];

      setState(() {
        _rolesDisponibles = roles.isNotEmpty ? roles : backendRoles;
        if (!_rolesDisponibles.contains(_rolSeleccionado)) {
          _rolSeleccionado = _rolesDisponibles.first;
        }
        _cargandoRoles = false;
      });
    } catch (e) {
      setState(() {
        _rolesDisponibles = ['user'];
        _rolSeleccionado = 'user';
        _cargandoRoles = false;
      });
    }
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    // 🔹 Normalizamos los datos antes de enviarlos
    final newUser = {
      "cedula": _cedulaController.text.trim(),
      "nombre": _nombreController.text.trim(),
      "tipo_documento": _tipoDocumento,
      "telefono": _telefonoController.text.trim(),
      "correo": _correoController.text.trim().toLowerCase(),
      "password": _passwordController.text.trim(),
      "rol": _rolSeleccionado,
    };

    debugPrint("🧠 Enviando usuario con rol: $_rolSeleccionado");

    final result = await _api.register(newUser);

    if (result['success'] == true) {
      // 🔹 Usuario registrado correctamente, ahora lo consultamos por cédula
      final cedula = _cedulaController.text.trim();
      final userData = await _api.getUserByCedula(cedula);

      final usuario = userData['usuario'] as Map<String, dynamic>?;

      if (usuario != null) {
        final backendRol = usuario['rol'];
        debugPrint("🧩 Rol guardado en backend: $backendRol");

        // 🔹 Si el rol no coincide, lo actualizamos
        if (backendRol != _rolSeleccionado) {
          debugPrint("🔄 Rol diferente detectado, actualizando a $_rolSeleccionado...");
          final updateResult = await _api.updateUser(cedula, {
            "rol": _rolSeleccionado,
          });

          if (updateResult['success'] == true) {
            debugPrint("✅ Rol actualizado correctamente en backend");
          } else {
            debugPrint("⚠️ Error al actualizar el rol: ${updateResult['mensaje'] ?? updateResult['message']}");
          }
        }
      } else {
        debugPrint("⚠️ No se encontró información del usuario en la respuesta del backend.");
      }
    }

    setState(() => _guardando = false);

    final mensaje = result['message'] ?? 'Usuario registrado correctamente';
    final color = result['success'] == true ? Colors.green : Colors.red;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: color),
      );
    }

    if (result['success'] == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar nuevo usuario")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _cedulaController,
                decoration: const InputDecoration(labelText: "Cédula"),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'La cédula es obligatoria' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: "Nombre completo"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _tipoDocumento,
                items: const [
                  DropdownMenuItem(value: 'CC', child: Text('Cédula de ciudadanía')),
                  DropdownMenuItem(value: 'CE', child: Text('Cédula de extranjería')),
                  DropdownMenuItem(value: 'PA', child: Text('Pasaporte')),
                ],
                onChanged: (v) => setState(() => _tipoDocumento = v ?? 'CC'),
                decoration: const InputDecoration(labelText: "Tipo de documento"),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: "Teléfono"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(labelText: "Correo electrónico"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'El correo es obligatorio';
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(v)) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Contraseña"),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
                  if (v.length < 6) return 'Debe tener al menos 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              if (_cargandoRoles)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: _rolesDisponibles.isNotEmpty
                      ? _rolSeleccionado
                      : 'user',
                  items: _rolesDisponibles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _rolSeleccionado = v ?? 'user'),
                  decoration: const InputDecoration(labelText: "Rol asignado"),
                ),

              const SizedBox(height: 30),

              _guardando
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text("Registrar usuario"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _guardarUsuario,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
