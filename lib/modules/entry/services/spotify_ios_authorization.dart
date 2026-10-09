import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

/// The iOS browser session returns the callback directly; token exchange stays
/// in AppAuth. Each attempt owns a fresh state and PKCE verifier.
class SpotifyIosAuthorization {
  static const channel = MethodChannel('bingusfy/spotify_authorization');

  static String _random() {
    final random = Random.secure();
    return base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    ).replaceAll('=', '');
  }

  static Future<AuthorizationResponse> authorize({
    required String clientId,
    required String redirectUri,
    required List<String> scopes,
    required Duration timeout,
  }) async {
    final state = _random();
    final verifier = _random();
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');
    final url = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': scopes.join(' '),
      'state': state,
      'code_challenge_method': 'S256',
      'code_challenge': challenge,
    });
    String? response;
    try {
      response = await channel
          .invokeMethod<String>('authorize', {
            'url': url.toString(),
            'redirectUri': redirectUri,
          })
          .timeout(timeout);
    } on TimeoutException {
      // Cancel the native session too; do not leave an old browser callback
      // attached to a later attempt.
      try {
        await channel
            .invokeMethod<void>('cancel')
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        // Preserve the original timeout.
      }
      rethrow;
    } on PlatformException catch (error) {
      if (error.code == 'cancelled') {
        throw FlutterAppAuthUserCancelledException(
          code: 'cancelled',
          platformErrorDetails: FlutterAppAuthPlatformErrorDetails(),
        );
      }
      rethrow;
    }
    final callback = Uri.tryParse(response ?? '');
    final expected = Uri.parse(redirectUri);
    // A URL with an empty path may be returned with a trailing slash by iOS.
    final expectedPath = expected.path.isEmpty ? '/' : expected.path;
    final callbackPath = callback?.path.isEmpty == true ? '/' : callback?.path;
    if (callback == null ||
        callback.scheme != expected.scheme ||
        callback.host != expected.host ||
        callback.port != expected.port ||
        callback.userInfo.isNotEmpty ||
        callback.hasFragment ||
        callbackPath != expectedPath ||
        callback.queryParametersAll['state']?.length != 1 ||
        callback.queryParameters['state'] != state) {
      throw const FormatException('Retorno do Spotify inválido.');
    }
    if (callback.queryParameters.containsKey('error')) {
      if (callback.queryParameters['error'] == 'access_denied') {
        throw FlutterAppAuthUserCancelledException(
          code: 'cancelled',
          platformErrorDetails: FlutterAppAuthPlatformErrorDetails(),
        );
      }
      throw const FormatException('O Spotify não autorizou o login.');
    }
    final code = callback.queryParameters['code'];
    if (code == null ||
        code.isEmpty ||
        callback.queryParametersAll['code']?.length != 1) {
      throw const FormatException('Código de autorização ausente.');
    }
    return AuthorizationResponse(
      authorizationCode: code,
      codeVerifier: verifier,
    );
  }
}
