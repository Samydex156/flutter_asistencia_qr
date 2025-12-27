import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/estudiante_provider.dart';

class EstudiantesScreen extends ConsumerWidget {
  const EstudiantesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estudiantesAsync = ref.watch(estudianteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio Estudiantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(estudianteProvider.notifier).refresh(),
          ),
        ],
      ),
      body: estudiantesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (estudiantes) {
          if (estudiantes.isEmpty) {
            return const Center(child: Text('No hay estudiantes registrados.'));
          }
          return ListView.separated(
            itemCount: estudiantes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final estudiante = estudiantes[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(estudiante.nombre[0].toUpperCase()),
                ),
                title: Text(estudiante.nombreCompleto),
                subtitle: Text('CI: ${estudiante.ci ?? "No registrado"}'),
                // Ya no mostramos QR aquí porque depende del curso activo
                // Si quisieras mostrar el curso activo, requeriría otra consulta
                // o un cambio en el provider 'fetchEstudiantes' para hacer join.
              );
            },
          );
        },
      ),
      // Eliminamos el FloatingActionButton de agregar estudiante
    );
  }
}
