import 'package:bingo/global/widgets/entrance_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('entrance fades after delay and stays visible on rebuild', (
    tester,
  ) async {
    Widget page(String label) => MaterialApp(
      home: EntranceFade(
        delay: const Duration(milliseconds: 200),
        child: Text(label),
      ),
    );
    await tester.pumpWidget(page('First'));
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    final opacity = tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(AnimatedOpacity),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;
    expect(opacity, greaterThan(0));
    expect(opacity, lessThan(1));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(page('Updated'));
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );
    expect(find.text('Updated'), findsOneWidget);
  });

  testWidgets('reduced motion shows content immediately', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: EntranceFade(
            delay: Duration(seconds: 1),
            child: Text('Visible'),
          ),
        ),
      ),
    );
    final fade = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(fade.opacity, 1);
    expect(fade.duration, Duration.zero);
  });

  testWidgets('disposing before the delay cancels the entrance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EntranceFade(delay: Duration(seconds: 1), child: Text('Delayed')),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
