import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:bingo/modules/entry/models/spotify_playback.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'spotify_ios_authorization.dart';

class SpotifyAuth {
  static const _clientId = String.fromEnvironment('SPOTIFY_CLIENT_ID');
  // The web loopback URL cannot return to an installed mobile app.
  static const redirectUri = 'br.com.theusmatag.bingo://spotify-callback';
  static bool get configured =>
      _clientId.isNotEmpty &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  static final _client = SpotifyNativeClient(clientId: _clientId);

  static Future<bool> restore() async => configured && await _client.restore();
  static Future<void> signIn() async {
    if (!configured) throw StateError('Configure o Client ID do Spotify.');
    await _client.signIn();
  }

  static Future<void> signOut() => _client.signOut();
  static Future<SpotifyPlayback> loadPlayback() => _client.loadPlayback();
  static Future<void> controlPlayback(String action) =>
      _client.controlPlayback(action);
}

/// AppAuth handles the browser callback, state validation and PKCE exchange.
/// Tokens are persisted in the platform's secure storage, never in preferences.
class SpotifyNativeClient {
  SpotifyNativeClient({
    required this.clientId,
    this.authorizationTimeout = const Duration(minutes: 3),
    this.tokenTimeout = const Duration(seconds: 30),
    FlutterAppAuth appAuth = const FlutterAppAuth(),
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    Dio? dio,
  }) : _appAuth = appAuth,
       _storage = storage,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 20),
             ),
           );

  final String clientId;
  final Duration authorizationTimeout;
  final Duration tokenTimeout;
  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _storage;
  final Dio _dio;
  Map<String, dynamic>? _session;
  bool _loaded = false;
  Future<void> _operations = Future.value();
  String get _storageKey => 'bingusfy.spotify.native.$clientId';
  static const _configuration = AuthorizationServiceConfiguration(
    authorizationEndpoint: 'https://accounts.spotify.com/authorize',
    tokenEndpoint: 'https://accounts.spotify.com/api/token',
  );
  static const _scopes = [
    'user-read-currently-playing',
    'user-read-playback-state',
    'user-modify-playback-state',
  ];

  // Serialize token writes so a pending renewal cannot undo sign-out.
  Future<T> _exclusive<T>(Future<T> Function() operation) {
    final next = _operations.then((_) => operation());
    _operations = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return next;
  }

  void _trace(String message) {
    developer.log(message, name: 'SpotifyAuth');
    if (const bool.fromEnvironment('SPOTIFY_AUTH_DIAGNOSTICS')) {
      debugPrint('[SpotifyAuth] $message');
      try {
        File(
          '${Directory.systemTemp.path}/spotify-auth-diagnostics.log',
        ).writeAsStringSync(
          '${DateTime.now().toIso8601String()} $message\n',
          mode: FileMode.append,
          flush: true,
        );
      } on FileSystemException {
        // Diagnostics must never interrupt authentication.
      }
    }
  }

  Future<T> _authStep<T>(
    String stage,
    Future<T> operation,
    Duration timeout,
  ) async {
    // Log stages only: OAuth URLs, codes and tokens must never reach the logs.
    _trace('$stage: started');
    try {
      final result = await operation.timeout(timeout);
      _trace('$stage: completed');
      return result;
    } catch (error) {
      _trace('$stage: ${error.runtimeType}');
      rethrow;
    }
  }

  Future<void> signIn() => _exclusive(() async {
    try {
      // Returning from the browser completes authorization first. Exchange the
      // code separately so a stalled token request cannot hold the UI forever.
      final authorization = await _authStep(
        'authorize',
        defaultTargetPlatform == TargetPlatform.iOS
            ? SpotifyIosAuthorization.authorize(
                clientId: clientId,
                redirectUri: SpotifyAuth.redirectUri,
                scopes: _scopes,
                timeout: authorizationTimeout,
              )
            : _appAuth.authorize(
                AuthorizationRequest(
                  clientId,
                  SpotifyAuth.redirectUri,
                  serviceConfiguration: _configuration,
                  scopes: _scopes,
                ),
              ),
        defaultTargetPlatform == TargetPlatform.iOS
            ? authorizationTimeout + const Duration(seconds: 3)
            : authorizationTimeout,
      );
      final code = authorization.authorizationCode;
      final verifier = authorization.codeVerifier;
      if (code == null ||
          code.isEmpty ||
          verifier == null ||
          verifier.isEmpty) {
        throw const SpotifyPlaybackException('session_expired');
      }
      final token = await _authStep(
        'exchange',
        _appAuth.token(
          TokenRequest(
            clientId,
            SpotifyAuth.redirectUri,
            serviceConfiguration: _configuration,
            authorizationCode: code,
            codeVerifier: verifier,
            nonce: authorization.nonce,
            scopes: _scopes,
          ),
        ),
        tokenTimeout,
      );
      // A late result after timeout never reaches this write.
      await _save(token, previous: null);
      _trace('session: saved');
    } on FlutterAppAuthUserCancelledException {
      // The entry page restores the button when the user dismisses the browser.
    }
  });

  Future<void> _save(
    TokenResponse token, {
    Map<String, dynamic>? previous,
  }) async {
    if (token.accessToken == null ||
        token.accessToken!.isEmpty ||
        token.accessTokenExpirationDateTime == null) {
      throw const SpotifyPlaybackException('session_expired');
    }
    final session = <String, dynamic>{
      'accessToken': token.accessToken,
      'refreshToken': token.refreshToken ?? previous?['refreshToken'],
      'expiresAt': token.accessTokenExpirationDateTime!.millisecondsSinceEpoch,
      'scopes': token.scopes ?? previous?['scopes'] ?? _scopes,
    };
    _trace('storage.write: started');
    await _storage.write(key: _storageKey, value: jsonEncode(session));
    _trace('storage.write: completed');
    _session = session;
    _loaded = true;
  }

  Future<bool> restore({bool forceRefresh = false}) => _exclusive(() async {
    if (clientId.isEmpty) return false;
    if (!_loaded) {
      _trace('storage.read: started');
      final raw = await _storage.read(key: _storageKey);
      _trace('storage.read: completed');
      try {
        _session = raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        await _clear();
      }
      _loaded = true;
    }
    final session = _session;
    if (session == null) return false;
    final expiresAt = session['expiresAt'];
    if (!forceRefresh &&
        session['accessToken'] is String &&
        expiresAt is num &&
        expiresAt > DateTime.now().millisecondsSinceEpoch + 30000) {
      return true;
    }
    final refreshToken = session['refreshToken'];
    if (refreshToken is! String || refreshToken.isEmpty) {
      await _clear();
      return false;
    }
    // Keep the saved session on temporary network errors so users can retry.
    try {
      final token = await _authStep(
        'refresh',
        _appAuth.token(
          TokenRequest(
            clientId,
            SpotifyAuth.redirectUri,
            serviceConfiguration: _configuration,
            refreshToken: refreshToken,
          ),
        ),
        tokenTimeout,
      );
      await _save(token, previous: session);
      return true;
    } on FlutterAppAuthPlatformException catch (error) {
      if (error.platformErrorDetails.error == 'invalid_grant') {
        await _clear();
        return false;
      }
      rethrow;
    }
  });

  Future<void> _clear() async {
    _session = null;
    _loaded = true;
    await _storage.delete(key: _storageKey);
  }

  Future<void> signOut() => _exclusive(_clear);

  Future<Response<dynamic>> _request(
    String path, {
    String method = 'GET',
  }) async {
    if (!await restore()) {
      throw const SpotifyPlaybackException('session_expired');
    }
    Future<Response<dynamic>> send() => _dio.request<dynamic>(
      'https://api.spotify.com/v1/me/player/$path',
      options: Options(
        method: method,
        headers: {'Authorization': 'Bearer ${_session?['accessToken']}'},
        validateStatus: (_) => true,
      ),
    );
    try {
      var response = await send();
      if (response.statusCode == 401 && await restore(forceRefresh: true)) {
        // Retry only explicit rejection; replaying a timed-out skip is unsafe.
        response = await send();
      }
      final status = response.statusCode ?? 0;
      if (status == 401) {
        await signOut();
        throw const SpotifyPlaybackException('session_expired');
      }
      if (status == 429) {
        throw SpotifyPlaybackException(
          'rate_limited',
          retryAfter:
              int.tryParse(response.headers.value('retry-after') ?? '') ?? 30,
        );
      }
      final control = method != 'GET';
      if (status == 403) {
        throw SpotifyPlaybackException(
          control ? 'control_forbidden' : 'forbidden',
        );
      }
      if (control && status == 404) {
        throw const SpotifyPlaybackException('no_device');
      }
      if (status < 200 || status >= 300) {
        throw SpotifyPlaybackException(
          control ? 'control_unavailable' : 'unavailable',
        );
      }
      return response;
    } on DioException {
      throw SpotifyPlaybackException(
        method == 'GET' ? 'unavailable' : 'control_unavailable',
      );
    }
  }

  Future<SpotifyPlayback> loadPlayback() async {
    final responses = await Future.wait([
      _request('queue'),
      _request('currently-playing'),
    ]);
    final queue = responses[0].data is Map ? responses[0].data as Map : null;
    final playback = responses[1].data is Map ? responses[1].data as Map : null;
    return SpotifyPlayback.fromJson({
      'queue': queue?['queue'] ?? [],
      'current': playback?['item'] ?? queue?['currently_playing'],
      'isPlaying': playback?['is_playing'],
      'progressMs': playback?['progress_ms'] ?? 0,
      'canControl':
          (_session?['scopes'] as List?)?.contains(
            'user-modify-playback-state',
          ) ??
          false,
    });
  }

  Future<void> controlPlayback(String action) async {
    final method = switch (action) {
      'next' || 'previous' => 'POST',
      'play' || 'pause' => 'PUT',
      _ => throw const SpotifyPlaybackException('invalid_action'),
    };
    await _request(action, method: method);
  }
}
