import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart'; // Para acceder a 'supabase'

// Configuración: Horario General (9:00 AM - 1:00 PM)
const int horaEntrada = 9;
const int minutoEntrada = 0;
const int toleranciaMinutos = 15; // Hasta las 9:15 es Asistencia
const int horaLimiteRetraso = 10;
const int minutoLimiteRetraso =
    30; // Después de las 10:30 es Falta (por horario)

class AsistenciaNotifier extends StateNotifier<AsyncValue<void>> {
  AsistenciaNotifier() : super(const AsyncValue.data(null));

  Future<String> registrarAsistencia(String qrScannedData) async {
    final now = DateTime.now();

    // Inicio y fin del día actual para verificar duplicados
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      // ---------------------------------------------------------
      // PASO 1: BUSCAR LA INSCRIPCIÓN POR EL CÓDIGO QR
      // ---------------------------------------------------------
      // Buscamos en la tabla 'inscripciones', no en 'estudiantes'.
      // Hacemos join con 'estudiantes' y 'cursos' para mostrar info bonita.
      final response = await supabase
          .from('inscripciones')
          .select('*, estudiantes(*), cursos(*)')
          .eq('codigo_qr_data', qrScannedData)
          .maybeSingle();

      if (response == null) {
        return '❌ Error: QR no válido o no encontrado en el sistema.';
      }

      // Extraemos datos clave
      final estudianteData = response['estudiantes'];
      final cursoData = response['cursos'];
      final fechaVencimientoStr = response['proximo_pago_vence'];
      final estudianteId = response['estudiante_id'];

      final nombreEstudiante =
          "${estudianteData['nombre']} ${estudianteData['apellido_paterno'] ?? ''}";
      final nombreCurso = cursoData['nombre'];

      // ---------------------------------------------------------
      // PASO 2: VERIFICAR ESTADO DE PAGO (SEMÁFORO)
      // ---------------------------------------------------------
      // Parseamos la fecha de vencimiento (YYYY-MM-DD)
      final fechaVencimiento = DateTime.parse(fechaVencimientoStr);

      // Comparamos solo fechas (sin horas) para ser justos
      final hoy = DateTime(now.year, now.month, now.day);
      final vence = DateTime(
        fechaVencimiento.year,
        fechaVencimiento.month,
        fechaVencimiento.day,
      );

      bool estaAlDia = true;
      String mensajePago = "";

      if (hoy.isAfter(vence)) {
        estaAlDia = false;
        mensajePago = "⚠️ PAGO VENCIDO ($fechaVencimientoStr)";
      }
      final cursoId =
          response['curso_id']; // ID del curso específico de este QR
      // ---------------------------------------------------------
      // PASO 3: VERIFICAR DUPLICADOS (¿Ya entró a ESTE CURSO hoy?)
      // ---------------------------------------------------------
      final List<dynamic> registrosHoy = await supabase
          .from('registros_asistencia')
          .select()
          .eq('estudiante_id', estudianteId)
          .eq('curso_id', cursoId) // <--- Filtro por curso
          .gte('hora_entrada', startOfDay.toUtc().toIso8601String())
          .lt('hora_entrada', endOfDay.toUtc().toIso8601String());

      if (registrosHoy.isNotEmpty) {
        return '⚠️ $nombreEstudiante ya registró asistencia para $nombreCurso hoy.';
      }

      // ---------------------------------------------------------
      // PASO 4: CLASIFICAR SEGÚN HORARIO
      // ---------------------------------------------------------
      final DateTime limiteAsistencia = DateTime(
        now.year,
        now.month,
        now.day,
        horaEntrada,
        minutoEntrada,
      ).add(Duration(minutes: toleranciaMinutos));
      final DateTime limiteRetraso = DateTime(
        now.year,
        now.month,
        now.day,
        horaLimiteRetraso,
        minutoLimiteRetraso,
      );

      String estadoAsistencia;
      if (now.isBefore(limiteAsistencia)) {
        estadoAsistencia = 'Asistencia';
      } else if (now.isBefore(limiteRetraso)) {
        estadoAsistencia = 'Retraso';
      } else {
        estadoAsistencia = 'Falta'; // Marcó muy tarde
      }

      // ---------------------------------------------------------
      // PASO 5: INSERTAR REGISTRO DE ASISTENCIA
      // ---------------------------------------------------------
      await supabase.from('registros_asistencia').insert({
        'estudiante_id': estudianteId,
        'curso_id': cursoId, // <--- Guardamos el ID del curso
        'hora_entrada': now.toUtc().toIso8601String(),
        'estado': estadoAsistencia,
        'pago_al_dia': estaAlDia,
      });

      // Retornar mensaje final
      if (!estaAlDia) {
        // Si debe dinero, retornamos un mensaje de ALERTA aunque se registre la asistencia
        return '🚨 ALERTA: $mensajePago\nEntrada registrada: $nombreEstudiante ($nombreCurso)';
      }

      return '✅ Bienvenido: $nombreEstudiante\n$nombreCurso - $estadoAsistencia';
    } catch (e) {
      return '❌ Error del sistema: $e';
    }
  }
}

final asistenciaProvider =
    StateNotifierProvider<AsistenciaNotifier, AsyncValue<void>>((ref) {
      return AsistenciaNotifier();
    });
