import 'dart:async';

import 'package:flutter/material.dart';

/// Fades in once when mounted; ordinary rebuilds keep the content visible.
class EntranceFade extends StatefulWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade> {
  Timer? _timer;
  bool _scheduled = false;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _timer?.cancel();
      _visible = true;
      return;
    }
    if (_scheduled || _visible) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _visible) return;
      if (widget.delay == Duration.zero) {
        setState(() => _visible = true);
      } else {
        _timer = Timer(widget.delay, () {
          if (mounted) setState(() => _visible = true);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !_visible,
    child: AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : widget.duration,
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

extension EntranceFadeList on List<Widget> {
  /// Keeps spacers unchanged and staggers the visible elements of a section.
  List<Widget> withEntranceFade({
    int delayMilliseconds = 0,
    int intervalMilliseconds = 100,
  }) {
    var index = 0;
    return map((child) {
      if (child is SizedBox) return child;
      return EntranceFade(
        delay: Duration(
          milliseconds: delayMilliseconds + index++ * intervalMilliseconds,
        ),
        child: child,
      );
    }).toList();
  }
}

/// Starts the fade when an asset or network image has actually decoded.
Widget fadeImageFrame(
  BuildContext context,
  Widget child,
  int? frame,
  bool synchronous,
) => AnimatedOpacity(
  opacity: frame != null || synchronous ? 1 : 0,
  duration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 450),
  curve: Curves.easeOutCubic,
  child: child,
);
