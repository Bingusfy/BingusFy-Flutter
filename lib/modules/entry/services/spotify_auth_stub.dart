import 'package:bingo/modules/entry/models/spotify_playback.dart';

class SpotifyAuth {
  static const configured = false;
  static Future<bool> restore() async => false;
  static Future<void> signIn() async {
    throw StateError('O login com Spotify está disponível na versão web.');
  }

  static Future<SpotifyPlayback> loadPlayback() async =>
      throw const SpotifyPlaybackException('session_expired');
  static Future<void> signOut() async {}
  static Future<void> controlPlayback(String action) async =>
      throw const SpotifyPlaybackException('session_expired');
}
