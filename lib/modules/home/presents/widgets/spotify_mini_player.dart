import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:bingo/modules/home/presents/widgets/home_design.dart';
import 'package:flutter/material.dart';
import 'package:bingo/global/widgets/entrance_fade.dart';
import 'package:get/get.dart';

class SpotifyMiniPlayer extends StatelessWidget {
  const SpotifyMiniPlayer({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
  });
  final HomeController controller;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) => Obx(() {
    final playback = controller.spotifyPlayback.value;
    final track = playback?.current;
    if (track == null) return const SizedBox.shrink();
    final playing = playback?.isPlaying;
    final enabled =
        controller.canControlPlayer &&
        playback?.canControl == true &&
        !controller.spotifyCommandBusy.value &&
        !controller.spotifyLoading.value &&
        !controller.spotifyNeedsAuthorization.value;
    final compact =
        MediaQuery.sizeOf(context).width < 900 ||
        MediaQuery.textScalerOf(context).scale(13) > 17;
    final artwork = Container(
      width: 44,
      height: 44,
      color: const Color(0xFF1B3022),
      child: const Icon(Icons.music_note_rounded, color: HomeDesign.green),
    );
    return Semantics(
      container: true,
      label: 'Mini player Spotify',
      child: Container(
        decoration: HomeDesign.surface(highlighted: true),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 20,
                  vertical: 12,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final row = Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: track.artworkUrl == null
                              ? artwork
                              : Image.network(
                                  track.artworkUrl!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  frameBuilder: fadeImageFrame,
                                  errorBuilder: (_, _, _) => artwork,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                track.artists.join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: HomeDesign.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 16),
                          const BingusBrandMark(size: 24),
                          const SizedBox(width: 8),
                          Text(
                            playing == true ? 'Tocando agora' : 'Seu Spotify',
                            style: const TextStyle(
                              color: HomeDesign.muted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 24),
                        ],
                        IconButton(
                          tooltip: 'Música anterior',
                          iconSize: 22,
                          onPressed: enabled
                              ? () => controller.controlSpotify('previous')
                              : null,
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        IconButton.filled(
                          tooltip: playing == true ? 'Pausar' : 'Reproduzir',
                          style: IconButton.styleFrom(
                            backgroundColor: HomeDesign.green,
                            foregroundColor: const Color(0xFF07140B),
                            disabledBackgroundColor: const Color(0xFF233B2A),
                            minimumSize: const Size(40, 40),
                          ),
                          onPressed: enabled && playing != null
                              ? () => controller.controlSpotify(
                                  playing ? 'pause' : 'play',
                                )
                              : null,
                          icon: Icon(
                            playing == true
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Próxima música',
                          iconSize: 22,
                          onPressed: enabled
                              ? () => controller.controlSpotify('next')
                              : null,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Ver player completo',
                            onPressed: onOpenPlayer,
                            icon: const Icon(
                              Icons.open_in_full_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ],
                    );
                    if (constraints.maxWidth >= 420 &&
                        MediaQuery.textScalerOf(context).scale(13) <= 17) {
                      return row;
                    }
                    return Column(
                      children: [
                        Row(children: row.children.take(3).toList()),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...row.children.skip(3),
                            IconButton(
                              tooltip: 'Ver player completo',
                              onPressed: onOpenPlayer,
                              icon: const Icon(
                                Icons.open_in_full_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (track.durationMs > 0)
                Obx(
                  () => LinearProgressIndicator(
                    value:
                        controller.spotifyPositionMs.value.clamp(
                          0,
                          track.durationMs,
                        ) /
                        track.durationMs,
                    minHeight: 3,
                    color: HomeDesign.green,
                    backgroundColor: const Color(0xFF25352A),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  });
}
