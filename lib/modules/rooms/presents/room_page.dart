import 'dart:async';

import 'package:bingo/modules/entry/models/spotify_playback.dart';
import 'package:bingo/modules/entry/services/spotify_auth.dart';
import 'package:bingo/modules/home/models/boards.model.dart';
import 'package:bingo/modules/home/models/tile.model.dart';
import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:bingo/modules/home/presents/home_page.dart';
import 'package:bingo/modules/home/presents/widgets/home_design.dart';
import 'package:bingo/modules/rooms/services/room_firebase.dart';
import 'package:bingo/modules/rooms/services/room_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'room_lobby_panel.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key, required this.roomId});
  final String roomId;
  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final _service = RoomService();
  final _name = TextEditingController();
  HomeController? _controller;
  Map<String, dynamic>? _room;
  bool _busy = true;
  bool _owner = false;
  String? _error;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _boardSubscription;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(widget.roomId)) {
        throw StateError('Link de sala inválido.');
      }
      await RoomFirebase.initialize();
      final document = await _service.room(widget.roomId).get();
      _room = document.data();
      if (_room == null || _room!['status'] != 'open') {
        throw StateError('Esta sala não existe ou já foi encerrada.');
      }
      _owner = _room!['ownerUid'] == _service.uid;
      if (_owner) {
        if (!await SpotifyAuth.restore()) {
          throw StateError(
            'O dono precisa entrar novamente no Spotify para controlar esta sala.',
          );
        }
        _open();
      } else {
        final member = await _service
            .room(widget.roomId)
            .collection('participants')
            .doc(_service.uid)
            .get();
        if (member.exists) _open();
      }
    } catch (error) {
      _error = error is StateError
          ? error.message.toString()
          : 'Não foi possível abrir a sala. Confira a conexão e tente novamente.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  SpotifyPlayback _remotePlayback() {
    final raw = Map<String, dynamic>.from(_room?['playback'] as Map? ?? {});
    raw['canControl'] = false;
    final updated = _room?['syncedAt'];
    if (raw['isPlaying'] == true && updated is Timestamp) {
      raw['progressMs'] =
          ((raw['progressMs'] as num?)?.toInt() ?? 0) +
          DateTime.now()
              .difference(updated.toDate())
              .inMilliseconds
              .clamp(0, 86400000);
    }
    if (_room?['status'] != 'open') raw['isPlaying'] = false;
    return SpotifyPlayback.fromJson(raw);
  }

  void _open() {
    if (!mounted) return;
    final controller = HomeController(
      isRoomGuest: !_owner,
      loadPlayback: _owner
          ? SpotifyAuth.loadPlayback
          : () async => _remotePlayback(),
      onRoomTileMark: (index, marked) =>
          _service.mark(widget.roomId, index, marked),
    );
    _controller = controller;
    final settings = Map<String, dynamic>.from(_room!['settings'] as Map);
    controller.gridSize.value = settings['gridSize'] as int;
    controller.blankPercent.value = settings['blankPercent'] as int;
    controller.freeCenter.value = settings['freeCenter'] as bool;
    controller.selectedArtists.value = List<String>.from(
      _room!['artists'] as List,
    );
    _roomSubscription = _service
        .room(widget.roomId)
        .snapshots()
        .listen(
          (snapshot) {
            _room = snapshot.data();
            if (controller.isClosed) return;
            if (_room?['status'] != 'open') {
              if (mounted) setState(() {});
              return;
            }
            if (!_owner) {
              final playback = _remotePlayback();
              controller.spotifyPlayback.value = playback;
              controller.spotifyUpdatedAt.value = DateTime.now();
              controller.spotifyPositionMs.value = playback.progressMs.clamp(
                0,
                playback.current?.durationMs ?? 0,
              );
            }
          },
          onError: (_) {
            if (!controller.isClosed) {
              controller.spotifyError.value =
                  'A sincronização com a sala foi interrompida.';
            }
          },
        );
    {
      _boardSubscription = _service
          .room(widget.roomId)
          .collection('boards')
          .snapshots()
          .listen(
            (snapshot) {
              if (controller.isClosed) return;
              final documents = [...snapshot.docs]
                ..sort((a, b) {
                  if (a.id == _service.uid) return -1;
                  if (b.id == _service.uid) return 1;
                  return a.id.compareTo(b.id);
                });
              controller.boards.value = [
                for (
                  var boardIndex = 0;
                  boardIndex < documents.length;
                  boardIndex++
                )
                  _readBoard(documents[boardIndex], boardIndex),
              ];
              controller.showEmptyState.value = false;
            },
            onError: (_) {
              if (!controller.isClosed) {
                controller.showToast('Não foi possível acompanhar as tabelas.');
              }
            },
          );
    }
  }

  BingoBoard _readBoard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    int index,
  ) {
    final board = document.data();
    final tiles = board['cells'] as List;
    final marks = board['marks'] as List;
    return BingoBoard(
      id: index + 1,
      ownerName: board['name'] as String,
      canMark: document.id == _service.uid,
      gridSize: board['gridSize'] as int,
      tiles: [
        for (var i = 0; i < tiles.length; i++)
          BingoTile(
            type: switch (tiles[i]) {
              RoomService.freeCell => BingoTileType.free,
              '' => BingoTileType.blank,
              _ => BingoTileType.artist,
            },
            content: tiles[i] == RoomService.freeCell
                ? 'FREE'
                : tiles[i] as String,
            isMarked: marks[i] == true,
          ),
      ],
    );
  }

  Future<void> _join() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Informe seu nome para participar.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.join(widget.roomId, _name.text.trim());
      _open();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível entrar. Confira sua conexão e se a sala está aberta.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _boardSubscription?.cancel();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && _room?['status'] == 'open') {
      return HomePage(
        homeController: _controller,
        roomPanel: RoomLobbyPanel(
          controller: _controller!,
          roomId: widget.roomId,
          isOwner: _owner,
        ),
      );
    }
    final closed = _controller != null;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: HomeDesign.surface(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      color: HomeDesign.green,
                      size: 36,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      closed ? 'Sala encerrada' : 'Entre no bingo',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Você recebe sua tabela. A música fica sob o controle do dono da sala.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: HomeDesign.muted, height: 1.6),
                    ),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (!closed && _room != null && !_owner) ...[
                      const SizedBox(height: 24),
                      TextField(
                        controller: _name,
                        maxLength: 40,
                        onSubmitted: (_) => _join(),
                        decoration: const InputDecoration(
                          labelText: 'Seu nome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _join,
                        child: const Text('Entrar na sala'),
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFFB4AB)),
                        ),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (_) => false),
                      child: Text(
                        _owner ? 'Entrar com Spotify' : 'Voltar ao início',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
