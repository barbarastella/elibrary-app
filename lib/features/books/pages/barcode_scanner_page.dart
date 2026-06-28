import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  CameraController? _cameraController;

  final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.ean13],
  );

  bool _isBusy = false;
  bool _isScannerActive = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {});

      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('Erro ao inicializar câmera: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || !_isScannerActive || _cameraController == null) return;
    _isBusy = true;

    try {
      final sensorOrientation = _cameraController!.description.sensorOrientation;
      final InputImageRotation rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
      final InputImageFormat format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      if (image.planes.isEmpty) {
        _isBusy = false;
        return;
      }

      final plane = image.planes.first;

      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );

      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && _isScannerActive) {
        final String? rawValue = barcodes.first.displayValue;
        if (rawValue != null && rawValue.isNotEmpty) {
          _isScannerActive = false;

          await _cameraController?.stopImageStream();

          if (mounted) {
            Navigator.of(context).pop(rawValue);
          }
        }
      }
    } catch (e) {
      debugPrint('Erro no Google ML Kit: $e');
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    _isScannerActive = false;
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color surfaceColor = Color(0xFFF4F4F0);
    const Color accentColor = Color(0xFFFFE800);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: accentColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(color: Colors.black, height: 3.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ESCANEAR ISBN',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Stack(
        children: [
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),

          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(3, 3)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.center_focus_strong, color: Colors.black, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Centralize o código de barras usando a IA do Google.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
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

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);

    final double cutoutWidth = size.width * 0.85;
    final double cutoutHeight = 150;
    final double left = (size.width - cutoutWidth) / 2;
    final double top = (size.height - cutoutHeight) / 2.5;

    final RRect cutout = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cutoutWidth, cutoutHeight),
      const Radius.circular(0),
    );

    final Path backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path cutoutPath = Path()..addRRect(cutout);
    final Path overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(overlayPath, paint);

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRRect(cutout, borderPaint);

    final cornerPaint = Paint()
      ..color = const Color(0xFFFF5900)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    const double cornerLength = 24.0;

    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);
    canvas.drawLine(Offset(left + cutoutWidth, top), Offset(left + cutoutWidth - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + cutoutWidth, top), Offset(left + cutoutWidth, top + cornerLength), cornerPaint);
    canvas.drawLine(Offset(left, top + cutoutHeight), Offset(left + cornerLength, top + cutoutHeight), cornerPaint);
    canvas.drawLine(Offset(left, top + cutoutHeight), Offset(left, top + cutoutHeight - cornerLength), cornerPaint);
    canvas.drawLine(Offset(left + cutoutWidth, top + cutoutHeight), Offset(left + cutoutWidth - cornerLength, top + cutoutHeight), cornerPaint);
    canvas.drawLine(Offset(left + cutoutWidth, top + cutoutHeight), Offset(left + cutoutWidth, top + cutoutHeight - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}