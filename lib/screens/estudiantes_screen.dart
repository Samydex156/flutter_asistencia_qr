// lib/screens/estudiantes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Para mostrar el QR
import '../models/estudiante.dart';
import '../providers/estudiante_provider.dart';

class EstudiantesScreen extends ConsumerWidget {
  const EstudiantesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha el estado del provider
    final estudiantesAsync = ref.watch(estudianteProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Estudiantes')),
      body: estudiantesAsync.when(
        // Cuando los datos están cargando
        loading: () => const Center(child: CircularProgressIndicator()),

        // Cuando hay un error
        error: (error, stack) =>
            Center(child: Text('Error: ${error.toString()}')),

        // Cuando los datos están disponibles (Success)
        data: (estudiantes) {
          return ListView.builder(
            itemCount: estudiantes.length,
            itemBuilder: (context, index) {
              final estudiante = estudiantes[index];
              return ListTile(
                leading: Text(estudiante.id.toString()), // Muestra el ID
                title: Text(estudiante.nombre),
                subtitle: Text(
                  'Clase: ${estudiante.clase} - QR: ${estudiante.codigoQrData ?? 'N/A'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.qr_code_2),
                  onPressed: () => _showQrDialog(context, estudiante),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentDialog(context, ref),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  // Diálogo para mostrar el Código QR
  void _showQrDialog(BuildContext context, Estudiante estudiante) {
    final qrData = estudiante.codigoQrData;
    if (qrData == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('QR de ${estudiante.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Generador de QR
              QrImageView(data: qrData, version: QrVersions.auto, size: 200.0),
              const SizedBox(height: 10),
              Text('Código de Escaneo: $qrData'),
              Text('Clase: ${estudiante.clase}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo para agregar un nuevo estudiante
  void _showAddStudentDialog(BuildContext context, WidgetRef ref) {
    final nombreController = TextEditingController();
    final claseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Nuevo Estudiante'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
              ),
              TextField(
                controller: claseController,
                decoration: const InputDecoration(labelText: 'Clase/Grupo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isNotEmpty &&
                    claseController.text.isNotEmpty) {
                  try {
                    await ref
                        .read(estudianteProvider.notifier)
                        .addEstudiante(
                          nombreController.text,
                          claseController.text,
                        );
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  } catch (e) {
                    if (!context.mounted) return;
                    // Mostrar error si la inserción falla
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fallo al agregar estudiante: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
