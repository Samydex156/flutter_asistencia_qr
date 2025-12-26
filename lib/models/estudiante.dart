// lib/models/estudiante.dart
class Estudiante {
  final int id;
  final String nombre;
  final String clase;
  final String? codigoQrData; // Almacena el ID como String para el QR

  Estudiante({
    required this.id,
    required this.nombre,
    required this.clase,
    this.codigoQrData,
  });

  // Método de fábrica para crear una instancia desde un mapa de Supabase
  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      clase: json['clase'] as String,
      codigoQrData: json['codigo_qr_data'] as String?,
    );
  }
}