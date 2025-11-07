import 'package:flutter/material.dart';
import '../home/theme/dark_theme.dart';

class FincaRegisterScreen extends StatefulWidget {
  const FincaRegisterScreen({super.key});

  @override
  State<FincaRegisterScreen> createState() => _FincaRegisterScreenState();
}

class _FincaRegisterScreenState extends State<FincaRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController ubicacionController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  bool _loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    await Future.delayed(const Duration(seconds: 1)); // Simulación backend

    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Finca registrada correctamente')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: const Text("Registrar Finca"),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: codigoController,
                decoration: const InputDecoration(
                  labelText: "Código (C.O)",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la Finca",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: ubicacionController,
                decoration: const InputDecoration(
                  labelText: "Ubicación",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 25),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GeoFloraTheme.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: const Text("Guardar Finca"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
