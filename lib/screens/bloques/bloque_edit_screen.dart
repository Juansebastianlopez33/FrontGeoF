// lib/screens/bloque/bloque_edit_screen.dart

import 'package:flutter/material.dart';
import '../../services/bloques_service.dart';
import '../home/theme/dark_theme.dart';

class BloqueEditScreen extends StatefulWidget {
  final int idBloque;

  const BloqueEditScreen({super.key, required this.idBloque});

  @override
  State<BloqueEditScreen> createState() => _BloqueEditScreenState();
}

class _BloqueEditScreenState extends State<BloqueEditScreen> {
  final BloquesService _bloquesService = BloquesService();
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _bloqueData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Controllers for editable fields
  final TextEditingController _numeroBloqueController = TextEditingController();
  final TextEditingController _nombreBloqueController = TextEditingController();
  final TextEditingController _superficieController = TextEditingController();
  
  // State for the status switch
  bool _isActive = false;

  final Color _themeAccent = GeoFloraTheme.accent;
  final Color _themeBackground = GeoFloraTheme.surface;

  @override
  void initState() {
    super.initState();
    _loadBloqueDetails();
  }

  @override
  void dispose() {
    _numeroBloqueController.dispose();
    _nombreBloqueController.dispose();
    _superficieController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD BLOCK DETAILS
  // ==========================================================
  Future<void> _loadBloqueDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _bloquesService.getBloqueDetails(widget.idBloque);

    if (mounted) {
      if (result['success']) {
        _bloqueData = result['data'];
        
        // Load data into controllers and switch
        _numeroBloqueController.text = _bloqueData!['numeroBloque']?.toString().toUpperCase() ?? '';
        _nombreBloqueController.text = _bloqueData!['nombreBloque']?.toString().toUpperCase() ?? '';
        _superficieController.text = _bloqueData!['superficieHectareas']?.toString() ?? '';
        _isActive = _bloqueData!['is_active'] ?? false;

      } else {
        _errorMessage = result['message'];
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==========================================================
  // TOGGLE BLOCK STATUS (Switch Action)
  // ==========================================================
  Future<void> _toggleStatus(bool newStatus) async {
    // Avoid simultaneous updates
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final result = await _bloquesService.toggleBloqueStatus(widget.idBloque, newStatus);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (result['success']) {
        setState(() {
          _isActive = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bloque ${newStatus ? 'Habilitado' : 'Inhabilitado'} con éxito.'),
            backgroundColor: _themeAccent,
          ),
        );
        // Opcional: Notificar a la pantalla anterior sobre el cambio si es necesario.
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  // ==========================================================
  // SAVE EDITS (Placeholder for a full update form)
  // ==========================================================
  Future<void> _saveEdits() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // TODO: Gather all form data and call _bloquesService.updateBloque

    await Future.delayed(const Duration(milliseconds: 800)); // Simulate API call

    setState(() {
      _isSaving = false;
    });
    
    // For now, just show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edición del Bloque ${widget.idBloque} guardada (Simulación).')),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeBackground,
      appBar: AppBar(
        title: Text('Detalle Bloque N° ${widget.idBloque}'),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Status Switch Section
                        _buildStatusSwitch(),
                        const Divider(color: Colors.white12, height: 40),

                        // Placeholder for full detail fields (e.g., area parent, etc.)
                        const Text('Detalles de Edición (FALTA IMPLEMENTAR CAMPOS)', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 10),

                        // Example Editable Field
                        TextFormField(
                          controller: _numeroBloqueController,
                          enabled: !_isSaving,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Número de Bloque',
                            labelStyle: const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          // Add formatting logic here if needed (e.g., uppercase)
                        ),
                        
                        const SizedBox(height: 20),

                        // Save Button (for the full edit form)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveEdits,
                            icon: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                  )
                                : const Icon(Icons.edit),
                            label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios', style: const TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _themeAccent,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Widget for the status switch
  Widget _buildStatusSwitch() {
    final statusText = _isActive ? 'Habilitado' : 'Inhabilitado';
    final statusColor = _isActive ? _themeAccent : Colors.redAccent;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado Actual:',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Switch(
            value: _isActive,
            onChanged: _isSaving ? null : _toggleStatus,
            activeColor: _themeAccent,
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}