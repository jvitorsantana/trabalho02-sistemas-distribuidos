import 'dart:typed_data';

import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  Future<void> initialize() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('Nenhuma câmera encontrada.');
    }

    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
  }

  Future<Uint8List> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw StateError('A câmera não foi inicializada.');
    }

    if (_controller!.value.isTakingPicture) {
      throw StateError('Uma foto já está sendo capturada.');
    }

    final XFile photo = await _controller!.takePicture();

    return await photo.readAsBytes();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}