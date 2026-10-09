import 'package:flutter/material.dart';

/// The custom element runs the original fluid solver without a React runtime.
/// The simulation moves autonomously with a simulated musical rhythm. DOM
/// pointer-events are disabled so Flutter controls buttons and scrolling.
class LiquidEtherBackground extends StatelessWidget {
  const LiquidEtherBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: HtmlElementView.fromTagName(tagName: 'bingus-liquid-ether'),
    );
  }
}
