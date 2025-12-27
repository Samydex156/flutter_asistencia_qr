import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estudiante.dart';
import '../main.dart';

class EstudianteNotifier extends StateNotifier<AsyncValue<List<Estudiante>>> {
  EstudianteNotifier() : super(const AsyncValue.loading()) {
    fetchEstudiantes();
  }

  // Ahora solo hacemos GET. Eliminamos addEstudiante()
  Future<void> fetchEstudiantes() async {
    try {
      final response = await supabase
          .from('estudiantes')
          .select()
          .order('nombre', ascending: true); // Orden alfabético

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

  // Función para refrescar manualmente (Pull to refresh)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await fetchEstudiantes();
  }
}

final estudianteProvider =
    StateNotifierProvider<EstudianteNotifier, AsyncValue<List<Estudiante>>>((
      ref,
    ) {
      return EstudianteNotifier();
    });
