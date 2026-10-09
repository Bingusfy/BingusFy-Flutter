import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bingo/modules/entry/models/spotify_playback.dart';
import 'package:bingo/modules/entry/services/spotify_auth.dart';
import 'room_firebase.dart';

class RoomService {
  static const freeCell = '__BINGUS_FREE__';
  FirebaseFirestore get db => FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> room(String id) =>
      db.collection('rooms').doc(id);

  Future<String> create({
    required List<String> artists,
    required int gridSize,
    required int blankPercent,
    required bool freeCenter,
  }) async {
    await RoomFirebase.initialize();
    if (!await SpotifyAuth.restore()) {
      throw StateError('Entre no Spotify para criar a sala.');
    }
    final names = artists
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty ||
        names.length > 200 ||
        names.any((name) => name.length > 120)) {
      throw StateError(
        'Escolha de 1 a 200 artistas com nomes de até 120 caracteres.',
      );
    }
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final batch = db.batch();
    batch.set(room(id), {
      'ownerUid': uid,
      'status': 'open',
      'artists': names,
      'settings': {
        'gridSize': gridSize,
        'blankPercent': blankPercent,
        'freeCenter': freeCenter,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
      'playback': {
        'current': null,
        'queue': [],
        'isPlaying': false,
        'progressMs': 0,
        'canControl': false,
      },
    });
    batch.set(room(id).collection('participants').doc(uid), {
      'name': 'Dono da sala',
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(room(id).collection('boards').doc(uid), {
      ...makeBoard(names, {
        'gridSize': gridSize,
        'blankPercent': blankPercent,
        'freeCenter': freeCenter,
      }),
      'name': 'Dono da sala',
    });
    await batch.commit();
    return id;
  }

  Future<void> join(String id, String name) async {
    await RoomFirebase.initialize();
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 40) {
      throw StateError('Informe um nome de até 40 caracteres.');
    }
    await db.runTransaction((transaction) async {
      final ref = room(id);
      final memberRef = ref.collection('participants').doc(uid);
      final document = await transaction.get(ref);
      final member = await transaction.get(memberRef);
      if (!document.exists || document.data()?['status'] != 'open') {
        throw StateError('Esta sala foi encerrada.');
      }
      if (member.exists) return;
      final data = document.data()!;
      transaction.set(memberRef, {
        'name': trimmed,
        'role': 'guest',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(ref.collection('boards').doc(uid), {
        ...makeBoard(
          List<String>.from(data['artists'] as List),
          Map<String, dynamic>.from(data['settings'] as Map),
        ),
        'name': trimmed,
      });
    });
  }

  static Map<String, dynamic> makeBoard(
    List<String> artists,
    Map<String, dynamic> settings,
  ) {
    final random = Random.secure();
    final grid = settings['gridSize'] as int;
    final count = grid * grid;
    final center = settings['freeCenter'] == true && grid.isOdd;
    final blanks = count * (settings['blankPercent'] as int) ~/ 100;
    final pool = [...artists]..shuffle(random);
    final cells = <String>[
      for (var i = 0; i < count - blanks - (center ? 1 : 0); i++)
        pool[i % pool.length],
      for (var i = 0; i < blanks; i++) '',
    ]..shuffle(random);
    if (center) cells.insert(count ~/ 2, freeCell);
    return {
      'gridSize': grid,
      'cells': cells,
      'marks': [for (final cell in cells) cell == freeCell],
    };
  }

  Future<void> leave(String id) async {
    final batch = db.batch();
    batch.delete(room(id).collection('boards').doc(uid));
    batch.delete(room(id).collection('participants').doc(uid));
    await batch.commit();
  }

  Future<void> close(String id) => room(
    id,
  ).update({'status': 'closed', 'closedAt': FieldValue.serverTimestamp()});
  Future<void> mark(String id, int index, bool marked) =>
      db.runTransaction((transaction) async {
        final ref = room(id).collection('boards').doc(uid);
        final document = await transaction.get(ref);
        final data = document.data();
        if (data == null ||
            index < 0 ||
            index >= (data['cells'] as List).length ||
            data['cells'][index] == '' ||
            data['cells'][index] == freeCell) {
          throw StateError('Marque apenas os artistas da sua tabela.');
        }
        final marks = List<bool>.from(data['marks'] as List);
        marks[index] = marked;
        transaction.update(ref, {'marks': marks});
      });

  Future<void> publish(String id, SpotifyPlayback playback) async {
    Map<String, dynamic>? track(dynamic item) => item == null
        ? null
        : {
            'type': 'track',
            'name': item.name,
            'artists': [
              for (final name in item.artists) {'name': name},
            ],
            'duration_ms': item.durationMs,
            'album': {
              'images': [
                if (item.artworkUrl != null) {'url': item.artworkUrl},
              ],
            },
          };
    await room(id).update({
      'playback': {
        'current': track(playback.current),
        'queue': [for (final item in playback.queue.take(80)) track(item)],
        'isPlaying': playback.isPlaying,
        'progressMs': playback.progressMs,
        'canControl': false,
      },
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  static String inviteLink(String id) =>
      Uri.base.replace(query: null, fragment: '/room/$id').toString();
}
