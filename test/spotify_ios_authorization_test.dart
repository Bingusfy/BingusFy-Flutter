import 'dart:async';
import 'dart:convert';

import 'package:bingo/modules/entry/services/spotify_ios_authorization.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const redirect = 'br.com.theusmatag.bingo://spotify-callback';
  Future<AuthorizationResponse> authorize({
    Duration timeout = const Duration(seconds: 1),
  }) => SpotifyIosAuthorization.authorize(
    clientId: 'client',
    redirectUri: redirect,
    scopes: ['user-read-playback-state'],
    timeout: timeout,
  );
  void handler(Future<dynamic> Function(MethodCall) callback) => binding
      .defaultBinaryMessenger
      .setMockMethodCallHandler(SpotifyIosAuthorization.channel, callback);
  tearDown(
    () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SpotifyIosAuthorization.channel,
      null,
    ),
  );

  for (final path in ['', '/']) {
    test('valid callback $path returns matching PKCE verifier', () async {
      late Uri request;
      handler((call) async {
        request = Uri.parse(call.arguments['url'] as String);
        return '$redirect$path?code=code&state=${request.queryParameters['state']}';
      });
      final result = await authorize();
      expect(request.scheme, 'https');
      expect(request.host, 'accounts.spotify.com');
      expect(request.queryParameters['code_challenge_method'], 'S256');
      expect(request.queryParameters['redirect_uri'], redirect);
      expect(result.authorizationCode, 'code');
      expect(result.codeVerifier!.length, 43);
      expect(
        request.queryParameters['code_challenge'],
        base64UrlEncode(
          sha256.convert(ascii.encode(result.codeVerifier!)).bytes,
        ).replaceAll('=', ''),
      );
    });
  }

  for (final invalid in [
    'state',
    'host',
    'path',
    'fragment',
    'missing-code',
    'duplicate-state',
    'duplicate-code',
  ]) {
    test('rejects callback with $invalid', () async {
      handler((call) async {
        final state = Uri.parse(
          call.arguments['url'] as String,
        ).queryParameters['state'];
        return switch (invalid) {
          'state' => '$redirect?code=x&state=wrong',
          'host' => 'br.com.theusmatag.bingo://other?code=x&state=$state',
          'path' => '$redirect/other?code=x&state=$state',
          'fragment' => '$redirect?code=x&state=$state#fragment',
          'missing-code' => '$redirect?state=$state',
          'duplicate-state' => '$redirect?code=x&state=$state&state=wrong',
          _ => '$redirect?code=x&code=y&state=$state',
        };
      });
      await expectLater(authorize(), throwsFormatException);
    });
  }

  test(
    'native dismissal and denied consent both report cancellation',
    () async {
      handler((_) async => throw PlatformException(code: 'cancelled'));
      await expectLater(
        authorize(),
        throwsA(isA<FlutterAppAuthUserCancelledException>()),
      );
      handler((call) async {
        final state = Uri.parse(
          call.arguments['url'] as String,
        ).queryParameters['state'];
        return '$redirect?error=access_denied&state=$state';
      });
      await expectLater(
        authorize(),
        throwsA(isA<FlutterAppAuthUserCancelledException>()),
      );
    },
  );

  test(
    'timeout cancels the native browser and late callback cannot complete login',
    () async {
      final callback = Completer<String>();
      var cancelled = false;
      handler((call) async {
        if (call.method == 'cancel') {
          cancelled = true;
          return null;
        }
        return callback.future;
      });
      await expectLater(
        authorize(timeout: const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()),
      );
      expect(cancelled, isTrue);
      callback.complete('$redirect?code=late&state=old');
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('each attempt has a fresh state and verifier', () async {
    final states = <String>{};
    handler((call) async {
      final state = Uri.parse(
        call.arguments['url'] as String,
      ).queryParameters['state']!;
      states.add(state);
      return '$redirect?code=x&state=$state';
    });
    final first = await authorize();
    final second = await authorize();
    expect(states.length, 2);
    expect(first.codeVerifier, isNot(second.codeVerifier));
  });
}
