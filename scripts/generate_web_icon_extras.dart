import 'dart:io';

import 'package:image/image.dart' as image;

void main() {
  final source = image.decodePng(
    File('assets/branding/bingusfy-dice.png').readAsBytesSync(),
  );
  if (source == null) {
    throw StateError('Não foi possível ler o ícone original.');
  }

  image.Image resize(int size) => image.copyResize(
    source,
    width: size,
    height: size,
    interpolation: image.Interpolation.average,
  );
  File('web/favicon.ico').writeAsBytesSync(
    image.IcoEncoder().encodeImages([
      for (final size in [16, 32, 48, 64, 128, 256]) resize(size),
    ]),
  );
  File(
    'web/apple-touch-icon.png',
  ).writeAsBytesSync(image.encodePng(resize(180)));
}
