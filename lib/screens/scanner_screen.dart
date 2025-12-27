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
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBeep({bool isSuccess = true}) async {
    try {
      // Asegúrate de tener 'assets/sounds/beep.mp3' y 'assets/sounds/error.mp3'
      final String soundFile = isSuccess
          ? 'sounds/beep.mp3'
          : 'sounds/error.mp3';
      await _audioPlayer.play(AssetSource(soundFile));
    } catch (e) {
      debugPrint("Error al reproducir sonido: $e");
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;

        setState(() {
          isProcessing = true;
        });

        // Llamamos al provider que ahora busca en 'inscripciones'
        final String mensaje = await ref
            .read(asistenciaProvider.notifier)
            .registrarAsistencia(code);

        if (!mounted) return;

        // --- LÓGICA DE FEEDBACK VISUAL ---
        Color colorFondo;
        IconData iconoFeedback;
        bool esExitoSonoro = true;

        if (mensaje.contains('🚨') || mensaje.contains('VENCIDO')) {
          // CASO: DEUDA (Rojo Intenso)
          colorFondo = Colors.red.shade800;
          iconoFeedback = Icons.money_off;
          esExitoSonoro = false; // Sonido de error
        } else if (mensaje.contains('❌')) {
          // CASO: ERROR (Rojo)
          colorFondo = Colors.red;
          iconoFeedback = Icons.error_outline;
          esExitoSonoro = false;
        } else if (mensaje.contains('⚠️')) {
          // CASO: ADVERTENCIA (Naranja)
          colorFondo = Colors.orange.shade800;
          iconoFeedback = Icons.warning_amber;
          esExitoSonoro = false;
        } else {
          // CASO: ÉXITO (Verde)
          colorFondo = Colors.green.shade700;
          iconoFeedback = Icons.check_circle_outline;
          esExitoSonoro = true;
        }

        // Feedback Auditivo
        await _playBeep(isSuccess: esExitoSonoro);

        if (!mounted) return;

        // Feedback Visual (SnackBar)
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(iconoFeedback, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mensaje,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: colorFondo,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );

        // Tiempo de espera antes del siguiente escaneo
        await Future.delayed(const Duration(seconds: 3));

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
      appBar: AppBar(title: const Text('Escanear QR')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(controller: controller, onDetect: _onDetect),

                // Marco Visual
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isProcessing
                          ? Colors.white.withValues(alpha: 0.5) // Bloqueado
                          : Colors.transparent,
                      width: 0,
                    ),
                  ),
                ),

                // Overlay de Escaneo (Cuadrado central)
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isProcessing ? Colors.grey : Colors.greenAccent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),

                // Texto superior
                const Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Text(
                    "Enfoque el código QR",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Panel Inferior de Estado
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isProcessing ? Icons.hourglass_top : Icons.qr_code_scanner,
                    size: 40,
                    color: isProcessing ? Colors.grey : Colors.greenAccent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isProcessing ? 'Procesando...' : 'Listo para escanear',
                    style: TextStyle(
                      color: isProcessing ? Colors.grey : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
