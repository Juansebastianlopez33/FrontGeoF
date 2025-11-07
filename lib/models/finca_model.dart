// Archivo: models/finca_model.dart

class Finca {
  // Campos obligatorios
  final int idFinca;
  final String codigoFinca;
  final String nombreFinca;
  final String direccionFinca;
  final String abreviaturaFinca;
  final bool isActive;
  
  // Campo opcional (puede ser null)
  final String? urlImagen; 
  
  // Campo que identifica al agrónomo, se asume que puede ser null al inicio o no estar en ciertos listados
  final String? agronomoEncargadoId; 

  Finca({
    required this.idFinca,
    required this.codigoFinca,
    required this.nombreFinca,
    required this.direccionFinca,
    required this.abreviaturaFinca,
    required this.isActive,
    this.urlImagen,
    this.agronomoEncargadoId,
  });

  /// Constructor de fábrica para crear una instancia de Finca a partir de un mapa JSON.
  factory Finca.fromJson(Map<String, dynamic> json) {
    return Finca(
      idFinca: json['idFinca'] as int,
      codigoFinca: json['codigoFinca'] as String,
      nombreFinca: json['nombreFinca'] as String,
      direccionFinca: json['direccionFinca'] as String,
      abreviaturaFinca: json['abreviaturaFinca'] as String,
      
      // Manejo de valores que pueden ser null
      agronomoEncargadoId: json['agronomoEncargado_id'] as String?,
      urlImagen: json['url_imagen'] as String?,
      
      // El estado de actividad es un booleano
      isActive: json['is_active'] as bool,
    );
  }
}