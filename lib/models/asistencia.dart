// lib/models/asistencia.dart
class Asistencia {
  final int id;
  final int estudianteId;
  final DateTime horaEntrada;
  final String estado; 

  Asistencia({
    required this.id,
    required this.estudianteId,
    required this.horaEntrada,
    required this.estado,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['id'] as int,
      estudianteId: json['estudiante_id'] as int,
      // Supabase devuelve fechas en formato ISO 8601 String
      horaEntrada: DateTime.parse(json['hora_entrada'] as String).toLocal(), 
      estado: json['estado'] as String,
    );
  }
}