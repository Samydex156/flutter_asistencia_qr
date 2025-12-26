// lib/providers/asistencia_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart'; // Para acceder a la variable 'supabase'
import '../models/estudiante.dart';

// Configuración: Hora límite para considerar "Retraso" (Ej: 8:30 AM)
const int horaLimite = 8;
const int minutoLimite = 30;

class AsistenciaNotifier extends StateNotifier<AsyncValue<void>> {
  AsistenciaNotifier() : super(const AsyncValue.data(null));

  // Función principal: Recibe el String del QR (ej: "JPR-Ofi-1") y registra
  Future<String> registrarAsistencia(String qrScannedData) async {
    final now = DateTime.now();

    // Definimos el inicio y fin del día actual (Local) para verificar duplicados
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      // 1. BUSCAR ESTUDIANTE POR SU CÓDIGO QR (Texto)
      final Map<String, dynamic>? estudianteData = await supabase
          .from('estudiantes')
          .select()
          .eq('codigo_qr_data', qrScannedData)
          .maybeSingle();

      if (estudianteData == null) {
        return '❌ Error: Código QR no válido o estudiante no encontrado.';
      }

      final estudiante = Estudiante.fromJson(estudianteData);

      // 2. VERIFICAR DUPLICADOS (¿Ya vino hoy?)
      // Convertimos a UTC porque Supabase/Postgres almacena en UTC (timestamptz)
      final List<dynamic> registrosHoy = await supabase
          .from('registros_asistencia')
          .select()
          .eq('estudiante_id', estudiante.id)
          .gte('hora_entrada', startOfDay.toUtc().toIso8601String())
          .lt('hora_entrada', endOfDay.toUtc().toIso8601String());

      if (registrosHoy.isNotEmpty) {
        return '⚠️ Advertencia: ${estudiante.nombre} ya tiene asistencia registrada hoy.';
      }

      // 3. CALCULAR ESTADO (A tiempo vs Tarde)
      // La comparación de hora límite se hace en local, que es lo correcto para la lógica de negocio "8:30 AM"
      final limite = DateTime(
        now.year,
        now.month,
        now.day,
        horaLimite,
        minutoLimite,
      );
      final estado = now.isAfter(limite) ? 'Retraso' : 'Asistencia';

      // 4. INSERTAR REGISTRO (Guardamos en UTC)
      await supabase.from('registros_asistencia').insert({
        'estudiante_id': estudiante.id,
        'hora_entrada': now.toUtc().toIso8601String(),
        'estado': estado,
      });

      return '✅ ${estudiante.nombre} registrado ($estado) - ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '❌ Error del sistema: $e';
    }
  }
}

// Provider global
final asistenciaProvider =
    StateNotifierProvider<AsistenciaNotifier, AsyncValue<void>>((ref) {
      return AsistenciaNotifier();
    });
