import 'dart:js_interop';
import 'dart:convert';
import 'package:bingo/modules/entry/models/spotify_playback.dart';

@JS('bingusSpotifySignIn')
external JSPromise<JSAny?> _signIn(JSString clientId, JSString redirectUri);

@JS('bingusSpotifyRestore')
external JSPromise<JSBoolean> _restore(JSString clientId, JSString redirectUri);

@JS('bingusSpotifyPlayback')
external JSPromise<JSString> _playback(JSString clientId, JSString redirectUri);

@JS('bingusSpotifySignOut')
external void _signOut();

@JS('bingusSpotifyControl')
external JSPromise<JSString> _control(
  JSString clientId,
  JSString redirectUri,
  JSString action,
);

class SpotifyAuth {
  static const _clientId = String.fromEnvironment('SPOTIFY_CLIENT_ID');
  static const _redirectUri = String.fromEnvironment('SPOTIFY_REDIRECT_URI');
  static const configured = _clientId != '' && _redirectUri != '';

  static Future<bool> restore() async {
    return (await _restore(_clientId.toJS, _redirectUri.toJS).toDart).toDart;
  }

  static Future<void> signIn() async {
    await _signIn(_clientId.toJS, _redirectUri.toJS).toDart;
  }

  static Future<SpotifyPlayback> loadPlayback() async {
    final json = (await _playback(
      _clientId.toJS,
      _redirectUri.toJS,
    ).toDart).toDart;
    return SpotifyPlayback.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  static Future<void> signOut() async => _signOut();

  static Future<void> controlPlayback(String action) async {
    final result =
        jsonDecode(
              (await _control(
                _clientId.toJS,
                _redirectUri.toJS,
                action.toJS,
              ).toDart).toDart,
            )
            as Map<String, dynamic>;
    if (result['error'] is String) {
      throw SpotifyPlaybackException(
        result['error'] as String,
        retryAfter: (result['retryAfter'] as num?)?.toInt(),
      );
    }
  }
}

