import 'package:flutter/widgets.dart';
import 'entrance_fade.dart';

class BingusBrandMark extends StatelessWidget {
  const BingusBrandMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/bingusfy-dice.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    frameBuilder: fadeImageFrame,
    filterQuality: FilterQuality.high,
    semanticLabel: 'Ícone do BingusFy',
  );
}
