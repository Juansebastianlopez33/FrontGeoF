import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final List<String> _documentTypes = ['CC', 'TI', 'CE', 'PA', 'RC'];
  String? _selectedDocumentType = 'CC';

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final userData = {
      'cedula': _cedulaController.text.trim(),
      'nombre': _nombreController.text.trim(),
      'tipo_documento': _selectedDocumentType ?? '',
      'telefono': _telefonoController.text.trim(),
      'correo': _correoController.text.trim(),
      'password': _passwordController.text,
    };

    final result = await _apiService.register(userData);

    if (result['success'] == true) {
      _showSnackbar("Registro exitoso. Inicia sesión.", isError: false);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      _showSnackbar(result['message'] ?? 'Error desconocido al registrar.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 🎨 Formulario adaptado a tema oscuro elegante
  Widget _buildRegisterForm(double maxWidth) {
    final double formWidth = maxWidth > 600 ? 500 : maxWidth * 0.9;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(28.0),
        width: formWidth,
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white12),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                "Crear Cuenta",
                style: TextStyle(
                  fontSize: maxWidth > 600 ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // --- Campos del Formulario ---
              _buildField(
                controller: _cedulaController,
                label: 'Cédula',
                icon: Icons.credit_card,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 15),

              _buildField(
                controller: _nombreController,
                label: 'Nombre Completo',
                icon: Icons.person,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedDocumentType,
                decoration: InputDecoration(
                  labelText: 'Tipo Documento',
                  prefixIcon: const Icon(Icons.description, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
                dropdownColor: colorScheme.surface,
                items: _documentTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white70)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedDocumentType = newValue);
                },
                validator: (value) =>
                    value == null ? 'Selecciona un tipo de documento' : null,
              ),
              const SizedBox(height: 15),

              _buildField(
                controller: _telefonoController,
                label: 'Teléfono',
                icon: Icons.phone,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 15),

              _buildField(
                controller: _correoController,
                label: 'Correo Electrónico',
                icon: Icons.email,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),

              _buildField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock,
                obscure: true,
              ),
              // --- Fin Campos ---

              const SizedBox(height: 30),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('REGISTRAR'),
                    ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.secondary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text("¿Ya tienes cuenta? Inicia sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 Campo reutilizable con estilo oscuro
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _buildRegisterForm(constraints.maxWidth),
            ),
          );
        },
      ),
    );
  }
}
