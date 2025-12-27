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
        title: const Text('Historial de Ingresos'),
        actions: [
          IconButton(
            tooltip: 'Reporte de Hoy (con Faltas)',
            icon: const Icon(Icons.today),
            onPressed: () =>
                ref.read(reportesProvider.notifier).cargarReporteHoyConFaltas(),
          ),
          IconButton(
            tooltip: 'Todo el Historial',
            icon: const Icon(Icons.history),
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
                'dd/MM - HH:mm',
              ).format(reporte.fechaHora);

              // Color del icono izquierdo (Asistencia/Retraso/Falta/Inasistencia)
              Color colorEstado = Colors.blue;
              IconData iconoEstado = Icons.access_time;

              if (reporte.estado == 'Asistencia') {
                colorEstado = Colors.green;
                iconoEstado = Icons.check_circle;
              } else if (reporte.estado == 'Retraso') {
                colorEstado = Colors.orange;
                iconoEstado = Icons.history;
              } else if (reporte.estado == 'Falta') {
                colorEstado = Colors.redAccent;
                iconoEstado = Icons.timer_off;
              } else if (reporte.estado == 'Inasistencia') {
                colorEstado = Colors.grey;
                iconoEstado = Icons.person_off;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorEstado.withValues(alpha: 0.1),
                    child: Icon(iconoEstado, color: colorEstado),
                  ),
                  title: Text(
                    reporte.nombreCompleto,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reporte.nombreCurso,
                        style: TextStyle(
                          color: Colors.blueGrey.shade700,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            fechaFormato,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          if (!reporte.pagoAlDia)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "DEUDA",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
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
        label: const Text('CSV'),
        icon: const Icon(Icons.download),
        backgroundColor: Colors.green[700],
      ),
    );
  }
}
