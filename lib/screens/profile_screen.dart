import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'home/home_screen.dart';
import 'admin_dashboard_screen.dart';

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
        backgroundColor: isError
            ? Colors.redAccent.shade200
            : Colors.greenAccent.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);

    final result = await _apiService.getProfile();

    if (result['success'] == true) {
      setState(() {
        _user = result['user'] as User?;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        _showSnackbar(result['message'] ?? 'Error de sesión. Vuelve a iniciar.');
        if (result['message'].toString().contains('Sesión expirada') ||
            result['message'].toString().contains('No hay token')) {
          _handleLogout();
        } else {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _handleGoToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen(userRole: _user?.rol ?? 'user')),
    );
  }

  void _handleGoToAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
    );
  }

  Widget _buildAvatar(double avatarRadius) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.6),
            Colors.tealAccent.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Colors.black.withOpacity(0.6),
        child: Icon(
          Icons.account_circle,
          size: avatarRadius * 1.5,
          color: Colors.greenAccent.shade400,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.greenAccent.shade400, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(double maxWidth) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              "No se pudo cargar el perfil.",
              style: TextStyle(fontSize: 18, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade400,
                foregroundColor: Colors.black,
              ),
              child: const Text('Recargar Perfil'),
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
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Column(
                children: [
                  _buildAvatar(avatarRadius),
                  const SizedBox(height: 20),
                  Text(
                    _user!.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Documento: ${_user!.tipoDocumento} ${_user!.cedula}',
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  if (_user!.rol.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _user!.rol.toLowerCase() == 'admin'
                            ? Colors.redAccent.shade400
                            : Colors.teal.shade600,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'ROL: ${_user!.rol.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const Divider(height: 40, color: Colors.white24),
                ],
              ),
            ),
            _buildDetailRow("Correo Electrónico", _user!.correo, Icons.email_outlined),
            if ((_user!.telefono ?? '').isNotEmpty)
              _buildDetailRow("Teléfono", _user!.telefono!, Icons.phone_outlined),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.home_outlined),
              label: const Text("Ir a la Página Principal"),
              onPressed: _handleGoToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade400,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            if (_user!.rol.toLowerCase() == 'admin')
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text("Ir al Panel de Administración"),
                onPressed: _handleGoToAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.shade700,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Cerrar Sesión"),
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade400,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Perfil de Usuario"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.greenAccent.shade400,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.greenAccent.shade400,
            onPressed: _fetchProfile,
            tooltip: "Recargar Perfil",
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth > 600 ? 40 : 20),
            child: _buildProfileDetails(constraints.maxWidth),
          );
        },
      ),
    );
  }
}
