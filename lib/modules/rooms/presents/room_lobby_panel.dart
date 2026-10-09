import 'dart:async';

import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:bingo/modules/home/presents/widgets/home_design.dart';
import 'package:bingo/modules/rooms/services/room_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class RoomLobbyPanel extends StatefulWidget {
  const RoomLobbyPanel({
    super.key,
    required this.controller,
    this.roomId,
    this.isOwner = true,
  });
  final HomeController controller;
  final String? roomId;
  final bool isOwner;

  @override
  State<RoomLobbyPanel> createState() => _RoomLobbyPanelState();
}

class _RoomLobbyPanelState extends State<RoomLobbyPanel> {
  final _service = RoomService();
  String? _roomId;
  String? _error;
  bool _busy = false;
  bool _publishing = false;
  DateTime? _lastPublished;
  String? _lastPlaybackKey;
  Worker? _worker;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSubscription;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _participants;
  String _status = 'open';

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) _bind(widget.roomId!);
  }

  void _bind(String id) {
    _roomId = id;
    _participants = _service.room(id).collection('participants').snapshots();
    _roomSubscription = _service
        .room(id)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(
                () =>
                    _status = snapshot.data()?['status'] as String? ?? 'closed',
              );
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() => _error = 'Não foi possível acompanhar a sala.');
            }
          },
        );
    if (widget.isOwner) {
      _worker = ever(widget.controller.spotifyPlayback, (_) => _publish());
      _publish();
    }
  }

  Future<void> _publish() async {
    final playback = widget.controller.spotifyPlayback.value;
    if (_publishing ||
        playback == null ||
        _roomId == null ||
        _status != 'open') {
      return;
    }
    final key =
        '${playback.current?.name}|${playback.isPlaying}|${playback.queue.map((track) => track.name).join('|')}';
    if (_lastPlaybackKey == key &&
        _lastPublished != null &&
        DateTime.now().difference(_lastPublished!) <
            const Duration(seconds: 10)) {
      return;
    }
    _publishing = true;
    try {
      await _service.publish(_roomId!, playback);
      _lastPublished = DateTime.now();
      _lastPlaybackKey = key;
      if (mounted && _error != null) setState(() => _error = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível sincronizar a música com a sala.',
        );
      }
    } finally {
      _publishing = false;
    }
  }

  Future<void> _create() async {
    if (widget.controller.selectedArtists.isEmpty) {
      setState(() => _error = 'Selecione os artistas antes de criar a sala.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await _service.create(
        artists: widget.controller.selectedArtists.toList(),
        gridSize: widget.controller.gridSize.value,
        blankPercent: widget.controller.blankPercent.value,
        freeCenter: widget.controller.freeCenter.value,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/room/$id', (_) => false);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Não foi possível criar a sala. Confira o Firebase e sua sessão Spotify.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exit() async {
    setState(() => _busy = true);
    try {
      if (widget.isOwner) {
        await _service.close(_roomId!);
      } else {
        await _service.leave(_roomId!);
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(widget.isOwner ? '/home' : '/', (_) => false);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível sair da sala. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _worker?.dispose();
    _roomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(20),
    decoration: HomeDesign.surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.groups_rounded, color: HomeDesign.green),
                Text(
                  _roomId == null
                      ? 'Jogue com a galera'
                      : _status == 'closed'
                      ? 'Sala encerrada'
                      : 'Sala do BingusFy',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (_roomId == null)
              FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: const Icon(Icons.add_link_rounded, size: 18),
                label: Text(_busy ? 'Criando...' : 'Criar sala'),
              ),
            if (_roomId != null && _status == 'open') ...[
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: RoomService.inviteLink(_roomId!)),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link da sala copiado.')),
                    );
                  }
                },
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Copiar convite'),
              ),
              TextButton(
                onPressed: _busy ? null : _exit,
                child: Text(widget.isOwner ? 'Encerrar sala' : 'Sair da sala'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _roomId == null
              ? 'Crie uma sala com os artistas selecionados. Cada pessoa recebe sua própria tabela.'
              : widget.isOwner
              ? 'Você controla a música. Todos acompanham as tabelas; cada pessoa marca a própria.'
              : 'Marque sua tabela e acompanhe as dos outros. A música fica sob o controle do dono.',
          style: const TextStyle(
            color: HomeDesign.muted,
            fontSize: 12,
            height: 1.6,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFFB4AB), fontSize: 12),
            ),
          ),
        if (_participants != null)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _participants,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Não foi possível consultar os participantes.',
                );
              }
              final participants = snapshot.data?.docs ?? [];
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${participants.length} participantes na sala',
                      style: const TextStyle(
                        color: HomeDesign.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final participant in participants)
                          Chip(
                            avatar: Icon(
                              participant.data()['role'] == 'owner'
                                  ? Icons.headphones_rounded
                                  : Icons.person_outline,
                              size: 16,
                              color: HomeDesign.green,
                            ),
                            label: Text(
                              participant.data()['name'] as String? ??
                                  'Participante',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    ),
  );
}
