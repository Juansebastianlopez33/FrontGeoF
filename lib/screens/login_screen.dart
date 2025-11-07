// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final correo = _correoController.text.trim();
    final password = _passwordController.text;

    if (correo.isEmpty || password.isEmpty) {
      _showSnackbar("Por favor, ingresa correo y contraseña.");
      setState(() => _isLoading = false);
      return;
    }

    final result = await _apiService.login(correo, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final user = result['user'];
      final role = result['role'] ?? 'user';

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WelcomeScreen(
            nombre: user.nombre,
            rol: role,
          ),
        ),
      );
    } else {
      _showSnackbar(result['message'] ?? "Error al iniciar sesión");
    }
  }

  void _handleGoToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  Widget _buildLoginForm(double maxWidth) {
    final double formWidth = maxWidth > 600 ? 400 : maxWidth * 0.9;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        width: formWidth,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 10),
            Text(
              "Iniciar Sesión",
              style: TextStyle(
                fontSize: maxWidth > 600 ? 32 : 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD4AF37),
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _correoController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Correo Electrónico',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.email, color: Colors.white70),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                : ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2C2C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('INGRESAR'),
                  ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: _handleGoToRegister,
              child: const Text(
                "¿No tienes cuenta? Regístrate aquí",
                style: TextStyle(color: Color(0xFF6FCF97)),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1E1E1E), Color(0xFF0F2C2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: _buildLoginForm(constraints.maxWidth),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================================
// 🌹 PANTALLA DE BIENVENIDA CON MÁS VIDA Y PROFUNDIDAD VISUAL
// ==========================================================
class WelcomeScreen extends StatefulWidget {
  final String nombre;
  final String rol;

  const WelcomeScreen({super.key, required this.nombre, required this.rol});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Color _backgroundColor = const Color(0xFF0F2C2C);
  IconData _icon = Icons.account_circle;

  @override
  void initState() {
    super.initState();

    switch (widget.rol) {
      case 'AgronomoFinca':
        _backgroundColor = const Color(0xFF1B5E20);
        _icon = Icons.local_florist;
        break;
      case 'dbAdmin':
        _backgroundColor = const Color(0xFF263238);
        _icon = Icons.storage_rounded;
        break;
      case 'UserAdmin':
      case 'admin':
        _backgroundColor = const Color(0xFF880E4F);
        _icon = Icons.admin_panel_settings_rounded;
        break;
      default:
        _backgroundColor = const Color(0xFF0F2C2C);
        _icon = Icons.person_rounded;
        break;
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      _irAlPerfil();
    });
  }

  void _irAlPerfil() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 900),
      pageBuilder: (_, __, ___) => const ProfileScreen(),
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        final slide =
            Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                .animate(fade);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icon, color: Colors.white, size: 110),
                const SizedBox(height: 20),
                Text(
                  "BIENVENIDO",
                  style: TextStyle(
                    fontSize: screenW > 600 ? 46 : 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD4AF37),
                    letterSpacing: 1.3,
                    shadows: const [
                      Shadow(blurRadius: 8, color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.nombre.toUpperCase(),
                  style: TextStyle(
                    fontSize: screenW > 600 ? 26 : 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "(${widget.rol.toUpperCase()})",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Conectando con tu perfil floral...",
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
