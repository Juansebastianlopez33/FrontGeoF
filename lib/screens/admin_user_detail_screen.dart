import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final User user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final ApiService _api = ApiService();
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late String _rolSeleccionado;
  bool _guardando = false;
  List<String> _rolesDisponibles = [];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.user.nombre);
    _correoController = TextEditingController(text: widget.user.correo);
    _telefonoController =
        TextEditingController(text: widget.user.telefono ?? '');
    _rolSeleccionado = widget.user.rol;
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final roles = await _api.getRoles();

    // Si la API no responde, usamos los roles oficiales definidos en el backend
    final fallbackRoles = [
      'user',
      'dbAdmin',
      'UserAdmin',
      'AnalistDB',
      'AgronomoFinca'
    ];

    setState(() {
      _rolesDisponibles =
          roles.isNotEmpty ? roles : fallbackRoles;

      // 🔧 Verificar que el rol actual del usuario exista en la lista
      // Si no existe, asignar el primero por defecto
      if (!_rolesDisponibles.contains(_rolSeleccionado)) {
        _rolSeleccionado = _rolesDisponibles.first;
      }
    });
  }

  Future<void> _guardarCambios() async {
    if (_guardando) return;
    setState(() => _guardando = true);

    final result = await _api.updateUser(widget.user.cedula, {
      "nombre": _nombreController.text.trim(),
      "correo": _correoController.text.trim(),
      "telefono": _telefonoController.text.trim(),
      "rol": _rolSeleccionado, // ✅ mantiene el nombre exacto
    });

    setState(() => _guardando = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al actualizar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cambiarEstadoUsuario(bool activar) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(activar ? "Activar usuario" : "Inactivar usuario"),
        content: Text(
          activar
              ? "¿Deseas habilitar nuevamente a este usuario?"
              : "¿Deseas inactivar este usuario? No podrá acceder al sistema.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: activar ? Colors.green : Colors.red,
            ),
            child: Text(activar ? "Activar" : "Inactivar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _api.toggleUserStatus(widget.user.cedula, activar);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Error al cambiar estado'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );

    if (result['success'] == true) Navigator.pop(context, true);
  }

  Future<void> _eliminarDefinitivo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar usuario definitivamente"),
        content: const Text(
          "Esta acción no se puede deshacer. ¿Seguro que deseas eliminar este usuario y todos sus datos?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _api.deleteUserPermanent(widget.user.cedula);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );

    if (result['success'] == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle: ${widget.user.nombre}"),
      ),
      body: _rolesDisponibles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nombreController,
                    decoration:
                        const InputDecoration(labelText: "Nombre completo"),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _correoController,
                    decoration: const InputDecoration(labelText: "Correo"),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(labelText: "Teléfono"),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _rolesDisponibles.contains(_rolSeleccionado)
                        ? _rolSeleccionado
                        : _rolesDisponibles.first,
                    items: _rolesDisponibles
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _rolSeleccionado = v ?? 'user'),
                    decoration:
                        const InputDecoration(labelText: "Rol asignado"),
                  ),
                  const SizedBox(height: 30),
                  _guardando
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("Guardar cambios"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: _guardarCambios,
                        ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    icon:
                        Icon(widget.user.isActive ? Icons.block : Icons.check),
                    label: Text(widget.user.isActive
                        ? "Inactivar usuario"
                        : "Activar usuario"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.user.isActive ? Colors.orange : Colors.green,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () =>
                        _cambiarEstadoUsuario(!widget.user.isActive),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: const Text("Eliminar definitivamente"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: _eliminarDefinitivo,
                  ),
                ],
              ),
            ),
    );
  }
}
