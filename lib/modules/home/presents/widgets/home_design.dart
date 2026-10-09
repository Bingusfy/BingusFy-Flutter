import 'dart:math' as math;

import 'package:flutter/material.dart';

export 'package:bingo/global/widgets/bingus_brand_mark.dart';

class HomeDesign {
  static const green = Color(0xFF1ED760);
  static const muted = Color(0xFF96A39A);

  static BoxDecoration surface({bool highlighted = false}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: highlighted
          ? const [Color(0xFF15281C), Color(0xFF101712), Color(0xFF101411)]
          : const [Color(0xFF171D19), Color(0xFF111612)],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: highlighted ? const Color(0x401ED760) : const Color(0x18FFFFFF),
    ),
    boxShadow: const [
      BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
  );
}

class HomeIntro extends StatelessWidget {
  const HomeIntro({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 640;
      return Padding(
        padding: EdgeInsets.only(
          top: compact ? 8 : 4,
          bottom: compact ? 24 : 32,
        ),
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            if (constraints.maxWidth > 1000)
              const Positioned(
                right: 24,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 420,
                  child: CustomPaint(painter: _IntroWaves()),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.album_outlined,
                      color: HomeDesign.green,
                      size: 14,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'MÚSICA. AMIGOS. BINGO.',
                      style: TextStyle(
                        color: HomeDesign.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Dê o play no seu bingo.',
                  style: TextStyle(
                    fontSize: compact ? 30 : 42,
                    height: 1.15,
                    letterSpacing: -1.4,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF1F5F2),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sua fila vira o jogo. Escolha os artistas e crie suas tabelas.',
                  style: TextStyle(
                    color: HomeDesign.muted,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _IntroWaves extends CustomPainter {
  const _IntroWaves();

  @override
  void paint(Canvas canvas, Size size) {
    for (var line = 0; line < 6; line++) {
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 2) {
        final envelope = math.sin(math.pi * x / size.width);
        final y =
            size.height / 2 +
            math.sin(x / 48 + line * .45) * envelope * (18 + line * 5);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = HomeDesign.green.withValues(alpha: .08 + line * .025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IntroWaves oldDelegate) => false;
}
