// lib/models/reporte_asistencia.dart
class ReporteAsistencia {
  final DateTime fechaHora;
  final String nombreEstudiante;
  final String clase;
  final String estado; // Asistencia, Retraso, Falta

  ReporteAsistencia({
    required this.fechaHora,
    required this.nombreEstudiante,
    required this.clase,
    required this.estado,
  });

  // Constructor que extrae datos de la respuesta unida de Supabase
  factory ReporteAsistencia.fromMap(Map<String, dynamic> map) {
    // Supabase devuelve los datos del estudiante anidados bajo 'estudiantes'
    // Usamos cast seguro por si la relación viene nula (aunque no debería con FK)
    final estudianteData = (map['estudiantes'] as Map<String, dynamic>?) ?? {};

    return ReporteAsistencia(
      fechaHora: DateTime.parse(map['hora_entrada'] as String).toLocal(),
      estado: map['estado'] as String,
      // Si no hay datos de estudiante, usamos valores por defecto
      nombreEstudiante: estudianteData['nombre'] ?? 'Desconocido',
      clase: estudianteData['clase'] ?? 'N/A',
    );
  }
}
