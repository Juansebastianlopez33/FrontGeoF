import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'home/home_screen.dart';
import 'admin_dashboard_screen.dart';
// 💡 Importar el tema global para consistencia
import 'home/theme/dark_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  // 🎯 DEFINICIÓN DE COLORES MATES (Mantenemos la estética específica del usuario)
  // Usaremos un color de acento azul/teal oscuro y desaturado
  static const Color _mateAccent = Color(0xFF5E8B9E); // Teal/Azul Mate
  static const Color _mateAdminColor = Color(0xFF8B4A4A); // Rojo Mate para Admin
  static const Color _mateLogoutColor = Color(0xFF9E4B4B); // Rojo Mate para Logout
  // Nota: Eliminamos _buttonBgColor y usamos GeoFloraTheme.card

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
            : _mateAccent, // Usar color mate para éxito
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

  // 🎯 AJUSTE VISUAL: Avatar sin neón ni gradientes brillantes
  Widget _buildAvatar(double avatarRadius) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Eliminamos el gradient neón, usamos un borde sutil con el color mate
        border: Border.all(color: _mateAccent.withOpacity(0.5), width: 2),
      ),
      child: CircleAvatar(
        radius: avatarRadius,
        // ✅ Usar color de tarjeta del tema para el fondo del avatar
        backgroundColor: GeoFloraTheme.card.withOpacity(0.6), 
        child: Icon(
          Icons.account_circle,
          size: avatarRadius * 1.5,
          color: _mateAccent, // Usar el color mate
        ),
      ),
    );
  }

  // 🎯 AJUSTE VISUAL: Fila de detalles con íconos y textos sobrios
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono con color mate
          Icon(icon, color: _mateAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500, // Texto de label más apagado
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17, // Ligeramente más grande
                    fontWeight: FontWeight.w600, // No tan bold
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
      // Usar el color mate para el indicador de carga
      return const Center(child: CircularProgressIndicator(color: _mateAccent));
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
                backgroundColor: _mateAccent, // Botón de recarga con color mate
                foregroundColor: Colors.white,
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
          // ✅ Aplicar GeoFloraTheme.card como fondo sólido para la tarjeta
          color: GeoFloraTheme.card, 
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
                      fontSize: 24, // Ligeramente más grande para más impacto
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Documento: ${_user!.tipoDocumento} ${_user!.cedula}',
                    // ✅ Usar el color de texto apagado del tema
                    style: TextStyle(fontSize: 16, color: GeoFloraTheme.textLight), 
                  ),
                  const SizedBox(height: 12),
                  if (_user!.rol.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        // 🎯 Color de Rol Mate (manteniendo el custom del usuario)
                        color: _user!.rol.toLowerCase() == 'admin'
                            ? _mateAdminColor.withOpacity(0.7) // Rojo mate admin
                            : _mateAccent.withOpacity(0.7), // Teal mate user
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
                  const Divider(height: 40, color: Colors.white12, thickness: 1.5), // Divisor más sutil
                ],
              ),
            ),
            _buildDetailRow("Correo Electrónico", _user!.correo, Icons.email_outlined),
            if ((_user!.telefono ?? '').isNotEmpty)
              _buildDetailRow("Teléfono", _user!.telefono!, Icons.phone_outlined),
            // Puedes agregar más detalles aquí si los hay
            
            const SizedBox(height: 40), // Más espacio antes de los botones
            
            // 🎯 AJUSTE VISUAL: Botón Home Mate (Borde y Texto con Color Mate)
            ElevatedButton.icon(
              icon: Icon(Icons.home_outlined, color: _mateAccent),
              label: Text("Ir a la Página Principal", style: TextStyle(color: _mateAccent)),
              onPressed: _handleGoToHome,
              style: ElevatedButton.styleFrom(
                // ✅ Usar color de tarjeta del tema para el fondo del botón
                backgroundColor: GeoFloraTheme.card, 
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(color: _mateAccent.withOpacity(0.5)), // Borde sutil
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            
            const SizedBox(height: 15), // Más espacio
            
            // 🎯 AJUSTE VISUAL: Botón Admin Mate
            if (_user!.rol.toLowerCase() == 'admin')
              ElevatedButton.icon(
                icon: Icon(Icons.admin_panel_settings_outlined, color: _mateAdminColor),
                label: Text("Ir al Panel de Administración", style: TextStyle(color: _mateAdminColor)),
                onPressed: _handleGoToAdmin,
                style: ElevatedButton.styleFrom(
                  // ✅ Usar color de tarjeta del tema para el fondo del botón
                  backgroundColor: GeoFloraTheme.card, 
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(color: _mateAdminColor.withOpacity(0.5)), // Borde sutil
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              
            const SizedBox(height: 15), // Más espacio
            
            // 🎯 AJUSTE VISUAL: Botón Cerrar Sesión Mate
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.white)),
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: _mateLogoutColor, // Rojo mate
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
      // ✅ Aplicar el color de fondo global del tema
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: const Text("Perfil de Usuario"),
        backgroundColor: Colors.black,
        // 🎯 AJUSTE VISUAL: Foreground color mate (manteniendo el custom del usuario)
        foregroundColor: _mateAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            // 🎯 AJUSTE VISUAL: Color de ícono de recarga mate
            color: _mateAccent,
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