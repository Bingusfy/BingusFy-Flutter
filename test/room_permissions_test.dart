import 'package:bingo/modules/entry/models/spotify_playback.dart';
import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:bingo/modules/home/presents/widgets/spotify_mini_player.dart';
import 'package:bingo/modules/home/presents/widgets/spotify_playback_panel.dart';
import 'package:bingo/modules/home/presents/home_page.dart';
import 'package:bingo/modules/home/models/boards.model.dart';
import 'package:bingo/modules/home/models/tile.model.dart';
import 'package:bingo/modules/rooms/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'room grid follows live tables and shows the own-table badge once',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      final controller = HomeController(
        onRoomTileMark: (_, _) async {},
        loadPlayback: () async => const SpotifyPlayback(queue: []),
      );
      final own = BingoBoard(
        id: 1,
        ownerName: 'Teste',
        gridSize: 3,
        tiles: List.generate(
          9,
          (_) => const BingoTile(type: BingoTileType.artist, content: 'A'),
        ),
      );
      controller.boards.value = [own];
      controller.showEmptyState.value = false;
      await tester.pumpWidget(
        GetMaterialApp(
          home: HomePage(
            homeController: controller,
            roomPanel: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 850));
      await tester.pump();
      expect(find.text('Sua tabela'), findsOneWidget);
      expect(find.text('Tabela · Outro'), findsNothing);
      controller.boards.value = [
        own,
        BingoBoard(
          id: 2,
          ownerName: 'Outro',
          canMark: false,
          gridSize: 3,
          tiles: own.tiles,
        ),
      ];
      await tester.pump();
      expect(find.text('Tabela · Outro'), findsOneWidget);
      expect(find.text('Sua tabela'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      Get.reset();
    },
  );
  test(
    'owner and guest mark only their own room table through the shared service',
    () async {
      for (final guest in [false, true]) {
        final calls = <int>[];
        final controller = HomeController(
          isRoomGuest: guest,
          onRoomTileMark: (index, marked) async {
            calls.add(index);
            expect(marked, true);
          },
        );
        controller.boards.value = [
          const BingoBoard(
            id: 1,
            gridSize: 3,
            tiles: [BingoTile(type: BingoTileType.artist, content: 'A')],
          ),
          const BingoBoard(
            id: 2,
            gridSize: 3,
            canMark: false,
            tiles: [BingoTile(type: BingoTileType.artist, content: 'B')],
          ),
        ];
        controller.toggleTileMark(0, 0);
        controller.toggleTileMark(1, 0);
        await Future<void>.delayed(Duration.zero);
        expect(calls, [0]);
        expect(controller.boards.first.tiles.first.isMarked, false);
        controller.onClose();
      }
    },
  );

  test(
    'room tables honor grid, blanks and free center before being shared',
    () {
      for (final grid in [3, 4, 5]) {
        final board = RoomService.makeBoard(
          ['A', 'B'],
          {'gridSize': grid, 'blankPercent': 20, 'freeCenter': true},
        );
        final cells = board['cells'] as List;
        final marks = board['marks'] as List;
        expect(cells.length, grid * grid);
        expect(
          cells.where((cell) => cell == '').length,
          grid * grid * 20 ~/ 100,
        );
        expect(
          cells.where((cell) => cell == RoomService.freeCell).length,
          grid.isOdd ? 1 : 0,
        );
        expect(marks.where((mark) => mark == true).length, grid.isOdd ? 1 : 0);
        if (grid.isOdd) expect(cells[grid * grid ~/ 2], RoomService.freeCell);
      }
    },
  );
  test(
    'guest cannot send Spotify commands even with a forged control flag',
    () async {
      final actions = <String>[];
      final controller = HomeController(
        isRoomGuest: true,
        controlPlayback: (action) async => actions.add(action),
        loadPlayback: () async =>
            const SpotifyPlayback(queue: [], canControl: true),
      );
      addTearDown(controller.onClose);
      await controller.refreshSpotify();
      for (final action in ['play', 'pause', 'next', 'previous']) {
        await controller.controlSpotify(action);
      }
      expect(actions, isEmpty);
    },
  );

  testWidgets('both players disable controls for a room guest', (tester) async {
    final controller = HomeController(isRoomGuest: true);
    controller.spotifyPlayback.value = const SpotifyPlayback(
      queue: [],
      current: SpotifyTrack(name: 'Song', artists: ['Artist']),
      isPlaying: true,
      canControl: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SpotifyPlaybackPanel(controller: controller),
              SpotifyMiniPlayer(controller: controller, onOpenPlayer: () {}),
            ],
          ),
        ),
      ),
    );
    for (final label in ['Pausar', 'Música anterior', 'Próxima música']) {
      final buttons = tester.widgetList<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == label,
        ),
      );
      expect(buttons.length, 2);
      expect(buttons.every((button) => button.onPressed == null), true);
    }
    expect(find.text('Autorizar controles do Spotify'), findsNothing);
    expect(find.text('Reconectar Spotify'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.onClose();
  });
}
