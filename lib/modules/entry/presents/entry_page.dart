import 'dart:async';

import 'package:bingo/modules/entry/widgets/musical_waves_background.dart';
import 'package:bingo/modules/entry/widgets/entry_floating_background.dart';
import 'package:bingo/modules/entry/widgets/entry_artist_gallery_background.dart';
import 'package:bingo/modules/entry/services/spotify_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:bingo/global/widgets/bingus_brand_mark.dart';
import 'package:bingo/global/widgets/entrance_fade.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  static const _green = Color(0xFF1ED760);
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final authenticated = await SpotifyAuth.restore();
      if (!mounted) return;
      if (authenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }
    } catch (_) {
      if (mounted) {
        _error = 'Não foi possível concluir o login. Tente novamente.';
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SpotifyAuth.signIn();
      if (!kIsWeb) await _restore();
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error =
              'O login demorou mais que o esperado. Confira sua conexão e tente novamente.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error =
              'Não foi possível concluir o login com Spotify. Tente novamente.';
        });
      }
    } finally {
      if (!kIsWeb && mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const EntryArtistGalleryBackground(),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: .85,
                  transform: _VerticalOvalGradientTransform(),
                  colors: [
                    Color(0x000A0A0A),
                    Color(0x180A0A0A),
                    Color(0xE60A0A0A),
                    Color(0xFF0A0A0A),
                  ],
                  stops: [0, .55, .9, 1],
                ),
              ),
            ),
          ),
          const EntranceFade(
            delay: Duration(milliseconds: 150),
            duration: Duration(milliseconds: 1000),
            child: EntryFloatingBackground(
              assetPath: 'assets/branding/bingusfy-dice.png',
            ),
          ),
          const EntranceFade(
            delay: Duration(milliseconds: 250),
            duration: Duration(milliseconds: 1000),
            child: EntryFloatingBackground(
              assetPath: 'assets/branding/bingusfy-trophy-transparent.png',
              lowerLeft: true,
            ),
          ),
          const EntranceFade(child: MusicalWavesBackground()),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x330A0A0A),
                    Color(0x100A0A0A),
                    Color(0x880A0A0A),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                final padding = compact
                    ? (constraints.maxWidth * .05).clamp(16.0, 24.0)
                    : 48.0;
                final shortScreen = constraints.maxHeight < 600;
                final headingSize = compact
                    ? (constraints.maxWidth * .10).clamp(30.0, 40.0)
                    : 60.0;

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          EntranceFade(
                            child: Row(
                              children: [
                                BingusBrandMark(size: compact ? 32 : 40),
                                const SizedBox(width: 10),
                                const Flexible(
                                  child: Text(
                                    'BingusFy',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: shortScreen ? 24 : 56,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: Column(
                                children:
                                    [
                                      Text(
                                        'Seu próximo bingo\ncomeça no play.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: headingSize,
                                          height: 1.08,
                                          letterSpacing: compact ? -1 : -2,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      const Text(
                                        'Transforme seus artistas favoritos em cartelas.\nReúna a galera e deixe a música fazer o resto.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFFD1D5DB),
                                          fontSize: 16,
                                          height: 1.6,
                                        ),
                                      ),
                                      const SizedBox(height: 36),
                                      Container(
                                        width: 380,
                                        padding: EdgeInsets.all(
                                          compact ? 20 : 32,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xEE101410),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: const Color(0x26FFFFFF),
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x44000000),
                                              blurRadius: 40,
                                              offset: Offset(0, 16),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            const Text(
                                              'Bem-vindo ao BingusFy',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            const Text(
                                              'Sua seleção, seu ritmo, seu jogo.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Color(0xFF9CA3AF),
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 26),
                                            FilledButton(
                                              onPressed:
                                                  !_busy &&
                                                      SpotifyAuth.configured
                                                  ? _signIn
                                                  : null,
                                              style: FilledButton.styleFrom(
                                                backgroundColor: _green,
                                                foregroundColor: const Color(
                                                  0xFF07170B,
                                                ),
                                                minimumSize:
                                                    const Size.fromHeight(54),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                    'assets/branding/spotify-icon-black.png',
                                                    width: 24,
                                                    height: 24,
                                                    frameBuilder:
                                                        fadeImageFrame,
                                                    excludeFromSemantics: true,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Flexible(
                                                    child: Text(
                                                      _busy
                                                          ? 'Conectando...'
                                                          : 'Continuar com Spotify',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!SpotifyAuth.configured) ...[
                                              const SizedBox(height: 14),
                                              const Text(
                                                'O acesso com Spotify estará disponível em breve.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Color(0xFF9CA3AF),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                            if (_error != null) ...[
                                              const SizedBox(height: 14),
                                              Text(
                                                _error!,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Color(0xFFFFB4AB),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ].withEntranceFade(
                                      delayMilliseconds: 120,
                                      intervalMilliseconds: 140,
                                    ),
                              ),
                            ),
                          ),
                          // Keep the login content centered below the header.
                          const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalOvalGradientTransform extends GradientTransform {
  const _VerticalOvalGradientTransform();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final center = bounds.center;
    return Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(.9, 1.45, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }
}
