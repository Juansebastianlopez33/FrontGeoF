import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'admin_user_detail_screen.dart';
import 'admin_user_form_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _api = ApiService();
  List<User> _users = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    final result = await _api.getAllUsers();
    if (result['success'] == true) {
      setState(() {
        _users = result['users'];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Error al cargar usuarios')),
      );
    }
  }

  void _goToUserDetail(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserDetailScreen(user: user),
      ),
    ).then((_) => _fetchUsers());
  }

  void _goToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminUserFormScreen()),
    ).then((_) => _fetchUsers());
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      return u.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.cedula.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Usuarios"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddUser,
        child: const Icon(Icons.person_add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar usuario por nombre o cédula',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: filteredUsers.isEmpty
                      ? const Center(child: Text('No hay usuarios registrados'))
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: user.isActive
                                      ? Colors.green
                                      : Colors.redAccent,
                                  child: Text(user.nombre[0].toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ),
                                title: Text(user.nombre),
                                subtitle: Text(
                                    "Cédula: ${user.cedula} | Rol: ${user.rol}"),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[600],
                                ),
                                onTap: () => _goToUserDetail(user),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
