class Estudiante {
  final int id;
  final String nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? ci;

  Estudiante({
    required this.id,
    required this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.ci,
  });

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      apellidoPaterno: json['apellido_paterno'] as String?,
      apellidoMaterno: json['apellido_materno'] as String?,
      ci: json['ci'] as String?,
    );
  }
  
  // Helper para nombre completo
  String get nombreCompleto => '$nombre ${apellidoPaterno ?? ''} ${apellidoMaterno ?? ''}'.trim();
}