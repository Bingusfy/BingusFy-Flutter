export 'spotify_auth_stub.dart'
    if (dart.library.io) 'spotify_auth_native.dart'
    if (dart.library.js_interop) 'spotify_auth_web.dart';
