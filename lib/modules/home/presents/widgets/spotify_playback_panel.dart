import 'package:bingo/modules/entry/models/spotify_playback.dart';
import 'package:bingo/modules/entry/services/spotify_auth.dart';
import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:bingo/modules/home/presents/widgets/home_design.dart';
import 'package:flutter/material.dart';
import 'package:bingo/global/widgets/entrance_fade.dart';
import 'package:get/get.dart';

class SpotifyPlaybackPanel extends StatelessWidget {
  const SpotifyPlaybackPanel({
    super.key,
    required this.controller,
    this.playerVisibilityKey,
  });
  final Key? playerVisibilityKey;
  final HomeController controller;
  static const _green = HomeController.primaryColor;
  static const _muted = Color(0xFF9CA9A0);

  @override
  Widget build(BuildContext context) => Obx(() {
    final playback = controller.spotifyPlayback.value;
    final loading = controller.spotifyLoading.value;
    final busy = loading || controller.spotifyCommandBusy.value;
    final error = controller.spotifyError.value;
    final needsAuthorization = controller.spotifyNeedsAuthorization.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: HomeDesign.surface(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BingusBrandMark(size: 28),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        controller.isRoomGuest
                            ? 'Spotify da sala'
                            : 'Seu Spotify',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (!controller.isRoomGuest)
                  TextButton.icon(
                    onPressed: busy ? null : controller.refreshSpotify,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _green,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(loading ? 'Consultando...' : 'Atualizar fila'),
                  ),
                if (!controller.isRoomGuest)
                  TextButton.icon(
                    onPressed: () {
                      SpotifyAuth.signOut();
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (_) => false);
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Sair'),
                  ),
              ],
            ),
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(error, style: const TextStyle(color: Color(0xFFFFB4AB))),
                  if (needsAuthorization && !controller.isRoomGuest)
                    TextButton(
                      onPressed: controller.reconnectSpotify,
                      child: const Text('Reconectar Spotify'),
                    ),
                  if (playback != null)
                    const Text(
                      'Exibindo os dados da última atualização.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final player = _player(playback, busy, needsAuthorization);
              final queue = _queue(playback);
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [
                    player,
                    const Divider(height: 1, color: Color(0x223A6544)),
                    queue,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: player),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Color(0x223A6544)),
                        ),
                      ),
                      child: queue,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  });

  Widget _player(
    SpotifyPlayback? playback,
    bool busy,
    bool needsAuthorization,
  ) {
    final current = playback?.current;
    final canControl =
        controller.canControlPlayer &&
        !busy &&
        playback?.canControl == true &&
        current != null &&
        !needsAuthorization;
    final playing = playback?.isPlaying;
    return Padding(
      key: playerVisibilityKey,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current == null
                ? 'PRONTO PARA O PLAY'
                : playing == false
                ? 'PAUSADO'
                : 'TOCANDO AGORA',
            style: const TextStyle(
              color: _green,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                _artwork(
                  current,
                  (constraints.maxWidth * .26).clamp(56.0, 112.0),
                ),
                SizedBox(width: constraints.maxWidth < 320 ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current?.name ?? 'Nenhuma música em reprodução',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (constraints.maxWidth * .06).clamp(
                            18.0,
                            22.0,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        current?.artists.join(' • ') ??
                            'Abra o Spotify e escolha uma música.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.devices_rounded, size: 14, color: _green),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              controller.isRoomGuest
                                  ? 'Reprodução no Spotify do dono'
                                  : 'Reprodução no seu Spotify',
                              style: TextStyle(color: _muted, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Música anterior',
                iconSize: 28,
                onPressed: canControl
                    ? () => controller.controlSpotify('previous')
                    : null,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: playing == true ? 'Pausar' : 'Reproduzir',
                style: IconButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: const Color(0xFF07140B),
                  disabledBackgroundColor: const Color(0xFF233B2A),
                  minimumSize: const Size(48, 48),
                ),
                iconSize: 30,
                onPressed: canControl && playing != null
                    ? () =>
                          controller.controlSpotify(playing ? 'pause' : 'play')
                    : null,
                icon: Icon(
                  playing == true
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Próxima música',
                iconSize: 28,
                onPressed: canControl
                    ? () => controller.controlSpotify('next')
                    : null,
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ],
          ),
          if (current != null && current.durationMs > 0) ...[
            const SizedBox(height: 14),
            Obx(() {
              final position = controller.spotifyPositionMs.value.clamp(
                0,
                current.durationMs,
              );
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: position / current.durationMs,
                      minHeight: 4,
                      color: _green,
                      backgroundColor: const Color(0xFF25352A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _time(position),
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                      Text(
                        _time(current.durationMs),
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
          if (controller.isRoomGuest)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Somente o dono da sala controla a reprodução.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          if (!controller.isRoomGuest &&
              playback != null &&
              !playback.canControl &&
              !needsAuthorization)
            TextButton(
              onPressed: controller.reconnectSpotify,
              child: const Text('Autorizar controles do Spotify'),
            ),
        ],
      ),
    );
  }

  Widget _queue(SpotifyPlayback? playback) {
    final tracks = playback?.queue ?? <SpotifyTrack>[];
    final artists = playback?.queueArtists.length ?? 0;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.queue_music_rounded, color: _green, size: 22),
              SizedBox(width: 8),
              Text(
                'A seguir',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${tracks.length} ${tracks.length == 1 ? 'música' : 'músicas'} na fila · $artists ${artists == 1 ? 'artista único' : 'artistas únicos'}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (tracks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Adicione músicas à fila no Spotify. Elas aparecerão aqui.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          if (tracks.isNotEmpty)
            SizedBox(
              height: (tracks.length * 60.0).clamp(0, 240),
              child: ListView.separated(
                primary: false,
                itemCount: tracks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ),
                        _artwork(track, 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                track.artists.join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (track.durationMs > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            _time(track.durationMs),
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'Os artistas da fila alimentam sua lista de artistas.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _artwork(SpotifyTrack? track, double size) {
    final fallback = Container(
      width: size,
      height: size,
      color: const Color(0xFF1B3022),
      child: Icon(Icons.music_note_rounded, color: _green, size: size * .4),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: track?.artworkUrl == null
          ? fallback
          : Image.network(
              track!.artworkUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              frameBuilder: fadeImageFrame,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }

  String _time(int ms) =>
      '${ms ~/ 60000}:${((ms ~/ 1000) % 60).toString().padLeft(2, '0')}';
}
