import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bingo/modules/entry/models/spotify_playback.dart';
import 'package:bingo/modules/home/models/boards.model.dart';
import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> track(String name, List<String> artists) => {
  'type': 'track',
  'name': name,
  'artists': artists.map((name) => {'name': name}).toList(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sync detects external track and pause without loading flicker', (
    tester,
  ) async {
    var snapshot = SpotifyPlayback.fromJson({
      'current': track('First', ['A']),
      'queue': [
        track('Queued', ['B']),
      ],
      'isPlaying': true,
    });
    var reads = 0;
    final controller = HomeController(
      loadPlayback: () async {
        reads++;
        return snapshot;
      },
    );
    controller.onInit();
    await tester.pump();
    controller.selectedArtists.value = ['Chosen'];
    snapshot = SpotifyPlayback.fromJson({
      'current': track('Second', ['C']),
      'queue': [
        track('Next', ['D']),
      ],
      'isPlaying': false,
    });
    await tester.pump(HomeController.spotifySyncInterval);
    expect(reads, 2);
    expect(controller.spotifyPlayback.value!.current!.name, 'Second');
    expect(controller.spotifyPlayback.value!.isPlaying, false);
    expect(controller.artistsDb, ['D']);
    expect(controller.selectedArtists, ['Chosen']);
    expect(controller.spotifyLoading.value, false);
    controller.onClose();
    await tester.pump(const Duration(seconds: 9));
    expect(reads, 2);
  });

  testWidgets('sync pauses when hidden and refreshes immediately on return', (
    tester,
  ) async {
    var reads = 0;
    final controller = HomeController(
      loadPlayback: () async {
        reads++;
        return const SpotifyPlayback(queue: []);
      },
    );
    controller.onInit();
    await tester.pump();
    controller.didChangeAppLifecycleState(AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 12));
    expect(reads, 1);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(reads, 2);
    await tester.pump(HomeController.spotifySyncInterval);
    expect(reads, 3);
    controller.onClose();
  });

  testWidgets('background reads are silent and never overlap', (tester) async {
    final pending = Completer<SpotifyPlayback>();
    var reads = 0;
    final controller = HomeController(
      loadPlayback: () async {
        reads++;
        if (reads == 1) return const SpotifyPlayback(queue: []);
        return pending.future;
      },
    );
    controller.onInit();
    await tester.pump();
    await tester.pump(HomeController.spotifySyncInterval);
    expect(reads, 2);
    expect(controller.spotifyLoading.value, false);
    await tester.pump(const Duration(seconds: 9));
    expect(reads, 2);
    pending.complete(const SpotifyPlayback(queue: []));
    await tester.pump();
    controller.onClose();
  });

  testWidgets(
    'automatic sync stops requesting when authorization is required',
    (tester) async {
      var reads = 0;
      final controller = HomeController(
        loadPlayback: () async {
          reads++;
          throw const SpotifyPlaybackException('session_expired');
        },
      );
      controller.onInit();
      await tester.pump();
      await tester.pump(const Duration(seconds: 15));
      expect(reads, 1);
      expect(controller.spotifyNeedsAuthorization.value, true);
      controller.onClose();
    },
  );

  test('player parses artwork, duration, progress and control permission', () {
    final playback = SpotifyPlayback.fromJson({
      'current': {
        ...track('Now', ['Artist']),
        'duration_ms': 180000,
        'album': {
          'images': [
            {'url': 'http://invalid.example/image'},
            {'url': 'https://i.scdn.co/image/cover'},
          ],
        },
      },
      'progressMs': 42000,
      'canControl': true,
    });
    expect(playback.current!.artworkUrl, 'https://i.scdn.co/image/cover');
    expect(playback.current!.durationMs, 180000);
    expect(playback.progressMs, 42000);
    expect(playback.canControl, true);
  });

  test(
    'command blocks duplicate taps and refreshes the resulting state',
    () async {
      final actions = <String>[];
      var reads = 0;
      final controller = HomeController(
        controlPlayback: (action) async => actions.add(action),
        loadPlayback: () async {
          reads++;
          return SpotifyPlayback.fromJson({
            'current': track('Next', ['Artist']),
            'queue': [
              track('Queued', ['New artist']),
            ],
          });
        },
      );
      addTearDown(controller.onClose);
      controller.selectedArtists.add('Selected artist');
      final command = controller.controlSpotify('next');
      await controller.controlSpotify('next');
      expect(controller.spotifyCommandBusy.value, true);
      await command;
      expect(actions, ['next']);
      expect(reads, 1);
      expect(controller.spotifyPlayback.value!.current!.name, 'Next');
      expect(controller.selectedArtists, contains('Selected artist'));
      expect(controller.spotifyCommandBusy.value, false);
    },
  );

  test(
    'failed command keeps snapshot and reports missing active device',
    () async {
      var reads = 0;
      final controller = HomeController(
        controlPlayback: (_) async =>
            throw const SpotifyPlaybackException('no_device'),
        loadPlayback: () async {
          reads++;
          return const SpotifyPlayback(queue: []);
        },
      );
      addTearDown(controller.onClose);
      await controller.refreshSpotify();
      final snapshot = controller.spotifyPlayback.value;
      await controller.controlSpotify('play');
      expect(reads, 1);
      expect(controller.spotifyPlayback.value, same(snapshot));
      expect(controller.spotifyError.value, contains('Abra o Spotify'));
      expect(controller.spotifyCommandBusy.value, false);
    },
  );

  test(
    'queue includes collaborations, deduplicates names and excludes episodes and current track',
    () {
      final playback = SpotifyPlayback.fromJson({
        'queue': [
          track('First', [' Artist A ', 'Artist B']),
          track('Second', ['artist a', 'Artist C', '']),
          {
            'type': 'episode',
            'name': 'Podcast',
            'artists': [
              {'name': 'Host'},
            ],
          },
          null,
        ],
        'current': track('Now', ['Current artist']),
        'isPlaying': false,
      });
      expect(playback.queueArtists, ['Artist A', 'Artist B', 'Artist C']);
      expect(playback.queue.length, 2);
      expect(playback.current?.name, 'Now');
      expect(playback.isPlaying, false);
    },
  );

  test('empty and unavailable track metadata do not invent artists', () {
    final playback = SpotifyPlayback.fromJson({'queue': [], 'current': null});
    expect(playback.queueArtists, isEmpty);
    expect(playback.current, isNull);
    expect(
      SpotifyTrack.fromJson({
        'type': 'track',
        'name': 'Local',
        'artists': null,
      })?.artists,
      isEmpty,
    );
  });

  test(
    'first queue populates selection; refresh preserves user edits and existing boards',
    () async {
      var playback = SpotifyPlayback.fromJson({
        'queue': [
          track('First', ['Artist A', 'Artist B']),
        ],
      });
      final controller = HomeController(loadPlayback: () async => playback);
      addTearDown(controller.onClose);
      expect(controller.artistsDb, isEmpty);
      await controller.refreshSpotify();
      expect(controller.artistsDb, ['Artist A', 'Artist B']);
      expect(controller.selectedArtists, ['Artist A', 'Artist B']);
      controller.selectedArtists.remove('Artist B');
      final board = BingoBoard(id: 1, gridSize: 3, tiles: []);
      controller.boards.add(board);
      playback = SpotifyPlayback.fromJson({
        'queue': [
          track('New', ['Artist C']),
        ],
      });
      await controller.refreshSpotify();
      expect(controller.artistsDb, ['Artist C']);
      expect(controller.selectedArtists, ['Artist A']);
      expect(controller.boards.single, same(board));
      controller.importQueueArtists();
      expect(controller.selectedArtists, ['Artist A', 'Artist C']);
    },
  );

  test(
    'empty startup stays empty and populates when a queue becomes available',
    () async {
      var playback = SpotifyPlayback.fromJson({'queue': []});
      final controller = HomeController(loadPlayback: () async => playback);
      addTearDown(controller.onClose);
      await controller.refreshSpotify();
      expect(controller.selectedArtists, isEmpty);
      playback = SpotifyPlayback.fromJson({
        'queue': [
          track('Later', ['Artist A']),
        ],
      });
      await controller.refreshSpotify();
      expect(controller.selectedArtists, ['Artist A']);
      playback = SpotifyPlayback.fromJson({'queue': []});
      await controller.refreshSpotify();
      expect(controller.artistsDb, isEmpty);
      expect(controller.selectedArtists, ['Artist A']);
    },
  );

  test(
    'rate limit preserves data and prevents requests before retry interval',
    () async {
      var calls = 0;
      final controller = HomeController(
        loadPlayback: () async {
          calls++;
          if (calls > 1) {
            throw const SpotifyPlaybackException(
              'rate_limited',
              retryAfter: 60,
            );
          }
          return SpotifyPlayback.fromJson({
            'queue': [
              track('First', ['Artist A']),
            ],
          });
        },
      );
      addTearDown(controller.onClose);
      await controller.refreshSpotify();
      await controller.refreshSpotify();
      await controller.refreshSpotify();
      expect(calls, 2);
      expect(controller.artistsDb, ['Artist A']);
      expect(controller.spotifyError.value, contains('60 segundos'));
      expect(controller.spotifyLoading.value, false);
    },
  );
}
