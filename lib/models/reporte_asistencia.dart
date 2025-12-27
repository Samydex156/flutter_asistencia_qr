// lib/models/reporte_asistencia.dart
class ReporteAsistencia {
  final DateTime fechaHora;
  final String nombreCompleto; // Nombre + Apellido
  final String nombreCurso; // Nuevo campo
  final String estado; // Asistencia, Retraso
  final bool pagoAlDia; // Nuevo campo vital

  ReporteAsistencia({
    required this.fechaHora,
    required this.nombreCompleto,
    required this.nombreCurso,
    required this.estado,
    required this.pagoAlDia,
  });

  factory ReporteAsistencia.fromMap(Map<String, dynamic> map) {
    // Función auxiliar para extraer un mapa de una respuesta que podría ser Lista o Mapa
    Map<String, dynamic> extraerMapa(dynamic data) {
      if (data == null) {
        return {};
      }
      if (data is List && data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      }
      if (data is Map) {
        return data as Map<String, dynamic>;
      }
      return {};
    }

    final estudiante = extraerMapa(map['estudiantes']);
    final curso = extraerMapa(map['cursos']);

    // Extraer valores con seguridad total
    final horaStr = map['hora_entrada']?.toString();
    final fecha = (horaStr != null)
        ? DateTime.parse(horaStr).toLocal()
        : DateTime.now();

    return ReporteAsistencia(
      fechaHora: fecha,
      estado: map['estado']?.toString() ?? 'N/A',
      pagoAlDia: map['pago_al_dia'] == true, // Seguro contra nulls
      nombreCurso: curso['nombre']?.toString() ?? 'Sin Curso',
      nombreCompleto:
          "${estudiante['nombre'] ?? 'Estudiante'} ${estudiante['apellido_paterno'] ?? ''}"
              .trim(),
    );
  }
}
