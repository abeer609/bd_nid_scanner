import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:playground/components/scanner_error_widget.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class BarcodeScannerWithController extends StatefulWidget {
  final WebSocketChannel socket;
  const BarcodeScannerWithController({super.key, required this.socket});

  @override
  State<BarcodeScannerWithController> createState() =>
      _BarcodeScannerWithControllerState();
}

class _BarcodeScannerWithControllerState
    extends State<BarcodeScannerWithController>
    with SingleTickerProviderStateMixin {
  final player = AudioPlayer();
  @override
  void dispose() {
    controller.stop();
    widget.socket.sink.close();
    super.dispose();
  }

  BarcodeCapture? barcode;
  bool isStarted = true;

  final MobileScannerController controller = MobileScannerController(
      torchEnabled: false,
      useNewCameraSelector: true,
      formats: [BarcodeFormat.pdf417],
      autoStart: true,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 2000,
      cameraResolution: const Size(3840, 2160));

  void _startOrStop() {
    try {
      if (isStarted) {
        controller.stop();
      } else {
        controller.start();
      }
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong! $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() {
      isStarted = !isStarted;
    });
  }

  int? numberOfCameras;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onScannerStarted: (arguments) {
              if (mounted && arguments?.numberOfCameras != null) {
                numberOfCameras = arguments!.numberOfCameras;
                setState(() {});
              }
            },
            controller: controller,
            errorBuilder: (context, error, child) {
              return ScannerErrorWidget(error: error);
            },
            fit: BoxFit.contain,
            onDetect: (barcode) {
              setState(() {
                this.barcode = barcode;
              });
              player.play(AssetSource('beep.mp3'));
              controller.stop();
              setState(() {
                isStarted = false;
              });

              widget.socket.sink.add(barcode.barcodes.first.rawValue);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: Colors.black.withOpacity(0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ValueListenableBuilder(
                    valueListenable: controller.hasTorchState,
                    builder: (context, state, child) {
                      if (state != true) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        color: Colors.white,
                        icon: ValueListenableBuilder<TorchState>(
                          valueListenable: controller.torchState,
                          builder: (context, state, child) {
                            switch (state) {
                              case TorchState.off:
                                return const Icon(
                                  Icons.flash_off,
                                  color: Colors.grey,
                                );
                              case TorchState.on:
                                return const Icon(
                                  Icons.flash_on,
                                  color: Colors.yellow,
                                );
                            }
                          },
                        ),
                        iconSize: 32.0,
                        onPressed: () => controller.toggleTorch(),
                      );
                    },
                  ),
                  IconButton(
                      color: Colors.white,
                      icon: isStarted
                          ? const Icon(Icons.stop)
                          : const Icon(Icons.play_arrow),
                      iconSize: 32.0,
                      onPressed: () {
                        _startOrStop();
                      }),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 200,
                      height: 50,
                      child: FittedBox(
                        child: Text(
                          barcode?.barcodes.first.rawValue ?? 'Scan something!',
                          overflow: TextOverflow.fade,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: ValueListenableBuilder<CameraFacing>(
                      valueListenable: controller.cameraFacingState,
                      builder: (context, state, child) {
                        switch (state) {
                          case CameraFacing.front:
                            return const Icon(Icons.camera_front);
                          case CameraFacing.back:
                            return const Icon(Icons.camera_rear);
                        }
                      },
                    ),
                    iconSize: 32.0,
                    onPressed: (numberOfCameras ?? 0) < 2
                        ? null
                        : () => controller.switchCamera(),
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.image),
                    iconSize: 32.0,
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      // Pick an image
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        if (await controller.analyzeImage(image.path)) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Barcode found!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No barcode found!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
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
