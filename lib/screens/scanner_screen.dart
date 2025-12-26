import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/asistencia_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  // CAMBIO 1: Usamos 'normal' para que detecte siempre, nosotros controlamos el freno.
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back, // O front, según tu preferencia
  );

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isProcessing = false; // Nuestro semáforo

  @override
  void dispose() {
    controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBeep({bool isSuccess = true}) async {
    try {
      final String soundFile = isSuccess
          ? 'sounds/beep.mp3'
          : 'sounds/error.mp3';
      await _audioPlayer.play(AssetSource(soundFile));
    } catch (e) {
      debugPrint("Error al reproducir sonido: $e");
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    // Si el semáforo está en ROJO (true), ignoramos todo lo que vea la cámara
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;

        // 1. Poner semáforo en ROJO
        setState(() {
          isProcessing = true;
        });

        // 2. Procesar
        final String mensaje = await ref
            .read(asistenciaProvider.notifier)
            .registrarAsistencia(code);

        if (!mounted) return;

        final bool esExito = mensaje.contains('✅');
        final color = esExito ? Colors.green : Colors.orange;

        // 3. Feedback inmediato
        await _playBeep(isSuccess: esExito);

        // Check mounted again inside logic if await is used above (it is)
        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje, style: const TextStyle(fontSize: 16)),
            backgroundColor: color,
            duration: const Duration(seconds: 2), // Duración igual al bloqueo
          ),
        );

        // 4. TIEMPO DE ESPERA (El "Respiro" entre estudiantes)
        // Aquí defines qué tan rápido quieres que acepte al siguiente.
        // 2 segundos es ideal para que el alumno escuche el beep y se quite.
        await Future.delayed(const Duration(seconds: 2));

        // 5. Poner semáforo en VERDE (Listo para el siguiente)
        if (mounted) {
          setState(() {
            isProcessing = false;
          });
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Asistencia')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                MobileScanner(controller: controller, onDetect: _onDetect),
                // MARCO VISUAL DE ESTADO
                // Esto te ayudará a saber visualmente si puedes pasar al siguiente
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      // Si está procesando: Naranja grueso. Si está libre: Transparente (o verde suave)
                      color: isProcessing
                          ? Colors.orange.withValues(alpha: 0.8)
                          : Colors.transparent,
                      width: 8,
                    ),
                  ),
                ),
                // Icono central opcional
                Center(
                  child: Opacity(
                    opacity: 0.3,
                    child: Icon(
                      isProcessing
                          ? Icons.hourglass_top
                          : Icons.qr_code_scanner,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              color: isProcessing ? Colors.orange[900] : Colors.black87,
              child: Text(
                isProcessing
                    ? 'Procesando... Espere'
                    : '¡Listo! Siguiente estudiante',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
