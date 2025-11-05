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

  // Tipos de documento para el Dropdown
  final List<String> _documentTypes = ['CC', 'TI', 'CE', 'PA', 'RC'];
  String? _selectedDocumentType = 'CC'; // Valor inicial por defecto

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
        backgroundColor: isError ? Colors.red : Colors.green,
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
      // Usamos el valor seleccionado del Dropdown
      'tipo_documento': _selectedDocumentType ?? '',
      'telefono': _telefonoController.text.trim(),
      'correo': _correoController.text.trim(),
      'password': _passwordController.text,
    };

    final result = await _apiService.register(userData);

    if (result['success'] == true) {
      _showSnackbar("Registro exitoso. Inicia sesión.", isError: false);
      if (mounted) {
        // Navega a Login, eliminando la pantalla de registro.
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

  // Widget para el formulario de registro responsive
  Widget _buildRegisterForm(double maxWidth) {
    final double formWidth = maxWidth > 600 ? 500 : maxWidth * 0.9;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        width: formWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: maxWidth > 600 ? [
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ] : null,
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
                  fontSize: maxWidth > 600 ? 32 : 28, // Ajuste de tamaño
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // --- Campos del Formulario ---
              TextFormField(
                controller: _cedulaController,
                decoration: const InputDecoration(labelText: 'Cédula', border: OutlineInputBorder(), prefixIcon: Icon(Icons.credit_card)),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 15),
              // Dropdown para Tipo Documento
              DropdownButtonFormField<String>(
                value: _selectedDocumentType,
                decoration: const InputDecoration(
                  labelText: 'Tipo Documento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                items: _documentTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDocumentType = newValue;
                  });
                },
                validator: (value) => value == null ? 'Selecciona un tipo de documento' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _telefonoController,
                // Nota: Este campo es obligatorio según la validación en el backend de Flask (user_auth.py).
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null, 
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@') ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              // --- Fin de Campos del Formulario ---
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                        // Borde redondeado para consistencia visual
                        shape: RoundedRectangleBorder( 
                          borderRadius: BorderRadius.circular(8),
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
                  foregroundColor: Theme.of(context).primaryColor, // Estilo para destacar
                ),
                child: const Text("¿Ya tienes cuenta? Inicia sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: _buildRegisterForm(constraints.maxWidth),
            ),
          );
        },
      ),
    );
  }
}
