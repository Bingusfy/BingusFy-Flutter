import 'package:flutter/material.dart';

/// Static fallback for platforms without browser WebGL.
class LiquidEtherBackground extends StatelessWidget {
  const LiquidEtherBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, 0.5),
          radius: 1.2,
          colors: [Color(0xFF103F23), Color(0xFF0A0A0A)],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}
