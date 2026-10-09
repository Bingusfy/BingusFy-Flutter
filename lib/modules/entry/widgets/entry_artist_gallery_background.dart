import 'dart:math' as math;

import 'package:flutter/material.dart';

class EntryArtistGalleryBackground extends StatefulWidget {
  const EntryArtistGalleryBackground({super.key});

  @override
  State<EntryArtistGalleryBackground> createState() =>
      _EntryArtistGalleryBackgroundState();
}

class _EntryArtistGalleryBackgroundState
    extends State<EntryArtistGalleryBackground>
    with SingleTickerProviderStateMixin {
  static const _photos = [
    'assets/artists/taylor-swift.jpg',
    'assets/artists/the-weeknd.jpg',
    'assets/artists/dua-lipa.jpg',
    'assets/artists/bruno-mars.jpg',
    'assets/artists/rihanna.jpg',
    'assets/artists/adele.jpg',
    'assets/artists/billie-eilish.jpg',
    'assets/artists/ariana-grande.jpg',
    'assets/artists/ed-sheeran.jpg',
    'assets/artists/beyonce.jpg',
    'assets/artists/drake.jpg',
    'assets/artists/kendrick-lamar.jpg',
    'assets/artists/harry-styles.jpg',
    'assets/artists/bad-bunny.jpg',
    'assets/artists/miley-cyrus.jpg',
    'assets/artists/post-malone.jpg',
    'assets/artists/coldplay.jpg',
    'assets/artists/imagine-dragons.jpg',
    'assets/artists/anitta.jpg',
    'assets/artists/ludmilla.jpg',
    'assets/artists/pabllo-vittar.jpg',
    'assets/artists/claudia-leitte.jpg',
    'assets/artists/luisa-sonza.jpg',
    'assets/artists/caetano-veloso.jpg',
    'assets/artists/gilberto-gil.jpg',
  ];
  final _seed = math.Random().nextInt(1 << 30);
  late final _photoOrder = List<String>.of(_photos)
    ..shuffle(math.Random(_seed));
  bool _loadingStarted = false;
  bool _imagesReady = false;
  int _laps = 0;
  double _previousValue = 0;
  late final AnimationController _motion =
      AnimationController(vsync: this, duration: const Duration(days: 1))
        ..addListener(() {
          // Keep travel continuous even if this page stays open for a full day.
          if (_motion.value < _previousValue) _laps++;
          _previousValue = _motion.value;
        });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadingStarted) {
      _loadingStarted = true;
      _preparePhotos();
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  Future<void> _preparePhotos() async {
    // Decode the small local photos before displaying any cards. Recycling a
    // card can then use the image cache without a second loading animation.
    await Future.wait(
      _photos.map((photo) => precacheImage(AssetImage(photo), context)),
    );
    if (mounted) setState(() => _imagesReady = true);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!_imagesReady) return const SizedBox.expand();
          final compact = constraints.maxWidth < 600;
          final gap = compact ? 4.0 : 7.0;
          final galleryWidth = constraints.maxWidth * .8;
          final columns = compact
              ? 10
              : constraints.maxWidth < 1000
              ? 14
              : (galleryWidth / 64).ceil().clamp(18, 32);
          final width = (galleryWidth - gap * (columns - 1)) / columns;
          final height = width;
          final spacing = height + gap;
          final rows = (constraints.maxHeight / spacing).ceil() + 2;
          final period = rows * spacing;
          final left = (constraints.maxWidth - galleryWidth) / 2;
          return ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const RadialGradient(
              center: Alignment(0, .04),
              radius: .62,
              transform: _GalleryCenterFadeTransform(),
              colors: [Colors.transparent, Colors.transparent, Colors.white],
              stops: [0, .46, 1],
            ).createShader(bounds),
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                // Leave the middle band clear for the sound waves at 56% height.
                stops: [0, .16, .3, .44, .68, .82, .9, 1],
              ).createShader(bounds),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: compact ? .19 : .25),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(seconds: 3),
                builder: (context, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, _) {
                    final seconds = (_laps + _motion.value) * 86400;
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        for (var column = 0; column < columns; column++)
                          for (var row = 0; row < rows; row++)
                            _buildCard(
                              column: column,
                              columns: columns,
                              row: row,
                              seconds: seconds,
                              compact: compact,
                              left: left + column * (width + gap),
                              width: width,
                              height: height,
                              spacing: spacing,
                              period: period,
                              viewportHeight: constraints.maxHeight,
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _buildCard({
    required int column,
    required int columns,
    required int row,
    required double seconds,
    required bool compact,
    required double left,
    required double width,
    required double height,
    required double spacing,
    required double period,
    required double viewportHeight,
  }) {
    // A shared pace keeps the mosaic evenly spaced. A small stagger avoids
    // synchronized entrances without opening large gaps between cards.
    final speed = compact ? 3.5 : 5.0;
    final travel =
        row * spacing + (column % 3) * spacing * .12 + seconds * speed;
    final cycle = (travel / period).floor();
    final distance = travel % period;
    final top = viewportHeight - distance;
    final random = math.Random(
      _seed + column * 100003 + row * 1009 + cycle * 7919,
    );
    // A shuffled deck distributes every artist before repeating. Assets change
    // only when a card recycles below the screen, with no visible swaps.
    final photo =
        _photoOrder[(row * columns + column + cycle * 7) % _photos.length];
    final fadeDistance = height + speed * (4 + random.nextDouble() * 4);
    final entrance = Curves.easeInOutSine.transform(
      (distance / fadeDistance).clamp(0.0, 1.0),
    );
    final exit = Curves.easeInOutSine.transform(
      ((viewportHeight + height - distance) / fadeDistance).clamp(0.0, 1.0),
    );
    return Positioned(
      key: ValueKey('$column:$row'),
      left: left,
      top: top,
      width: width,
      height: height,
      child: Opacity(
        opacity: entrance * exit,
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 4 : 7),
            child: ColoredBox(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    photo,
                    key: ValueKey('$column:$row:$cycle'),
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -.25),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x08101A13), Color(0x700A0A0A)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryCenterFadeTransform extends GradientTransform {
  const _GalleryCenterFadeTransform();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final center = bounds.center;
    return Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(.95, 1.2, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }
}
