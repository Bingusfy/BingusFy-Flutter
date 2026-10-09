import 'package:bingo/modules/entry/models/spotify_playback.dart';
import 'package:bingo/modules/entry/presents/entry_page.dart';
import 'package:bingo/modules/home/models/boards.model.dart';
import 'package:bingo/modules/home/models/tile.model.dart';
import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:bingo/modules/home/presents/home_page.dart';
import 'package:bingo/modules/home/presents/widgets/spotify_mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  for (final size in const [
    Size(320, 568),
    Size(360, 800),
    Size(390, 844),
    Size(430, 932),
    Size(740, 360),
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('entry fits $size with text scale $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const EntryPage(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byType(FilledButton)).width,
          lessThanOrEqualTo(size.width),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('home and mini player fit $size with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Get.testMode = true;
        final controller = HomeController(
          loadPlayback: () async => const SpotifyPlayback(
            current: SpotifyTrack(
              name: 'Uma música com um título longo',
              artists: ['Um artista com nome longo'],
              durationMs: 180000,
            ),
            queue: [
              SpotifyTrack(name: 'Próxima música', artists: ['Artista']),
            ],
            canControl: true,
            isPlaying: true,
          ),
        );
        controller.boards.value = [
          BingoBoard(
            id: 1,
            gridSize: 5,
            tiles: List.generate(
              25,
              (index) => index == 12
                  ? const BingoTile(type: BingoTileType.free)
                  : index == 0
                  ? const BingoTile(type: BingoTileType.blank)
                  : const BingoTile(
                      type: BingoTileType.artist,
                      content: 'Artista com nome longo',
                    ),
            ),
          ),
        ];
        controller.showEmptyState.value = false;
        await tester.pumpWidget(
          GetMaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: HomePage(homeController: controller),
          ),
        );
        await tester.pump(const Duration(milliseconds: 850));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
        await tester.pump();
        expect(find.byType(SpotifyMiniPlayer), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        Get.reset();
      });
    }
  }
}
