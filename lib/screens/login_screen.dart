import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_screen.dart'; // Importa la pantalla de perfil
import 'register_screen.dart'; // Importa la pantalla de registro (nuevo archivo)

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
    if (_isLoading) return; // Evitar múltiples clicks

    setState(() {
      _isLoading = true;
    });

    final correo = _correoController.text.trim();
    final password = _passwordController.text;

    if (correo.isEmpty || password.isEmpty) {
      _showSnackbar("Por favor, ingresa correo y contraseña.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final result = await _apiService.login(correo, password);

    if (result['success'] == true) {
      _showSnackbar("Login exitoso", isError: false);
      if (mounted) {
        // Navega y elimina la pantalla de login del stack
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      }
    } else {
      _showSnackbar(result['message']);
    }

    setState(() {
      _isLoading = false;
    });
  }

  // FUNCIÓN AGREGADA: Ir a Registrarme
  void _handleGoToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  // Widget para el formulario de login responsive
  Widget _buildLoginForm(double maxWidth) {
    // Ancho máximo en PC/Web, o ancho completo en móvil
    final double formWidth = maxWidth > 600 ? 400 : maxWidth * 0.9;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        width: formWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          // Sombra solo para desktop/web
          boxShadow: maxWidth > 600 ? [
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Iniciar Sesión",
              style: TextStyle(
                fontSize: maxWidth > 600 ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('INGRESAR'),
                  ),
            const SizedBox(height: 10), // Nuevo separador
            // WIDGET AGREGADO: Botón de Registro
            TextButton(
              onPressed: _handleGoToRegister,
              child: const Text("¿No tienes cuenta? Regístrate aquí"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder ayuda a construir la UI basándose en el tamaño disponible (Responsive)
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: 40,
              horizontal: constraints.maxWidth > 600 ? constraints.maxWidth * 0.1 : 0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: _buildLoginForm(constraints.maxWidth),
            ),
          );
        },
      ),
    );
  }
}
