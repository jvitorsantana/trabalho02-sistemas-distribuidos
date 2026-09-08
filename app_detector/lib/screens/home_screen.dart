import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/detection_result.dart';
import '../services/camera_service.dart';
import '../services/image_service.dart';
import '../services/socket_service.dart';
import '../widgets/server_settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CameraService _cameraService = CameraService();
  final ImageService _imageService = ImageService();

  bool _isInitialized = false;
  bool _isProcessing = false;

  String? _error;
  String? _photoPath;

  DetectionResult? _result;

  // Configuração padrão.
  //
  // Para o Android Emulator, 10.0.2.2 representa
  // o computador onde o emulador está executando.
  String _serverHost = '10.0.2.2';
  int _serverPort = 25565;

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
    if (_isProcessing) return;

    try {
      setState(() {
        _error = null;
        _result = null;
        _isProcessing = true;
      });

      // 1. Captura a foto.
      final XFile photo = await _cameraService.takePicture();

      if (!mounted) return;

      // Mostra imediatamente a foto tirada.
      setState(() {
        _photoPath = photo.path;
      });

      // 2. Lê os bytes da imagem.
      final Uint8List originalBytes = await photo.readAsBytes();

      // 3. Redimensiona e comprime.
      final Uint8List processedBytes =
          _imageService.processImage(originalBytes);

      debugPrint(
        'Imagem original: ${originalBytes.length} bytes',
      );

      debugPrint(
        'Imagem processada: ${processedBytes.length} bytes',
      );

      // 4. Cria o socket.
      final socketService = SocketService();

      try {
        // 5. Conecta ao servidor.
        debugPrint(
          'Conectando em $_serverHost:$_serverPort...',
        );

        await socketService.connect(
          host: _serverHost,
          port: _serverPort,
        );

        debugPrint('Conectado ao servidor.');

        // 6. Envia a imagem.
        await socketService.sendFrame(processedBytes);

        debugPrint('Imagem enviada.');

        // 7. Aguarda a resposta do servidor.
        final responseBytes =
            await socketService.receiveFrame();

        // 8. Converte os bytes para texto UTF-8.
        final responseJson =
            jsonDecode(utf8.decode(responseBytes));

        // 9. Converte o JSON para nosso modelo.
        final result = DetectionResult.fromJson(
          Map<String, dynamic>.from(responseJson),
        );

        debugPrint(
          'Resposta recebida: ${result.message}',
        );

        if (!mounted) return;

        setState(() {
          _result = result;
          _isProcessing = false;
        });
      } finally {
        await socketService.disconnect();
      }
    } catch (e) {
      debugPrint('Erro: $e');

      if (!mounted) return;

      setState(() {
        _error = _friendlyError(e);
        _isProcessing = false;
      });
    }
  }

  String _friendlyError(Object error) {
    if (error is SocketException) {
      return 'Não foi possível conectar ao servidor.\n'
          'Verifique o IP, a porta e se o servidor Python está executando.';
    }

    if (error is TimeoutException) {
      return 'Tempo limite ao conectar ao servidor.';
    }

    if (error is FormatException) {
      return 'O servidor enviou uma resposta inválida.';
    }

    return error.toString();
  }

  Future<void> _showServerSettings() async {
    final settings = await showDialog<ServerSettings>(
      context: context,
      builder: (context) {
        return ServerSettingsDialog(
          initialHost: _serverHost,
          initialPort: _serverPort,
        );
      },
    );

    if (settings == null || !mounted) {
      return;
    }

    setState(() {
      _serverHost = settings.host;
      _serverPort = settings.port;
    });
  }

  void _resetProcess() {
    setState(() {
      _photoPath = null;
      _result = null;
      _error = null;
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && !_isProcessing && _photoPath == null) {
      return _buildErrorScreen();
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
        actions: [
          IconButton(
            onPressed: _isProcessing
                ? null
                : _showServerSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Configurar servidor',
          ),
        ],
      ),

      body: Column(
        children: [
          // Exibe IP e porta atuais.
          _buildServerInfo(),

          Expanded(
            child: _photoPath == null
                ? _buildCameraView()
                : _buildPhotoResultView(),
          ),
        ],
      ),
    );
  }

  Widget _buildServerInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.dns, size: 20),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              'Servidor: $_serverHost:$_serverPort',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          TextButton.icon(
            onPressed: _isProcessing
                ? null
                : _showServerSettings,
            icon: const Icon(Icons.edit),
            label: const Text('Alterar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
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
            child: FloatingActionButton.large(
              onPressed:
                  _isProcessing ? null : _takePicture,
              child: const Icon(
                Icons.camera_alt,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoResultView() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Image.file(
                  File(_photoPath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),

        Expanded(
          flex: 4,
          child: _buildResultPanel(),
        ),
      ],
    );
  }

  Widget _buildResultPanel() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),

            SizedBox(height: 16),

            Text(
              'Analisando imagem...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Aguardando resposta do servidor',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),

            const SizedBox(height: 12),

            Text(
              _error!,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _resetProcess,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_result == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultado da análise',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _result!.summary.isEmpty
                ? const Center(
                    child: Text(
                      'Nada detectado',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _result!.summary.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(
                          Icons.check_circle_outline,
                        ),
                        title: Text(
                          _result!.summary[index],
                        ),
                        dense: true,
                      );
                    },
                  ),
          ),

          Text(
            'Tempo de processamento: '
            '${_result!.elapsedMs} ms',
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _resetProcess,
              icon: const Icon(Icons.refresh),
              label: const Text('Repetir processo'),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector de Objetos'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
              ),

              const SizedBox(height: 16),

              Text(
                'Erro ao inicializar a câmera',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                _error ?? 'Erro desconhecido.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              FilledButton(
                onPressed: _initializeCamera,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
