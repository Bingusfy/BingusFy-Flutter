import 'package:bingo/modules/entry/models/spotify_playback.dart';
import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:bingo/modules/home/presents/home_page.dart';
import 'package:bingo/modules/home/presents/widgets/spotify_mini_player.dart';
import 'package:bingo/modules/home/presents/widgets/spotify_playback_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

void main() {
  for (final width in [1280.0, 390.0]) {
    testWidgets('mini player follows main visibility at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      final actions = <String>[];
      var playing = true;
      final controller = HomeController(
        loadPlayback: () async => SpotifyPlayback(
          queue: const [
            SpotifyTrack(name: 'Next', artists: ['Next artist']),
          ],
          current: const SpotifyTrack(
            name: 'Current song',
            artists: ['Artist'],
            durationMs: 180000,
          ),
          isPlaying: playing,
          canControl: true,
          progressMs: 12000,
        ),
        controlPlayback: (action) async {
          actions.add(action);
          playing = action != 'pause';
        },
      );
      GetIt.I.registerFactory<HomeController>(() => controller);
      addTearDown(() async {
        Get.reset();
        await GetIt.I.unregister<HomeController>();
      });
      await tester.pumpWidget(const GetMaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 850));
      await tester.pump();
      await Scrollable.ensureVisible(
        tester.element(find.byType(SpotifyPlaybackPanel)),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(SpotifyMiniPlayer), findsNothing);
      // Scroll the outer viewport; nested queue/table scrolls must not drive visibility.
      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      await tester.pump();
      expect(find.byType(SpotifyMiniPlayer), findsOneWidget);
      // Let the new mini player finish its entrance before interacting.
      await tester.pump(const Duration(milliseconds: 700));
      final mini = find.byType(SpotifyMiniPlayer);
      expect(
        find.descendant(of: mini, matching: find.text('Current song')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: mini, matching: find.byTooltip('Pausar')),
      );
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      expect(actions, ['pause']);
      expect(
        find.descendant(of: mini, matching: find.byTooltip('Reproduzir')),
        findsOneWidget,
      );
      if (width > 640) {
        await tester.tap(find.byTooltip('Ver player completo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      } else {
        await Scrollable.ensureVisible(
          tester.element(find.byType(SpotifyPlaybackPanel)),
        );
      }
      await tester.pump();
      await tester.pump();
      expect(find.byType(SpotifyMiniPlayer), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
