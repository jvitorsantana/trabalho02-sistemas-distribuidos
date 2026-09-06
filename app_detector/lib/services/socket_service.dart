
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class SocketService {
  Socket? _socket;

  // Buffer que armazena os bytes recebidos pelo TCP.
  final BytesBuilder _receiveBuffer = BytesBuilder();

  // Usado para avisar que chegaram novos dados.
  Completer<void>? _dataAvailable;

  // Indica se a conexão foi encerrada.
  bool _connectionClosed = false;

  // Conecta ao servidor Python.
  Future<void> connect({
    required String host,
    required int port,
  }) async {
    if (_socket != null) {
      throw StateError('O socket já está conectado.');
    }

    _socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 5),
    );

    _connectionClosed = false;
    _receiveBuffer.clear();

    // Começamos a escutar os dados recebidos.
    _socket!.listen(
      (data) {
        _receiveBuffer.add(data);

        // Avisa quem estiver esperando novos dados.
        _dataAvailable?.complete();
        _dataAvailable = null;
      },
      onError: (Object error) {
        _connectionClosed = true;

        _dataAvailable?.completeError(error);
        _dataAvailable = null;
      },
      onDone: () {
        _connectionClosed = true;

        _dataAvailable?.complete();
        _dataAvailable = null;
      },
      cancelOnError: false,
    );
  }

  // Envia um frame no formato:
  //
  // [4 bytes do tamanho][payload]
  //
  // Equivalente ao send_frame() do Python.
  Future<void> sendFrame(Uint8List payload) async {
    final socket = _socket;

    if (socket == null) {
      throw StateError('Socket não conectado.');
    }

    if (_connectionClosed) {
      throw const SocketException(
        'A conexão com o servidor foi encerrada.',
      );
    }

    if (payload.isEmpty) {
      throw ArgumentError('O payload não pode estar vazio.');
    }

    const maxPayloadSize = 32 * 1024 * 1024;

    if (payload.length > maxPayloadSize) {
      throw ArgumentError(
        'Payload muito grande: ${payload.length} bytes.',
      );
    }

    // Criamos os 4 bytes do tamanho.
    //
    // Python:
    // struct.pack('!I', len(payload))
    //
    // Dart:
    // Uint32 + Big Endian
    final header = ByteData(4);

    header.setUint32(
      0,
      payload.length,
      Endian.big,
    );

    // Envia primeiro o tamanho.
    socket.add(header.buffer.asUint8List());

    // Depois envia os bytes do payload.
    socket.add(payload);

    await socket.flush();
  }

  // Recebe um frame no formato:
  //
  // [4 bytes do tamanho][payload]
  //
  // Equivalente ao read_frame() do Python.
  Future<Uint8List> receiveFrame() async {
    final header = await _readExactly(4);

    final headerData = ByteData.sublistView(header);

    final size = headerData.getUint32(
      0,
      Endian.big,
    );

    const maxPayloadSize = 32 * 1024 * 1024;

    if (size == 0 || size > maxPayloadSize) {
      throw FormatException(
        'Tamanho de payload inválido: $size bytes.',
      );
    }

    return await _readExactly(size);
  }

  // Lê exatamente 'size' bytes.
  //
  // O TCP pode entregar:
  //
  // 2 bytes
  // depois 2 bytes
  // depois 500 bytes
  //
  // etc.
  //
  // Este método junta tudo até possuir exatamente a
  // quantidade solicitada.
  Future<Uint8List> _readExactly(int size) async {
    while (_receiveBuffer.length < size) {
      if (_connectionClosed) {
        throw const SocketException(
          'Conexão encerrada antes de receber todos os dados.',
        );
      }

      _dataAvailable = Completer<void>();

      await _dataAvailable!.future;
    }

    final allBytes = _receiveBuffer.takeBytes();

    final requestedBytes = Uint8List.fromList(
      allBytes.sublist(0, size),
    );

    // Se recebemos bytes além dos solicitados,
    // devolvemos o restante para o buffer.
    if (allBytes.length > size) {
      _receiveBuffer.add(
        allBytes.sublist(size),
      );
    }

    return requestedBytes;
  }

  // Fecha a conexão.
  Future<void> disconnect() async {
    final socket = _socket;

    _socket = null;
    _connectionClosed = true;
    _receiveBuffer.clear();

    _dataAvailable?.complete();
    _dataAvailable = null;

    await socket?.close();
  }
}
