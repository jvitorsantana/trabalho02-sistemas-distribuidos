import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/camera_service.dart';
import '../services/image_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CameraService _cameraService = CameraService();
  final ImageService _imageService = ImageService();

  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _takePicture() async {
    try {
      // Captura a imagem e obtém os bytes do JPEG original.
      final Uint8List originalBytes =
          await _cameraService.takePicture();

      // Redimensiona e comprime a imagem conforme os requisitos.
      final Uint8List processedBytes =
          _imageService.processImage(originalBytes);

      debugPrint(
        'Imagem original: ${originalBytes.length} bytes',
      );

      debugPrint(
        'Imagem processada: ${processedBytes.length} bytes',
      );
    } catch (e) {
      debugPrint('Erro ao tirar/processar foto: $e');
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detector de Objetos'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erro ao inicializar câmera:\n$_error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector de Objetos'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(
              _cameraService.controller!,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: FloatingActionButton(
                onPressed: _takePicture,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
