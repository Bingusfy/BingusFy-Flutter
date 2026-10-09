import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Slow sound waves with a simulated rhythm, drawn directly by Flutter.
class MusicalWavesBackground extends StatefulWidget {
  const MusicalWavesBackground({super.key});

  @override
  State<MusicalWavesBackground> createState() => _MusicalWavesBackgroundState();
}

class _MusicalWavesBackgroundState extends State<MusicalWavesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final nativeMobile =
                !kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.android);
            if (!nativeMobile) {
              return CustomPaint(
                painter: _MusicalWavesPainter(_motion),
                child: const SizedBox.expand(),
              );
            }
            // A phone is a window onto the same large waves. Crop the artwork
            // instead of squeezing its wavelength into the viewport.
            final width = math.max(1440.0, constraints.maxWidth);
            final height = math.max(900.0, constraints.maxHeight);
            return ClipRect(
              child: OverflowBox(
                minWidth: width,
                maxWidth: width,
                minHeight: height,
                maxHeight: height,
                child: CustomPaint(
                  painter: _MusicalWavesPainter(_motion),
                  child: SizedBox(width: width, height: height),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MusicalWavesPainter extends CustomPainter {
  _MusicalWavesPainter(this.motion) : super(repaint: motion);

  final Animation<double> motion;
  static const _green = Color(0xFF1ED760);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;

    // A broad glow adds depth while the crisp curves suggest an audio signal.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.15),
          radius: 0.85,
          colors: [Color(0x181ED760), Color(0x001ED760)],
        ).createShader(bounds),
    );

    final phase = motion.value * math.pi * 2;
    // 28 soft accents per 24-second cycle = 70 simulated beats per minute.
    final beat = math.pow(0.5 + 0.5 * math.cos(phase * 28), 3).toDouble();
    final swell = 0.9 + 0.07 * math.sin(phase * 2) + 0.03 * beat;
    final amplitude = math.min(size.height * 0.16, 135.0) * swell;
    final spacing = math.min(size.height * 0.025, 22.0);
    final segments = (size.width / 6).ceil().clamp(80, 360);

    canvas.save();
    canvas.clipRect(bounds);
    for (var line = 0; line < 9; line++) {
      final path = Path();
      final layer = line - 4;
      final offset = layer * spacing;
      for (var step = 0; step <= segments; step++) {
        final u = step / segments;
        // The signal grows at the sides and calms down behind the login card.
        final side = math.pow((u * 2 - 1).abs(), 0.8).toDouble();
        final envelope = 0.25 + 0.75 * side;
        final wave =
            math.sin(u * math.pi * 3.5 - phase + layer * 0.24) * 0.65 +
            math.sin(u * math.pi * 6 + phase * 2 + layer * 0.15) * 0.25 +
            math.sin(u * math.pi * 2 - phase * 3) * 0.1;
        final x = u * size.width;
        final y = size.height * 0.56 + offset + wave * amplitude * envelope;
        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final strength = 1 - layer.abs() / 7;
      final shader = LinearGradient(
        colors: [
          _green.withValues(alpha: 0.4 * strength),
          _green.withValues(alpha: 0.09 * strength),
          _green.withValues(alpha: 0.035 * strength),
          _green.withValues(alpha: 0.09 * strength),
          _green.withValues(alpha: 0.4 * strength),
        ],
        stops: const [0, 0.3, 0.5, 0.7, 1],
      ).createShader(bounds);

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = line == 4 ? 1.6 : 1
          ..strokeCap = StrokeCap.round
          ..shader = shader,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MusicalWavesPainter oldDelegate) =>
      oldDelegate.motion != motion;
}
