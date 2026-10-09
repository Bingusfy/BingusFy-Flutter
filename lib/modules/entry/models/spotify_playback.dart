class SpotifyTrack {
  const SpotifyTrack({
    required this.name,
    required this.artists,
    this.artworkUrl,
    this.durationMs = 0,
  });

  final String name;
  final List<String> artists;
  final String? artworkUrl;
  final int durationMs;

  static SpotifyTrack? fromJson(dynamic value) {
    if (value is! Map || value['type'] != 'track') return null;
    final name = value['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final artists = <String>[];
    final seen = <String>{};
    final rawArtists = value['artists'];
    if (rawArtists is List) {
      for (final artist in rawArtists) {
        if (artist is! Map || artist['name'] is! String) continue;
        final artistName = (artist['name'] as String).trim();
        if (artistName.isNotEmpty && seen.add(artistName.toLowerCase())) {
          artists.add(artistName);
        }
      }
    }
    String? artworkUrl;
    final album = value['album'];
    if (album is Map && album['images'] is List) {
      for (final image in album['images'] as List) {
        if (image is Map &&
            image['url'] is String &&
            Uri.tryParse(image['url'])?.scheme == 'https') {
          artworkUrl = image['url'] as String;
          break;
        }
      }
    }
    return SpotifyTrack(
      name: name.trim(),
      artists: List.unmodifiable(artists),
      artworkUrl: artworkUrl,
      durationMs: value['duration_ms'] is num
          ? (value['duration_ms'] as num).toInt().clamp(0, 86400000)
          : 0,
    );
  }
}

class SpotifyPlayback {
  const SpotifyPlayback({
    required this.queue,
    this.current,
    this.isPlaying,
    this.progressMs = 0,
    this.canControl = false,
  });

  final List<SpotifyTrack> queue;
  final SpotifyTrack? current;
  final bool? isPlaying;
  final int progressMs;
  final bool canControl;

  factory SpotifyPlayback.fromJson(Map<String, dynamic> value) {
    final error = value['error'];
    if (error is String) {
      throw SpotifyPlaybackException(
        error,
        retryAfter: (value['retryAfter'] as num?)?.toInt(),
      );
    }
    final rawQueue = value['queue'];
    return SpotifyPlayback(
      queue: List.unmodifiable([
        if (rawQueue is List)
          for (final item in rawQueue)
            if (SpotifyTrack.fromJson(item) case final SpotifyTrack track)
              track,
      ]),
      current: SpotifyTrack.fromJson(value['current']),
      isPlaying: value['isPlaying'] is bool ? value['isPlaying'] as bool : null,
      progressMs: value['progressMs'] is num
          ? (value['progressMs'] as num).toInt().clamp(0, 86400000)
          : 0,
      canControl: value['canControl'] == true,
    );
  }

  /// Includes featured artists; episodes and the current track are excluded.
  List<String> get queueArtists {
    final names = <String, String>{};
    for (final track in queue) {
      for (final artist in track.artists) {
        names.putIfAbsent(artist.toLowerCase(), () => artist);
      }
    }
    return List.unmodifiable(names.values);
  }
}

class SpotifyPlaybackException implements Exception {
  const SpotifyPlaybackException(this.code, {this.retryAfter});
  final String code;
  final int? retryAfter;

  bool get needsAuthorization =>
      code == 'session_expired' ||
      code == 'forbidden' ||
      code == 'control_forbidden';

  String get message => switch (code) {
    'session_expired' => 'Sua sessão expirou. Conecte o Spotify novamente.',
    'forbidden' =>
      'O Spotify não autorizou a leitura. Reconecte sua conta e confira se ela está autorizada no app.',
    'rate_limited' =>
      'O Spotify pediu uma pausa. Tente atualizar novamente em ${retryAfter ?? 30} segundos.',
    'no_device' =>
      'Abra o Spotify e comece a tocar uma música em um dispositivo.',
    'control_forbidden' =>
      'Reconecte o Spotify para permitir o controle. A conta e o dispositivo precisam aceitar reprodução Premium.',
    'control_unavailable' =>
      'Não foi possível enviar o comando. Confira a reprodução no Spotify antes de tentar novamente.',
    _ => 'Não foi possível consultar o Spotify. Tente atualizar novamente.',
  };
}
