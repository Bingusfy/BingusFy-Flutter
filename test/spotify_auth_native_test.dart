import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bingo/modules/entry/models/spotify_playback.dart';
import 'package:bingo/modules/entry/services/spotify_auth_native.dart';
import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAppAuth extends FlutterAppAuth {
  bool cancel = false;
  Object? refreshError;
  int refreshes = 0;
  AuthorizationRequest? authorization;
  TokenRequest? exchange;
  int exchanges = 0;
  Completer<AuthorizationResponse>? pendingAuthorization;
  Completer<TokenResponse>? pendingExchange;
  TokenRequest? renewal;
  Completer<TokenResponse>? pending;

  @override
  Future<AuthorizationResponse> authorize(AuthorizationRequest request) async {
    authorization = request;
    if (cancel) {
      throw FlutterAppAuthUserCancelledException(
        code: 'cancelled',
        platformErrorDetails: FlutterAppAuthPlatformErrorDetails(),
      );
    }
    if (pendingAuthorization != null) return pendingAuthorization!.future;
    return const AuthorizationResponse(
      authorizationCode: 'code',
      codeVerifier: 'verifier',
      nonce: 'nonce',
    );
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    if (request.authorizationCode != null) {
      exchange = request;
      exchanges++;
      if (pendingExchange != null) return pendingExchange!.future;
      return TokenResponse(
        'access',
        'refresh',
        DateTime.now().add(const Duration(hours: 1)),
        null,
        'Bearer',
        null,
        null,
      );
    }
    renewal = request;
    refreshes++;
    if (refreshError != null) throw refreshError!;
    if (pending != null) return pending!.future;
    return renewedToken();
  }

  TokenResponse renewedToken() => TokenResponse(
    'renewed',
    null,
    DateTime.now().add(const Duration(hours: 1)),
    null,
    'Bearer',
    null,
    null,
  );
}

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAppAuth auth;
  late Dio dio;
  late SpotifyNativeClient client;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    auth = FakeAppAuth();
    dio = Dio();
    client = SpotifyNativeClient(
      clientId: 'test-client',
      appAuth: auth,
      dio: dio,
    );
  });

  test(
    'login uses native callback and survives restarting the client',
    () async {
      expect(await client.restore(), isFalse);
      await client.signIn();
      expect(auth.authorization!.redirectUrl, SpotifyAuth.redirectUri);
      expect(auth.exchange!.redirectUrl, SpotifyAuth.redirectUri);
      expect(auth.exchange!.authorizationCode, 'code');
      expect(auth.exchange!.codeVerifier, 'verifier');
      expect(auth.exchange!.nonce, 'nonce');
      expect(
        auth.authorization!.scopes,
        contains('user-modify-playback-state'),
      );
      final restarted = SpotifyNativeClient(
        clientId: 'test-client',
        appAuth: auth,
      );
      expect(await restarted.restore(), isTrue);
      expect(auth.refreshes, 0);
      await restarted.signOut();
      expect(
        await SpotifyNativeClient(
          clientId: 'test-client',
          appAuth: auth,
        ).restore(),
        isFalse,
      );
    },
  );

  test(
    'cancellation leaves an empty session and permits a second attempt',
    () async {
      auth.cancel = true;
      await client.signIn();
      expect(await client.restore(), isFalse);
      auth.cancel = false;
      await client.signIn();
      expect(await client.restore(), isTrue);
    },
  );

  test(
    'refresh retains refresh token and granted scopes when omitted',
    () async {
      await client.signIn();
      expect(await client.restore(forceRefresh: true), isTrue);
      expect(await client.restore(forceRefresh: true), isTrue);
      expect(auth.renewal!.refreshToken, 'refresh');
    },
  );

  test(
    'revoked refresh token clears session; network failure retains it',
    () async {
      await client.signIn();
      auth.refreshError = StateError('offline');
      await expectLater(client.restore(forceRefresh: true), throwsStateError);
      expect(await client.restore(), isTrue);
      auth.refreshError = FlutterAppAuthPlatformException(
        code: 'token_error',
        platformErrorDetails: FlutterAppAuthPlatformErrorDetails(
          error: 'invalid_grant',
        ),
      );
      expect(await client.restore(forceRefresh: true), isFalse);
      expect(await client.restore(), isFalse);
    },
  );

  test('sign-out wins over an in-flight token renewal', () async {
    await client.signIn();
    auth.pending = Completer<TokenResponse>();
    final renewal = client.restore(forceRefresh: true);
    final logout = client.signOut();
    auth.pending!.complete(auth.renewedToken());
    await renewal;
    await logout;
    expect(await client.restore(), isFalse);
  });

  test('401 retries a control once with renewed token', () async {
    await client.signIn();
    final headers = <Object?>[];
    dio.httpClientAdapter = FakeAdapter((options) {
      headers.add(options.headers['Authorization']);
      expect(options.method, 'POST');
      return ResponseBody.fromString('', headers.length == 1 ? 401 : 204);
    });
    await client.controlPlayback('next');
    expect(headers, ['Bearer access', 'Bearer renewed']);
    expect(auth.refreshes, 1);
  });

  test('network failure never repeats a skip command', () async {
    await client.signIn();
    var calls = 0;
    dio.httpClientAdapter = FakeAdapter((options) {
      calls++;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });
    await expectLater(
      client.controlPlayback('next'),
      throwsA(
        isA<SpotifyPlaybackException>().having(
          (e) => e.code,
          'code',
          'control_unavailable',
        ),
      ),
    );
    expect(calls, 1);
  });

  test(
    '429 preserves retry-after and invalid actions make no request',
    () async {
      await client.signIn();
      var calls = 0;
      dio.httpClientAdapter = FakeAdapter((options) {
        calls++;
        return ResponseBody.fromString(
          '',
          429,
          headers: {
            'retry-after': ['47'],
          },
        );
      });
      await expectLater(
        client.controlPlayback('pause'),
        throwsA(
          isA<SpotifyPlaybackException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            47,
          ),
        ),
      );
      await expectLater(
        client.controlPlayback('invalid'),
        throwsA(isA<SpotifyPlaybackException>()),
      );
      expect(calls, 1);
    },
  );

  test(
    'playback combines queue and current track; accepts no active playback',
    () async {
      await client.signIn();
      dio.httpClientAdapter = FakeAdapter(
        (options) => options.path.endsWith('/queue')
            ? ResponseBody.fromString(
                jsonEncode({
                  'queue': [
                    {
                      'type': 'track',
                      'name': 'Song',
                      'artists': [
                        {'name': 'Artist'},
                      ],
                    },
                  ],
                }),
                200,
                headers: {
                  Headers.contentTypeHeader: ['application/json'],
                },
              )
            : ResponseBody.fromString('', 204),
      );
      final playback = await client.loadPlayback();
      expect(playback.queueArtists, ['Artist']);
      expect(playback.current, isNull);
      expect(playback.canControl, isTrue);
    },
  );
  test(
    'missing callback releases queue and ignores late authorization',
    () async {
      auth.pendingAuthorization = Completer<AuthorizationResponse>();
      final stuck = auth.pendingAuthorization!;
      client = SpotifyNativeClient(
        clientId: 'test-client',
        appAuth: auth,
        authorizationTimeout: const Duration(milliseconds: 10),
      );
      await expectLater(client.signIn(), throwsA(isA<TimeoutException>()));
      expect(await client.restore(), isFalse);
      stuck.complete(
        const AuthorizationResponse(
          authorizationCode: 'late',
          codeVerifier: 'late',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(auth.exchanges, 0);
      auth.pendingAuthorization = null;
      await client.signIn();
      expect(await client.restore(), isTrue);
    },
  );

  test('stalled exchange cannot block retry or save a late token', () async {
    auth.pendingExchange = Completer<TokenResponse>();
    final stuck = auth.pendingExchange!;
    client = SpotifyNativeClient(
      clientId: 'test-client',
      appAuth: auth,
      tokenTimeout: const Duration(milliseconds: 10),
    );
    await expectLater(client.signIn(), throwsA(isA<TimeoutException>()));
    await client.signOut();
    stuck.complete(auth.renewedToken());
    await Future<void>.delayed(Duration.zero);
    expect(await client.restore(), isFalse);
    auth.pendingExchange = null;
    await client.signIn();
    expect(await client.restore(), isTrue);
  });

  test('missing PKCE verifier prevents token exchange', () async {
    auth.pendingAuthorization = Completer<AuthorizationResponse>()
      ..complete(const AuthorizationResponse(authorizationCode: 'code'));
    await expectLater(
      client.signIn(),
      throwsA(isA<SpotifyPlaybackException>()),
    );
    expect(auth.exchanges, 0);
    expect(await client.restore(), isFalse);
  });

  test('a stuck renewal releases queued sign-out', () async {
    client = SpotifyNativeClient(
      clientId: 'test-client',
      appAuth: auth,
      tokenTimeout: const Duration(milliseconds: 10),
    );
    await client.signIn();
    auth.pending = Completer<TokenResponse>();
    final renewal = client.restore(forceRefresh: true);
    final logout = client.signOut();
    await expectLater(renewal, throwsA(isA<TimeoutException>()));
    await logout;
    auth.pending!.complete(auth.renewedToken());
    await Future<void>.delayed(Duration.zero);
    expect(await client.restore(), isFalse);
  });
}
