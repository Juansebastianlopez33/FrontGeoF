// lib/main.dart

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  // Asegura que los servicios de Flutter estén inicializados antes de usar SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Responsive Flask-Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Adaptación visual para diferentes plataformas
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Define un estilo de elevación común para los botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, 
            foregroundColor: Colors.white, 
          ),
        ),
      ),
      // AuthWrapper decide la pantalla inicial
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // Decide si mostrar LoginScreen o ProfileScreen revisando si hay token
  Future<bool> _checkAuthStatus() async {
    return ApiService().isAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Muestra una pantalla de carga mientras se verifica la sesión
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          // Si hay token (true), va a Perfil, sino a Login.
          final isAuthenticated = snapshot.data ?? false;
          return isAuthenticated ? const ProfileScreen() : const LoginScreen();
        }
      },
    );
  }
}