import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageService {
  Uint8List processImage(
    Uint8List originalBytes, {
    int maxWidth = 1280,
    int quality = 80,
  }) {
    final image = img.decodeImage(originalBytes);

    if (image == null) {
      throw Exception('Não foi possível decodificar a imagem.');
    }

    img.Image processedImage = image;

    // Só redimensiona se a imagem ultrapassar 1280 pixels de largura.
    if (image.width > maxWidth) {
      processedImage = img.copyResize(
        image,
        width: maxWidth,
      );
    }

    // Converte novamente para JPEG com qualidade 80.
    final jpegBytes = img.encodeJpg(
      processedImage,
      quality: quality,
    );

    return Uint8List.fromList(jpegBytes);
  }
}