// lib/screens/login_screen.dart (MODIFICADO - Estética de Alto Contraste)

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'register_screen.dart';
// ⚠️ ASEGÚRESE DE QUE LA RUTA SEA CORRECTA
import 'home/theme/dark_theme.dart'; 

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
  // 🟢 CAMBIO REQUERIDO: Estado para controlar la visibilidad de la contraseña
  bool _isPasswordVisible = false;

  void _showSnackbar(String message, {bool isError = true}) {
    // Usamos el tema para los colores de feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: isError ? Colors.redAccent : GeoFloraTheme.accent,
        behavior: SnackBarBehavior.floating, // Más moderno
      ),
    );
  }

  Future<void> _handleLogin() async {
    // ... Lógica de login (sin cambios)
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final correo = _correoController.text.trim();
    final password = _passwordController.text;

    if (correo.isEmpty || password.isEmpty) {
      _showSnackbar("Por favor, ingresa correo y contraseña.");
      setState(() => _isLoading = false);
      return;
    }

    // Simulamos la llamada a la API
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
    
    // 1. Usamos el color de Superficie del tema para la elevación del panel
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30.0), // Más padding para aire
        width: formWidth,
        decoration: BoxDecoration(
          color: GeoFloraTheme.surface, // Superficie Elevada
          borderRadius: BorderRadius.circular(18), // Bordes más suaves
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5), // Sombra fuerte
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "INICIAR SESIÓN", // Texto más formal en mayúsculas
              style: TextStyle(
                fontSize: maxWidth > 600 ? 34 : 28,
                fontWeight: FontWeight.w900,
                color: GeoFloraTheme.gold, // Acento en el título
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "GeoFlora Management System",
              style: TextStyle(
                fontSize: 16,
                color: GeoFloraTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 35),
            
            // Los TextField ahora toman su estilo (fillColor, border, etc.) de GeoFloraTheme.theme.inputDecorationTheme
            TextField(
              controller: _correoController,
              style: const TextStyle(color: GeoFloraTheme.textLight),
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: Icon(Icons.email_outlined, color: GeoFloraTheme.textMuted),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: GeoFloraTheme.textLight),
              // ⚠️ CAMBIO CLAVE: Quitamos 'const' y añadimos suffixIcon
              decoration: InputDecoration( 
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline, color: GeoFloraTheme.textMuted),
                // 🟢 Ícono de Ojo para ver/ocultar contraseña
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: GeoFloraTheme.textMuted,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              // 🟢 Usamos el estado para decidir si ocultar el texto
              obscureText: !_isPasswordVisible, 
            ),
            const SizedBox(height: 35),
            
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: GeoFloraTheme.accent)) // Usamos accent para loading
                : ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      // 2. Usamos el acento para el botón primario
                      backgroundColor: GeoFloraTheme.accent, 
                      foregroundColor: Colors.black, // Texto negro sobre verde
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8, // Elevación para hacerlo táctil
                    ),
                    child: const Text('INGRESAR'),
                  ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _handleGoToRegister,
              child: const Text(
                "¿No tienes cuenta? Regístrate aquí",
                style: TextStyle(
                  color: GeoFloraTheme.accent, // Usamos el color de acento
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
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
      // Ya no necesitamos el gradiente, usamos el background global
      backgroundColor: GeoFloraTheme.background, 
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _buildLoginForm(constraints.maxWidth),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================================
// 🌹 PANTALLA DE BIENVENIDA CON MÁS VIDA Y PROFUNDIDAD VISUAL
// ==========================================================

// 🎯 MAPA DE COLORES PROFESIONALES POR ROL
// Usamos tonos temáticos y de alto contraste en lugar de colores arbitrarios.
const Map<String, Color> _roleColors = {
  'AgronomoFinca': Color(0xFF386641), // Verde Bosque (Serio)
  'dbAdmin': Color(0xFF4A4E69), // Azul Pizarra (Base de Datos)
  'UserAdmin': Color(0xFF9D4EDD), // Morado Intenso (Administración)
  'admin': Color(0xFFE63946), // Rojo Vibrante (Máximo Nivel)
  'user': GeoFloraTheme.surface, // Superficie Estándar
};

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

  Color _backgroundColor = GeoFloraTheme.background;
  IconData _icon = Icons.account_circle;

  @override
  void initState() {
    super.initState();

    // 1. Asignación de colores e iconos más estéticos
    _backgroundColor = _roleColors[widget.rol] ?? GeoFloraTheme.background;
    switch (widget.rol) {
      case 'AgronomoFinca':
        _icon = Icons.spa_outlined;
        break;
      case 'dbAdmin':
        _icon = Icons.storage_outlined;
        break;
      case 'UserAdmin':
      case 'admin':
        _icon = Icons.verified_user_outlined;
        break;
      default:
        _icon = Icons.person_outline;
        break;
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Animación más rápida
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _slideController.forward();
    });

    // Reducimos el tiempo de espera a 2.5 segundos (más profesional)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _irAlPerfil();
    });
  }

  void _irAlPerfil() {
    // Transición de página más suave
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) => const ProfileScreen(),
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        final slide =
            Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
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
    final String nombreCapitalizado = widget.nombre.split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
    
    // El rol se mantiene en mayúsculas para ser distintivo
    final String rolUpper = widget.rol.toUpperCase();

    return Scaffold(
      // 2. El color de fondo del Scaffold está determinado por el rol
      backgroundColor: _backgroundColor, 
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3. Ícono del rol prominente
                Icon(_icon, color: GeoFloraTheme.textLight, size: 120),
                const SizedBox(height: 30),
                Text(
                  "BIENVENIDO",
                  style: TextStyle(
                    fontSize: screenW > 600 ? 50 : 38,
                    fontWeight: FontWeight.w900,
                    color: GeoFloraTheme.gold, // Usamos el gold del tema
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.6),
                          offset: const Offset(2, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // 4. Nombre con capitalización de palabras (más elegante)
                Text(
                  nombreCapitalizado, 
                  style: TextStyle(
                    fontSize: screenW > 600 ? 30 : 24,
                    fontWeight: FontWeight.w500,
                    color: GeoFloraTheme.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "ROL: $rolUpper",
                  style: TextStyle(
                    fontSize: 18,
                    color: GeoFloraTheme.textLight.withOpacity(0.8),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 50),
                CircularProgressIndicator(
                  // Usamos el acento para el cargador
                  valueColor: const AlwaysStoppedAnimation<Color>(GeoFloraTheme.accent), 
                ),
                const SizedBox(height: 40),
                Text(
                  "Cargando módulos de gestión...",
                  style: TextStyle(color: GeoFloraTheme.textMuted, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}