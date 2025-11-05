import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart'; // Importa la pantalla de inicio

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.getProfile();

    if (result['success'] == true) {
      setState(() {
        _user = result['user'] as User?;
        _isLoading = false;
      });
    } else {
      // Si falla (sesión expirada, etc.), redirigir a Login y limpiar el historial
      if (mounted) {
        _showSnackbar(result['message'] ?? 'Error de sesión. Vuelve a iniciar.', isError: true);
        if (result['message'].toString().contains('Sesión expirada') || result['message'].toString().contains('No hay token')) {
            _handleLogout(); // Llama a logout para asegurar limpieza de token
        } else {
             setState(() {
              _isLoading = false;
            });
        }
      }
    }
  }
  
  // Función para cerrar sesión (limpia token y navega)
  Future<void> _handleLogout() async {
    await _apiService.logout();
    if (mounted) {
      // Navega y elimina la pantalla de perfil del stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
      );
    }
  }

  // Función para volver a la Home Screen (si el usuario está logeado)
  void _handleGoToHome() {
    // Usa pushReplacement si la pantalla de perfil se usa como el primer destino de un usuario logeado
    // Si se accede desde la home, usa pop() o push()
    Navigator.of(context).pushReplacement( 
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Widget para mostrar un detalle de usuario
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget principal con los detalles del perfil
  Widget _buildProfileDetails(double maxWidth) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("No se pudo cargar el perfil.", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Reintentar"),
              onPressed: _fetchProfile,
            ),
            const SizedBox(height: 10),
             ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Volver a Login"),
              onPressed: _handleLogout,
            ),
          ],
        ),
      );
    }

    final avatarRadius = maxWidth > 600 ? 70.0 : 50.0;
    final contentWidth = maxWidth > 600 ? 600.0 : maxWidth;

    return Center(
      child: Container(
        width: contentWidth,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            if (maxWidth > 600)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Sección de Avatar y Nombre
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.account_circle,
                      size: avatarRadius * 1.5,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _user!.nombre,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: maxWidth > 600 ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Documento: ${_user!.tipoDocumento} ${_user!.cedula}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const Divider(height: 30),
                ],
              ),
            ),
            
            // Sección de Detalles
            _buildDetailRow("Correo Electrónico", _user!.correo, Icons.email),
            if (_user!.telefono != null && _user!.telefono!.isNotEmpty) 
              _buildDetailRow("Teléfono", _user!.telefono!, Icons.phone),
            
            // Botones de acción
            const SizedBox(height: 30),
            
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text("Ir a la Página Principal"),
              onPressed: _handleGoToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Cerrar Sesión"),
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil de Usuario"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProfile,
            tooltip: "Recargar Perfil",
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth > 600 ? 40 : 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (kToolbarHeight + (constraints.maxWidth > 600 ? 80 : 40)), 
              ),
              child: _buildProfileDetails(constraints.maxWidth),
            ),
          );
        },
      ),
    );
  }
}