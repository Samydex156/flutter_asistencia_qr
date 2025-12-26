// lib/providers/reportes_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart'; // <--- Para debugPrint
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

  // 1. Cargar el historial desde Supabase
  Future<void> cargarHistorial() async {
    try {
      state = const AsyncValue.loading();

      // Consulta con JOIN: traemos registros e incluimos datos de la tabla 'estudiantes'
      final data = await supabase
          .from('registros_asistencia')
          .select('*, estudiantes(nombre, clase)')
          .order('hora_entrada', ascending: false); // Los más recientes primero

      final lista = (data as List)
          .map((item) => ReporteAsistencia.fromMap(item))
          .toList();

      state = AsyncValue.data(lista);
    } catch (e, stack) {
      state = AsyncValue.error('Error al cargar historial: $e', stack);
    }
  }

  // 2. Función para exportar a CSV y compartir
  Future<void> exportarReporte() async {
    final reportes = state.value;
    if (reportes == null || reportes.isEmpty) return;

    try {
      // a. Crear la estructura del CSV
      List<List<dynamic>> rows = [];

      // Cabeceras
      rows.add(["Fecha", "Hora", "Estudiante", "Clase", "Estado"]);

      // Datos
      for (var reporte in reportes) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(reporte.fechaHora),
          DateFormat('HH:mm:ss').format(reporte.fechaHora),
          reporte.nombreEstudiante,
          reporte.clase,
          reporte.estado,
        ]);
      }

      // b. Convertir a String CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // c. Guardar archivo temporalmente
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/reporte_asistencia.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // d. Compartir el archivo (hace que aparezca el menú "Compartir con..." de Android)
      // Usamos Share.shareXFiles en lugar de shareFiles (versiones nuevas)
      await Share.shareXFiles([
        XFile(path),
      ], text: 'Aquí tienes el reporte de asistencia.');
    } catch (e) {
      debugPrint("Error al exportar: $e");
      throw Exception("No se pudo exportar el archivo");
    }
  }
}

final reportesProvider =
    StateNotifierProvider<
      ReportesNotifier,
      AsyncValue<List<ReporteAsistencia>>
    >((ref) {
      return ReportesNotifier();
    });
