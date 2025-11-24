import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'package:flutter/services.dart';
// ⚠️ IMPORTACIÓN CLAVE: Asegura la ruta correcta a tu tema
import 'home/theme/dark_theme.dart'; 

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
  bool _isPasswordVisible = false;

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

  // 1. 🟢 MODIFICACIÓN: Uso de GeoFloraTheme para los colores del Snackbar
  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          // Texto negro para buen contraste sobre el color de acento
          style: const TextStyle(color: Colors.black), 
        ), 
        backgroundColor: isError
            // Color de error fijo para consistencia si el tema no lo define
            ? Colors.redAccent.shade400
            // Usamos el color de acento para éxito
            : GeoFloraTheme.accent, 
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus(); 
    
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
        await Future.delayed(const Duration(milliseconds: 1500)); 
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

  // 2. 🟢 MODIFICACIÓN: Uso de constantes de GeoFloraTheme
  Widget _buildRegisterForm(double maxWidth) {
    final double formWidth = maxWidth > 600 ? 500 : maxWidth * 0.9;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(28.0),
        width: formWidth,
        decoration: BoxDecoration(
          // Usamos GeoFloraTheme.card para el fondo del formulario
          color: GeoFloraTheme.card.withOpacity(0.98), 
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
                  // Usamos GeoFloraTheme.accent para el título
                  color: GeoFloraTheme.accent, 
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
                formatterType: 'number',
                maxLength: 10,
              ),
              const SizedBox(height: 15),

              _buildField(
                controller: _nombreController,
                label: 'Nombre Completo',
                icon: Icons.person,
                keyboard: TextInputType.text,
                formatterType: 'text',
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
                    // Usamos GeoFloraTheme.accent para el borde enfocado
                    borderSide: const BorderSide(color: GeoFloraTheme.accent), 
                  ),
                ),
                // Usamos GeoFloraTheme.card para el fondo del dropdown
                dropdownColor: GeoFloraTheme.card, 
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
                formatterType: 'phone',
                maxLength: 10,
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
                obscure: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        // Usamos GeoFloraTheme.accent para el indicador
                        valueColor: const AlwaysStoppedAnimation<Color>(GeoFloraTheme.accent),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // Usamos GeoFloraTheme.accent para el botón principal
                        backgroundColor: GeoFloraTheme.accent, 
                        // Texto oscuro para alto contraste
                        foregroundColor: Colors.black, 
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
                  // Usamos GeoFloraTheme.accent para el texto del enlace
                  foregroundColor: GeoFloraTheme.accent, 
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

  // 3. 🟢 MODIFICACIÓN: Uso de GeoFloraTheme.accent
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboard,
    String? formatterType,
    int? maxLength,
    Widget? suffixIcon,
  }) {
    List<TextInputFormatter> formatters = [];
    int? limit;

    if (formatterType == 'number' || formatterType == 'phone') {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
      limit = maxLength;
    } else if (formatterType == 'text') {
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')));
      limit = maxLength;
    }
    
    if (maxLength != null && formatterType != 'number' && formatterType != 'phone') {
        limit = maxLength;
    }
    
    if (limit != null) {
        formatters.add(LengthLimitingTextInputFormatter(limit));
    }

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      inputFormatters: formatters,
      maxLength: null, 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white10,
        counterText: "",
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          // Usamos GeoFloraTheme.accent para el borde enfocado
          borderSide: const BorderSide(color: GeoFloraTheme.accent), 
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Campo obligatorio';
        }
        
        if (keyboard == TextInputType.emailAddress) {
          const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
          final regex = RegExp(pattern);
          if (!regex.hasMatch(value.trim())) {
            return 'Ingresa un correo electrónico válido';
          }
        }

        if (obscure && value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        
        if ((formatterType == 'number' || formatterType == 'phone') && value.length < 7) {
            return 'El campo debe tener al menos 7 dígitos';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 4. 🟢 MODIFICACIÓN: Usamos GeoFloraTheme.background
      backgroundColor: GeoFloraTheme.background, 
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 50), 
              child: _buildRegisterForm(constraints.maxWidth),
            ),
          );
        },
      ),
    );
  }
}