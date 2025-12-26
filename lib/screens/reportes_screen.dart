// lib/screens/reportes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/reportes_provider.dart';

class ReportesScreen extends ConsumerWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(reportesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial y Reportes'),
        actions: [
          // Botón de recargar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(reportesProvider.notifier).cargarHistorial(),
          ),
        ],
      ),
      body: historialAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (reportes) {
          if (reportes.isEmpty) {
            return const Center(
              child: Text('No hay registros de asistencia aún.'),
            );
          }

          return ListView.builder(
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final reporte = reportes[index];
              final fechaFormato = DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(reporte.fechaHora);

              // Color según estado
              Color colorEstado = Colors.green;
              if (reporte.estado == 'Retraso') colorEstado = Colors.orange;
              if (reporte.estado == 'Falta') colorEstado = Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorEstado,
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  title: Text(
                    reporte.nombreEstudiante,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${reporte.clase} - $fechaFormato'),
                  trailing: Text(
                    reporte.estado,
                    style: TextStyle(
                      color: colorEstado,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Acción de exportar
          try {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Generando CSV...')));
            await ref.read(reportesProvider.notifier).exportarReporte();
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        label: const Text('Exportar CSV'),
        icon: const Icon(Icons.download),
        backgroundColor: Colors.green[700],
      ),
    );
  }
}
