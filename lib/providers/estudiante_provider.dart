// lib/providers/estudiante_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estudiante.dart';
import '../main.dart'; // Importamos 'supabase' del main.dart

// ----------------------------------------------------
// 1. Definiendo el Notifier para gestionar el estado
// ----------------------------------------------------

class EstudianteNotifier extends StateNotifier<AsyncValue<List<Estudiante>>> {
  EstudianteNotifier() : super(const AsyncValue.loading()) {
    fetchEstudiantes(); // Cargar datos al inicializar
  }

  // Obtener todos los estudiantes desde Supabase
  Future<void> fetchEstudiantes() async {
    try {
      final response = await supabase
          .from('estudiantes')
          .select()
          .order('id', ascending: true);

      final List<Estudiante> estudiantes = (response as List)
          .map((item) => Estudiante.fromJson(item))
          .toList();

      state = AsyncValue.data(estudiantes);
    } catch (error) {
      state = AsyncValue.error(
        'Error al cargar estudiantes: $error',
        StackTrace.current,
      );
    }
  }

  // ----------------------------------------------------
  // 2. Función clave: Agregar Estudiante (con lógica QR)
  // ----------------------------------------------------

  // lib/providers/estudiante_provider.dart

  // ... (inicio de la clase EstudianteNotifier) ...

  Future<void> addEstudiante(String nombre, String clase) async {
    try {
      // 1. Intentar insertar el nuevo estudiante SIN el código QR data
      final Map<String, dynamic> response = await supabase
          .from('estudiantes')
          .insert({'nombre': nombre, 'clase': clase})
          .select() // Solicitamos que devuelva la fila insertada
          .single(); // Devuelve un solo mapa, NO una lista

      // Ahora procesamos la respuesta directamente
      final Estudiante nuevoEstudianteSinQR = Estudiante.fromJson(response);
      final int nuevoId = nuevoEstudianteSinQR.id;

      // GENERACIÓN PERSONALIZADA DEL QR: [Iniciales]-[Curso]-[ID]
      // Ej: Juan Perez Ramires, Ofimatica, ID 1 -> JPR-Ofi-1
      final String qrData = _generateCustomQrCode(nombre, clase, nuevoId);

      // 2. Actualizar la misma fila para añadir el codigo_qr_data
      await supabase
          .from('estudiantes')
          .update({'codigo_qr_data': qrData})
          .eq('id', nuevoId);

      // 3. Actualizar el estado local (para reflejar el cambio en la UI)
      final Estudiante estudianteCompleto = Estudiante(
        id: nuevoId,
        nombre: nombre,
        clase: clase,
        codigoQrData: qrData,
      );

      final currentData = state.value ?? [];
      state = AsyncValue.data([...currentData, estudianteCompleto]);
    } on PostgrestException catch (e) {
      // Manejo específico de errores de Supabase
      state = AsyncValue.error(
        'Error al agregar: ${e.message}',
        StackTrace.current,
      );
      rethrow;
    } catch (error) {
      state = AsyncValue.error(
        'Error desconocido al agregar: $error',
        StackTrace.current,
      );
      rethrow;
    }
  }

  // Método auxiliar para generar el formato JPR-Ofi-1
  String _generateCustomQrCode(String nombre, String clase, int id) {
    // 1. Iniciales del Nombre
    // trim() limpia espacios, split(' ') divide por palabras
    final nameParts = nombre.trim().split(RegExp(r'\s+'));
    final nameInitials = nameParts
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .join();

    // 2. Código del Curso/Clase
    final classParts = clase.trim().split(RegExp(r'\s+'));
    String classCode = '';

    if (classParts.length == 1) {
      // Si es una sola palabra, intentamos tomar las primeras 3 letras
      // Ej: Ofimatica -> Ofi. Si es muy corta (Ej: IA), se queda como IA.
      final word = classParts[0];
      if (word.length >= 3) {
        // Primera mayúscula, resto minúscula para 'Ofi'
        classCode = word.substring(0, 3);
        classCode =
            classCode[0].toUpperCase() + classCode.substring(1).toLowerCase();
      } else {
        classCode = word.toUpperCase();
      }
    } else {
      // Si son varias palabras, tomamos iniciales (Ej: Base de Datos -> BD)
      classCode = classParts
          .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
          .join();
    }

    // 3. Retornar formato final
    return '$nameInitials-$classCode-$id';
  }

  // ...
}

// ----------------------------------------------------
// 3. El Global Provider (para accederlo desde los Widgets)
// ----------------------------------------------------

final estudianteProvider =
    StateNotifierProvider<EstudianteNotifier, AsyncValue<List<Estudiante>>>((
      ref,
    ) {
      return EstudianteNotifier();
    });
