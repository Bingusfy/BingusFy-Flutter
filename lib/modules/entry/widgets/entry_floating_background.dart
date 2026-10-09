import 'package:flutter/material.dart';
import 'package:bingo/global/widgets/entrance_fade.dart';

class EntryFloatingBackground extends StatefulWidget {
  const EntryFloatingBackground({
    super.key,
    required this.assetPath,
    this.lowerLeft = false,
  });

  final String assetPath;
  final bool lowerLeft;

  @override
  State<EntryFloatingBackground> createState() =>
      _EntryFloatingBackgroundState();
}

class _EntryFloatingBackgroundState extends State<EntryFloatingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    value: .5,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = .5;
    } else if (!_motion.isAnimating) {
      _motion.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final originalSize = compact
              ? (constraints.biggest.shortestSide * .60).clamp(150.0, 280.0)
              : (constraints.biggest.shortestSide * .65).clamp(200.0, 580.0);
          final size = originalSize * .9;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: widget.lowerLeft ? null : (compact ? 60 : -60),
                right: widget.lowerLeft ? null : (compact ? -70 : -85),
                bottom: widget.lowerLeft ? (compact ? -45 : -70) : null,
                left: widget.lowerLeft ? (compact ? -55 : -60) : null,
                width: size,
                height: size,
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      0,
                      (Curves.easeInOutSine.transform(_motion.value) * 2 - 1) *
                          (compact ? 6 : 10),
                    ),
                    child: child,
                  ),
                  child: RepaintBoundary(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          colors: [Color(0x101ED760), Color(0x001ED760)],
                          stops: [.2, 1],
                        ),
                      ),
                      child: Transform.rotate(
                        angle: widget.lowerLeft ? .16 : -.16,
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (bounds) => LinearGradient(
                            begin: widget.lowerLeft
                                ? Alignment.bottomLeft
                                : Alignment.topRight,
                            end: widget.lowerLeft
                                ? Alignment.topRight
                                : Alignment.bottomLeft,
                            colors: [
                              Colors.white,
                              Colors.white,
                              Colors.transparent,
                            ],
                            stops: [0, .45, 1],
                          ).createShader(bounds),
                          child: Opacity(
                            opacity: compact ? .26 : .4,
                            child: Image.asset(
                              widget.assetPath,
                              fit: BoxFit.contain,
                              frameBuilder: fadeImageFrame,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
