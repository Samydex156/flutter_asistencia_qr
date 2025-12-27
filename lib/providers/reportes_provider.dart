import 'dart:io';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart'; // Para acceder a 'supabase'
import '../models/reporte_asistencia.dart';

class ReportesNotifier
    extends StateNotifier<AsyncValue<List<ReporteAsistencia>>> {
  ReportesNotifier() : super(const AsyncValue.loading()) {
    cargarHistorial();
  }

  // 1. Cargar el historial general (registros existentes)
  Future<void> cargarHistorial() async {
    try {
      state = const AsyncValue.loading();
      final data = await supabase
          .from('registros_asistencia')
          .select('*, estudiantes(nombre, apellido_paterno), cursos(nombre)')
          .order('hora_entrada', ascending: false);

      final lista = (data as List)
          .map((item) => ReporteAsistencia.fromMap(item))
          .toList();

      state = AsyncValue.data(lista);
    } catch (e, stack) {
      debugPrint('Error cargando historial: $e');
      state = AsyncValue.error('Error al cargar historial: $e', stack);
    }
  }

  // 1.b Generar reporte de HOY incluyendo inasistencias
  Future<void> cargarReporteHoyConFaltas() async {
    try {
      state = const AsyncValue.loading();
      final now = DateTime.now();
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).toUtc().toIso8601String();
      final endOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1)).toUtc().toIso8601String();

      // a. Obtener todas las inscripciones activas ( Universo de estudiantes que DEBEN asistir )
      final inscripcionesData = await supabase
          .from('inscripciones')
          .select('*, estudiantes(nombre, apellido_paterno), cursos(nombre)')
          .eq('estado', 'activo');

      // b. Obtener registros de asistencia de HOY
      final registrosHoyData = await supabase
          .from('registros_asistencia')
          .select()
          .gte('hora_entrada', startOfDay)
          .lt('hora_entrada', endOfDay);

      // Creamos un Set de llaves (estudiante_id-curso_id) que sí marcaron
      final Set<String> marcados = (registrosHoyData as List)
          .map((r) => "${r['estudiante_id']}-${r['curso_id']}")
          .toSet();

      List<ReporteAsistencia> reporteFinal = [];

      for (var ins in (inscripcionesData as List)) {
        final key = "${ins['estudiante_id']}-${ins['curso_id']}";

        if (marcados.contains(key)) {
          // Si marcó, buscamos su registro para tener la hora exacta y el estado (Puntual/Retraso/Falta)
          final registro = (registrosHoyData as List).firstWhere(
            (r) => "${r['estudiante_id']}-${r['curso_id']}" == key,
          );

          // Combinamos datos para el mapa del modelo
          final Map<String, dynamic> itemMap = {
            ...registro,
            'estudiantes': ins['estudiantes'],
            'cursos': ins['cursos'],
          };
          reporteFinal.add(ReporteAsistencia.fromMap(itemMap));
        } else {
          // NO MARCÓ -> Inasistencia
          final estudiante = ins['estudiantes'];
          final curso = ins['cursos'];
          reporteFinal.add(
            ReporteAsistencia(
              fechaHora: DateTime(
                now.year,
                now.month,
                now.day,
                9,
                0,
              ), // Hora base
              nombreCompleto:
                  "${estudiante['nombre']} ${estudiante['apellido_paterno'] ?? ''}"
                      .trim(),
              nombreCurso: curso['nombre'] ?? 'Sin Curso',
              estado: 'Inasistencia',
              pagoAlDia:
                  ins['proximo_pago_vence'] !=
                  null, // Opcional colocar lógica de pago aquí
            ),
          );
        }
      }

      // Ordenar: Primero los que sí asistieron, luego las inasistencias
      reporteFinal.sort((a, b) {
        if (a.estado == 'Inasistencia' && b.estado != 'Inasistencia') return 1;
        if (a.estado != 'Inasistencia' && b.estado == 'Inasistencia') return -1;
        return b.fechaHora.compareTo(a.fechaHora);
      });

      state = AsyncValue.data(reporteFinal);
    } catch (e, stack) {
      debugPrint('Error en reporte diario: $e');
      state = AsyncValue.error('Error al generar reporte de hoy: $e', stack);
    }
  }

  // 2. Función para exportar a CSV y compartir
  Future<void> exportarReporte() async {
    final reportes = state.value;
    if (reportes == null || reportes.isEmpty) return;

    try {
      // a. Crear la estructura del CSV
      List<List<dynamic>> rows = [];

      // Cabeceras ACTUALIZADAS (Eliminamos Clase, Agregamos Pago al Día)
      rows.add(["Fecha", "Hora", "Estudiante", "Estado", "Pago al Día"]);

      // Datos
      for (var reporte in reportes) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(reporte.fechaHora),
          DateFormat('HH:mm:ss').format(reporte.fechaHora),
          reporte.nombreCompleto, // Usamos el nombre completo del nuevo modelo
          reporte.estado,
          reporte.pagoAlDia
              ? 'AL DÍA'
              : 'DEUDA', // Convertimos booleano a texto
        ]);
      }

      // b. Convertir a String CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // c. Guardar archivo temporalmente
      final directory = await getTemporaryDirectory();
      final path =
          "${directory.path}/reporte_asistencia_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // d. Compartir el archivo
      await Share.shareXFiles(
        [XFile(path)],
        text:
            'Reporte de Asistencia - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
      );
    } catch (e) {
      debugPrint("Error al exportar: $e");
      throw Exception("No se pudo generar o compartir el archivo CSV: $e");
    }
  }
}

// Provider global
final reportesProvider =
    StateNotifierProvider<
      ReportesNotifier,
      AsyncValue<List<ReporteAsistencia>>
    >((ref) {
      return ReportesNotifier();
    });
