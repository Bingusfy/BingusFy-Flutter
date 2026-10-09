import 'package:bingo/modules/home/models/boards.model.dart';
import 'package:bingo/modules/home/models/tile.model.dart';
import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:bingo/modules/home/presents/widgets/spotify_playback_panel.dart';
import 'package:bingo/modules/home/presents/widgets/home_design.dart';
import 'package:bingo/modules/home/presents/widgets/spotify_mini_player.dart';
import 'package:bingo/modules/rooms/presents/room_lobby_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.homeController, this.roomPanel});
  final HomeController? homeController;
  final Widget? roomPanel;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController controller;
  late final String _controllerTag = 'home-${identityHashCode(this)}';
  bool _isInitializing = true;
  final _scrollController = ScrollController();
  final _mainPlayerKey = GlobalKey();
  final _viewportKey = GlobalKey();
  final _showMiniPlayer = ValueNotifier(false);
  bool _visibilityCheckScheduled = false;

  void _schedulePlayerVisibilityCheck() {
    if (_visibilityCheckScheduled || !mounted) return;
    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;
      if (!mounted) return;
      final player = _mainPlayerKey.currentContext?.findRenderObject();
      final viewport = _viewportKey.currentContext?.findRenderObject();
      if (player is! RenderBox ||
          viewport is! RenderBox ||
          !player.hasSize ||
          !viewport.hasSize) {
        return;
      }
      final playerBounds = player.localToGlobal(Offset.zero) & player.size;
      final viewportBounds =
          viewport.localToGlobal(Offset.zero) & viewport.size;
      _showMiniPlayer.value = !playerBounds.overlaps(viewportBounds);
    });
  }

  void _openMainPlayer() {
    final playerContext = _mainPlayerKey.currentContext;
    if (playerContext != null) {
      Scrollable.ensureVisible(
        playerContext,
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  double _pageHorizontalPadding(double width) {
    if (width < 640) return 16;
    if (width < 1024) return 24;
    return 32;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_schedulePlayerVisibilityCheck);
    // Get the controller from GetIt and register it with GetX
    controller = widget.homeController ?? GetIt.I.get<HomeController>();

    // This page owns the lifecycle, including transitions from home into a room.
    Get.put(controller, tag: _controllerTag, permanent: true);

    // Aguarda o próximo frame para garantir que o GetX esteja pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Simula um tempo mínimo de loading para evitar flicker
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showMiniPlayer.dispose();
    // Remove o controller do GetX quando o widget for descartado
    if (Get.isRegistered<HomeController>(tag: _controllerTag)) {
      Get.delete<HomeController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update screen dimensions in controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      controller.updateScreenSize(size.width, size.height);
    });

    _schedulePlayerVisibilityCheck();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Theme(
        data: Theme.of(context).copyWith(
          sliderTheme: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            inactiveTrackColor: const Color(0xFF2A3730),
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
            tickMarkShape: SliderTickMarkShape.noTickMark,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayColor: const Color(0x141ED760),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        child: _isInitializing ? _buildLoadingScreen() : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BingusBrandMark(size: 96),
          const SizedBox(height: 32),

          // Loading indicator
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                HomeController.primaryColor,
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),

          // Texto de loading
          const Text(
            'Carregando BingusFy...',
            style: TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Preparando sua experiência musical',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Main content
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 640;
              final isTablet =
                  constraints.maxWidth >= 640 && constraints.maxWidth < 1024;

              return NotificationListener<ScrollMetricsNotification>(
                onNotification: (_) {
                  _schedulePlayerVisibilityCheck();
                  return false;
                },
                child: SingleChildScrollView(
                  key: _viewportKey,
                  controller: _scrollController,
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: _pageHorizontalPadding(
                          constraints.maxWidth,
                        ),
                        vertical: isMobile
                            ? 16
                            : isTablet
                            ? 24
                            : 32,
                      ),
                      child: Column(
                        children: [
                          // Background gradients overlay
                          Stack(
                            children: [
                              // Gradient backgrounds (only on larger screens)
                              if (!isMobile) ...[
                                Positioned(
                                  top: -100,
                                  left: -200,
                                  child: Container(
                                    width: 600,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          HomeController.primaryColor
                                              .withValues(alpha: 0.2),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.6],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -100,
                                  right: -200,
                                  child: Container(
                                    width: 500,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          HomeController.primaryColor
                                              .withValues(alpha: 0.1),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.6],
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // Main content
                              Column(
                                children: [
                                  // Hero/Search section
                                  const HomeIntro(),
                                  widget.roomPanel ??
                                      RoomLobbyPanel(controller: controller),
                                  NotificationListener<
                                    SizeChangedLayoutNotification
                                  >(
                                    onNotification: (_) {
                                      _schedulePlayerVisibilityCheck();
                                      return false;
                                    },
                                    child: SizeChangedLayoutNotifier(
                                      child: SpotifyPlaybackPanel(
                                        controller: controller,
                                        playerVisibilityKey: _mainPlayerKey,
                                      ),
                                    ),
                                  ),
                                  if (!controller.isRoom)
                                    _buildMainSection(context),
                                  SizedBox(
                                    height: isMobile
                                        ? 20
                                        : isTablet
                                        ? 28
                                        : 32,
                                  ),

                                  // Boards section
                                  _buildBoardsSection(),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        ValueListenableBuilder<bool>(
          valueListenable: _showMiniPlayer,
          builder: (context, show, _) {
            if (!show) return const SizedBox.shrink();
            return Obx(() {
              if (controller.spotifyPlayback.value?.current == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  _pageHorizontalPadding(MediaQuery.sizeOf(context).width),
                  8,
                  _pageHorizontalPadding(MediaQuery.sizeOf(context).width),
                  12,
                ),
                child: SpotifyMiniPlayer(
                  controller: controller,
                  onOpenPlayer: _openMainPlayer,
                ),
              );
            });
          },
        ),
        // Footer
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;
        final isTablet =
            constraints.maxWidth >= 640 && constraints.maxWidth < 1024;

        return Container(
          height: isMobile ? 56 : 64,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withValues(alpha: 0.7),
            border: const Border(
              bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1),
            ),
          ),
          child: Center(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                horizontal: _pageHorizontalPadding(constraints.maxWidth),
              ),
              child: isMobile
                  ? _buildMobileHeader()
                  : _buildDesktopHeader(isTablet),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader() {
    return Row(
      children: [
        const BingusBrandMark(size: 32),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'BingusFy',
            style: TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Menu hamburger ou ação principal
        if (!controller.isRoom)
          IconButton(
            onPressed: controller.shuffleSample,
            icon: const Icon(Icons.shuffle, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFFD1D5DB),
              side: const BorderSide(color: Color(0x1AFFFFFF)),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopHeader(bool isTablet) {
    return Row(
      children: [
        const BingusBrandMark(size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BingusFy',
                style: TextStyle(
                  color: Color(0xFFF1F5F2),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.4,
                ),
              ),
              if (!isTablet)
                const Text(
                  'Seu ritmo. Seu jogo.',
                  style: TextStyle(color: HomeDesign.muted, fontSize: 12),
                ),
            ],
          ),
        ),

        // Actions
        if (!controller.isRoom)
          Row(
            children: [
              if (isTablet)
                IconButton(
                  onPressed: controller.shuffleSample,
                  icon: const Icon(Icons.shuffle, size: 18),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFFD1D5DB),
                    side: const BorderSide(color: Color(0x1AFFFFFF)),
                  ),
                )
              else ...[
                TextButton.icon(
                  onPressed: controller.shuffleSample,
                  icon: const Icon(Icons.shuffle, size: 16),
                  label: const Text('Artistas aleatórios'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD1D5DB),
                    side: const BorderSide(color: Color(0x1AFFFFFF)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Como funciona'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF9CA3AF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildMainSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;
        final isTablet =
            constraints.maxWidth >= 640 && constraints.maxWidth < 1024;

        if (isMobile) {
          return Column(
            children: [
              _buildSearchSection(),
              const SizedBox(height: 16),
              _buildOptionsPanel(),
            ],
          );
        } else if (isTablet) {
          return Column(
            children: [
              _buildSearchSection(),
              const SizedBox(height: 20),
              _buildOptionsPanel(),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSearchSection()),
              const SizedBox(width: 24),
              SizedBox(width: 380, child: _buildOptionsPanel()),
            ],
          );
        }
      },
    );
  }

  Widget _buildSearchSection() {
    return Obx(() {
      return Container(
        decoration: HomeDesign.surface(),
        padding: EdgeInsets.all(controller.isMobile ? 20 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            controller.isMobile
                ? _buildMobileSearchHeader()
                : _buildDesktopSearchHeader(),
            SizedBox(height: controller.isMobile ? 10 : 12),

            // Search input
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF0A0A0A),
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    focusNode: controller.searchFocusNode,
                    onTap: () => controller.onSearchFocus(),
                    onChanged: (value) => controller.onSearchChanged(value),
                    onSubmitted: (value) => controller.onSearchSubmitted(value),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: controller.isMobile ? 16 : 14,
                    ),
                    decoration: InputDecoration(
                      hintText: controller.isMobile
                          ? 'Pesquise artistas...'
                          : 'Pesquise artistas ou pressione Enter para adicionar…',
                      hintStyle: const TextStyle(color: HomeDesign.muted),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                // Suggestions
                Obx(() {
                  if (!controller.showSuggestions.value ||
                      controller.suggestions.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: controller.isMobile ? 200 : 288,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xF50A0A0A),
                        border: Border.all(color: const Color(0x1AFFFFFF)),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: controller.suggestions.length,
                        itemBuilder: (context, index) {
                          final artist = controller.suggestions[index];
                          return ListTile(
                            title: Text(
                              artist,
                              style: TextStyle(
                                color: const Color(0xFFE5E7EB),
                                fontSize: controller.isMobile ? 16 : 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            trailing: const Icon(
                              Icons.add,
                              color: Color(0xFF9CA3AF),
                              size: 16,
                            ),
                            onTap: () => controller.addArtist(artist),
                            dense: !controller.isMobile,
                            hoverColor: const Color(0x0DFFFFFF),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
            SizedBox(height: controller.isMobile ? 12 : 16),

            // Selected artists header
            controller.isMobile
                ? _buildMobileArtistsHeader()
                : _buildDesktopArtistsHeader(),
            SizedBox(height: controller.isMobile ? 6 : 8),

            // Selected artists display
            Obx(() {
              if (controller.selectedArtists.isEmpty) {
                return Container(
                  height: controller.isMobile ? 48 : 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF0A0A0A),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_upward,
                        color: HomeDesign.muted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.isMobile
                              ? 'Adicione artistas acima.'
                              : 'Comece adicionando artistas da pesquisa acima.',
                          style: TextStyle(
                            color: HomeDesign.muted,
                            fontSize: controller.isMobile ? 14 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: controller.isMobile ? 48 : 44,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF0A0A0A),
                ),
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: controller.isMobile ? 6 : 8,
                  runSpacing: controller.isMobile ? 6 : 8,
                  children: controller.selectedArtists
                      .map(
                        (artist) =>
                            _buildArtistChip(artist, controller.isMobile),
                      )
                      .toList(),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildMobileSearchHeader() =>
      _buildArtistsSectionHeading(compact: true);
  Widget _buildDesktopSearchHeader() => _buildArtistsSectionHeading();
  Widget _buildArtistsSectionHeading({bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Sua seleção de artistas',
              style: TextStyle(
                fontSize: compact ? 20 : 23,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
                color: const Color(0xFFF1F5F2),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: HomeController.primaryBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0x261ED760)),
              ),
              child: Text(
                '${controller.selectedArtists.length} selecionados',
                style: const TextStyle(
                  color: HomeController.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Adicione da fila ou encontre um artista para entrar no jogo.',
          style: TextStyle(color: HomeDesign.muted, fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMobileArtistsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artistas selecionados',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: controller.artistsDb.isEmpty
                    ? null
                    : controller.importQueueArtists,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD1D5DB),
                  side: const BorderSide(color: Color(0x1AFFFFFF)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 44),
                  visualDensity: VisualDensity.standard,
                ),
                child: const Text('Da fila', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(
                onPressed: controller.clearSelectedArtists,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDCAA8C),
                  side: const BorderSide(color: Color(0x1AFFFFFF)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 44),
                  visualDensity: VisualDensity.standard,
                ),
                child: const Text('Limpar', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopArtistsHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        const Text(
          'Artistas selecionados',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
        Row(
          children: [
            TextButton(
              onPressed: controller.artistsDb.isEmpty
                  ? null
                  : controller.importQueueArtists,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD1D5DB),
                side: const BorderSide(color: Color(0x1AFFFFFF)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 40),
                visualDensity: VisualDensity.standard,
              ),
              child: const Text(
                'Adicionar artistas da fila',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: controller.clearSelectedArtists,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDCAA8C),
                side: const BorderSide(color: Color(0x1AFFFFFF)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 40),
                visualDensity: VisualDensity.standard,
              ),
              child: const Text('Limpar tudo', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArtistChip(String artist, [bool isMobile = false]) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isMobile ? 200 : 180, // Limita a largura máxima
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C3023),
        border: Border.all(color: const Color(0x301ED760)),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 8 : 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note_rounded,
            color: HomeController.primaryColor,
            size: isMobile ? 16 : 14,
          ),
          SizedBox(width: isMobile ? 8 : 6),
          Flexible(
            child: Text(
              artist,
              style: TextStyle(
                color: const Color(0xFFE5E7EB),
                fontSize: isMobile ? 16 : 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 6),
          GestureDetector(
            onTap: () => controller.removeArtist(artist),
            child: Icon(
              Icons.close,
              color: HomeDesign.muted,
              size: isMobile ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        return Container(
          decoration: HomeDesign.surface(),
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalize o jogo',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // Number of boards
              _buildNumberOfBoardsControl(isMobile),
              SizedBox(height: isMobile ? 12 : 16),

              // Grid size
              _buildGridSizeControl(isMobile),
              SizedBox(height: isMobile ? 12 : 16),

              // Blank tiles percentage
              _buildBlankTilesControl(isMobile),
              SizedBox(height: isMobile ? 12 : 16),

              // Free center switch
              _buildFreeCenterControl(isMobile),
              SizedBox(height: isMobile ? 16 : 20),

              // Action buttons
              isMobile
                  ? _buildMobileActionButtons()
                  : _buildDesktopActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => controller.generateBoards(),
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text(
            'Gerar tabelas',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(double.maxFinite, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: HomeController.primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.maxFinite,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => {}, // Print functionality
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Imprimir'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x1AFFFFFF)),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.generateBoards,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text(
              'Gerar tabelas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(double.maxFinite, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: HomeController.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => {}, // Print functionality
          icon: const Icon(Icons.print, size: 16),
          style: IconButton.styleFrom(
            side: const BorderSide(color: Color(0x1AFFFFFF)),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberOfBoardsControl([bool isMobile = false]) {
    return Obx(
      () => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Número de tabelas',
                style: TextStyle(
                  color: const Color(0xFFD1D5DB),
                  fontSize: isMobile ? 16 : 14,
                ),
              ),
              Text(
                '${controller.numBoards.value}',
                style: TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: isMobile ? 14 : 12,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 8),
          Row(
            children: [
              IconButton(
                onPressed: controller.decrementBoards,
                icon: Icon(Icons.remove, size: isMobile ? 20 : 16),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0x1AFFFFFF)),
                  foregroundColor: Colors.white,
                  fixedSize: Size(isMobile ? 44 : 36, isMobile ? 44 : 36),
                ),
              ),
              Expanded(
                child: Slider(
                  value: controller.numBoards.value.toDouble(),
                  min: 1,
                  max: 24,
                  divisions: 23,
                  activeColor: HomeController.primaryColor,
                  onChanged: (value) => controller.setNumBoards(value.round()),
                ),
              ),
              IconButton(
                onPressed: controller.incrementBoards,
                icon: Icon(Icons.add, size: isMobile ? 20 : 16),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0x1AFFFFFF)),
                  foregroundColor: Colors.white,
                  fixedSize: Size(isMobile ? 44 : 36, isMobile ? 44 : 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridSizeControl([bool isMobile = false]) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tamanho da grade',
            style: TextStyle(
              color: const Color(0xFFD1D5DB),
              fontSize: isMobile ? 16 : 14,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 8),
          Row(
            children: [3, 4, 5].map((size) {
              final isSelected = controller.gridSize.value == size;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: size == 3 ? 0 : 4,
                    right: size == 5 ? 0 : 4,
                  ),
                  child: GestureDetector(
                    onTap: () => controller.setGridSize(size),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? HomeController.primaryBg : null,
                        border: Border.all(
                          color: isSelected
                              ? HomeController.primaryBorder
                              : const Color(0x1AFFFFFF),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$size × $size',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFD7FBE6)
                                : const Color(0xFFD1D5DB),
                            fontSize: isMobile ? 16 : 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBlankTilesControl([bool isMobile = false]) {
    return Obx(
      () => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Espaços em branco',
                  style: TextStyle(
                    color: const Color(0xFFD1D5DB),
                    fontSize: isMobile ? 16 : 14,
                  ),
                ),
              ),
              Text(
                '${controller.blankPercent.value}%',
                style: TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: isMobile ? 14 : 12,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 8),
          Slider(
            value: controller.blankPercent.value.toDouble(),
            min: 0,
            max: 60,
            divisions: 12,
            activeColor: HomeController.primaryColor,
            onChanged: (value) => controller.setBlankPercent(value.round()),
          ),
          Text(
            'Distribua espaços livres para variar o desafio.',
            style: TextStyle(
              color: HomeDesign.muted,
              fontSize: isMobile ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeCenterControl([bool isMobile = false]) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Centro livre (grades ímpares)',
              style: TextStyle(
                color: const Color(0xFFD1D5DB),
                fontSize: isMobile ? 16 : 14,
              ),
            ),
          ),
          CupertinoSwitch(
            value: controller.freeCenter.value,
            onChanged: (_) => controller.toggleFreeCenter(),

            trackOutlineColor: WidgetStateProperty.all(
              controller.freeCenter.value
                  ? HomeController.primaryColor.withAlpha(70)
                  : Colors.grey.withAlpha(70),
            ),

            activeTrackColor: HomeController.primaryColor.withAlpha(50),

            thumbColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildBoardsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        return Obx(
          () => Column(
            children: [
              // Header
              isMobile
                  ? _buildMobileBoardsHeader()
                  : _buildDesktopBoardsHeader(),
              SizedBox(height: isMobile ? 8 : 12),

              if (controller.showEmptyState.value)
                _buildEmptyState()
              else
                _buildBoardsGrid(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileBoardsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tabelas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Toque nos artistas para marcar',
                style: TextStyle(color: HomeDesign.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopBoardsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Tabelas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const Flexible(
          child: Text(
            'Clique nos artistas para marcar enquanto joga',
            style: TextStyle(color: HomeDesign.muted, fontSize: 12),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: controller.isMobile ? 24 : 40,
        vertical: 40,
      ),
      decoration: HomeDesign.surface(),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: HomeController.primaryBg,
              border: Border.all(color: HomeController.primaryBorder),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.music_note,
              color: HomeController.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma tabela adicionada',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pesquise e adicione artistas, ajuste as opções e, em seguida, gere tabelas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth < 640) {
          // Mobile: 1 coluna
          crossAxisCount = 1;
          childAspectRatio = 0.8;
        } else if (constraints.maxWidth < 1024) {
          // Tablet: 2 colunas
          crossAxisCount = 2;
          childAspectRatio = 0.9;
        } else if (constraints.maxWidth < 1440) {
          // Desktop pequeno: 2 colunas
          crossAxisCount = 2;
          childAspectRatio = 1.0;
        } else {
          // Desktop grande: 3 colunas
          crossAxisCount = 3;
          childAspectRatio = 1.0;
        }

        return Obx(() {
          final boards = controller.boards.toList();
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: constraints.maxWidth < 640 ? 16 : 20,
              mainAxisSpacing: constraints.maxWidth < 640 ? 16 : 20,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: boards.length,
            itemBuilder: (context, index) {
              final board = boards[index];
              return _buildBoardCard(board, index);
            },
          );
        });
      },
    );
  }

  Widget _buildBoardCard(BingoBoard board, int boardIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 300;

        return Semantics(
          container: true,
          label: 'Tabela de ${board.ownerName ?? board.id}',
          explicitChildNodes: true,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Intercepta e consome o scroll dentro da tabela
              return true;
            },
            child: Container(
              decoration: HomeDesign.surface(),
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                children: [
                  // Board header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          board.ownerName == null
                              ? 'Tabela ${board.id}'
                              : 'Tabela · ${board.ownerName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF9CA3AF),
                            fontSize: isMobile ? 16 : 14,
                          ),
                        ),
                      ),
                      if (controller.isRoom && board.canMark)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: HomeController.primaryBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: HomeController.primaryBorder,
                            ),
                          ),
                          child: const Text(
                            'Sua tabela',
                            style: TextStyle(
                              color: HomeController.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (!controller.isRoom)
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  controller.clearBoardMarks(boardIndex),
                              icon: Icon(Icons.clear, size: isMobile ? 18 : 16),
                              style: IconButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0x1AFFFFFF),
                                ),
                                foregroundColor: Colors.white,
                                fixedSize: Size(
                                  isMobile ? 36 : 32,
                                  isMobile ? 36 : 32,
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 6 : 4),
                            IconButton(
                              onPressed: () =>
                                  controller.shuffleBoard(boardIndex),
                              icon: Icon(
                                Icons.casino,
                                size: isMobile ? 18 : 16,
                              ),
                              style: IconButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0x1AFFFFFF),
                                ),
                                foregroundColor: Colors.white,
                                fixedSize: Size(
                                  isMobile ? 36 : 32,
                                  isMobile ? 36 : 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 8 : 12),

                  // Board grid com scroll próprio e interceptação de eventos
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, gridConstraints) {
                        // Calcula o tamanho necessário para a grid
                        final spacingSize = isMobile ? 4.0 : 6.0;
                        final tileSize =
                            (gridConstraints.maxWidth -
                                (board.gridSize - 1) * spacingSize) /
                            board.gridSize;
                        final totalHeight =
                            tileSize * board.gridSize +
                            (board.gridSize - 1) * spacingSize;

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: SizedBox(
                            height: totalHeight > gridConstraints.maxHeight
                                ? totalHeight
                                : gridConstraints.maxHeight,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: board.gridSize,
                                    crossAxisSpacing: spacingSize,
                                    mainAxisSpacing: spacingSize,
                                  ),
                              itemCount: board.tiles.length,
                              itemBuilder: (context, tileIndex) {
                                final tile = board.tiles[tileIndex];
                                return _buildBoardTile(
                                  tile,
                                  boardIndex,
                                  tileIndex,
                                  isMobile,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoardTile(
    BingoTile tile,
    int boardIndex,
    int tileIndex, [
    bool isMobile = false,
  ]) {
    final canMark =
        controller.boards[boardIndex].canMark &&
        tile.type == BingoTileType.artist;
    return Semantics(
      button: true,
      enabled: canMark,
      toggled: tile.isMarked,
      excludeSemantics: true,
      label: tile.content?.isNotEmpty == true ? tile.content : 'Espaço vazio',
      child: GestureDetector(
        onTap: canMark
            ? () => controller.toggleTileMark(boardIndex, tileIndex)
            : null,
        child: Container(
          constraints: BoxConstraints(
            minHeight: isMobile ? 60 : 80, // Altura mínima garantida
          ),
          decoration: BoxDecoration(
            color: tile.isMarked
                ? HomeController.primaryBg
                : tile.type == BingoTileType.free
                ? HomeController.primaryBg
                : null,
            border: Border.all(
              color: tile.isMarked
                  ? HomeController.primaryBorder
                  : tile.type == BingoTileType.free
                  ? HomeController.primaryBorder
                  : const Color(0x1AFFFFFF),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildTileContent(tile, isMobile),
        ),
      ),
    );
  }

  Widget _buildTileContent(BingoTile tile, [bool isMobile = false]) {
    switch (tile.type) {
      case BingoTileType.free:
        return Padding(
          padding: EdgeInsets.all(isMobile ? 2 : 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FREE',
                style: TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: isMobile ? 7 : 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isMobile ? 1 : 2),
              Text(
                'Center',
                style: TextStyle(
                  color: HomeController.primaryColor,
                  fontSize: isMobile ? 10 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case BingoTileType.blank:
        return Padding(
          padding: EdgeInsets.all(isMobile ? 2 : 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note,
                color: HomeDesign.muted,
                size: isMobile ? 12 : 14,
              ),
              SizedBox(height: isMobile ? 1 : 2),
              Text(
                'Em branco',
                style: TextStyle(
                  color: HomeDesign.muted,
                  fontSize: isMobile ? 8 : 10,
                ),
              ),
            ],
          ),
        );
      case BingoTileType.artist:
        return Padding(
          padding: EdgeInsets.all(isMobile ? 2 : 3), // Padding reduzido
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Usa tamanho mínimo
            children: [
              Text(
                'Artista',
                style: TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: isMobile ? 6 : 8, // Fonte ainda menor
                ),
              ),
              SizedBox(height: isMobile ? 1 : 1),
              Expanded(
                child: Center(
                  child: Text(
                    tile.content ?? '',
                    style: TextStyle(
                      color: const Color(0xFFE5E7EB),
                      fontSize: isMobile ? 8 : 10, // Fonte mais reduzida
                      fontWeight: FontWeight.w500,
                      height: 1.0, // Altura de linha mais compacta
                    ),
                    textAlign: TextAlign.center,
                    maxLines: isMobile ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildFooter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        return Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _pageHorizontalPadding(constraints.maxWidth),
            vertical: isMobile ? 16 : 24,
          ),
          child: Center(
            child: SizedBox(
              width: double.infinity,
              child: isMobile ? _buildMobileFooter() : _buildDesktopFooter(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileFooter() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BingusBrandMark(size: 28),
            SizedBox(width: 8),
            Text('•', style: TextStyle(color: HomeDesign.muted, fontSize: 12)),
            SizedBox(width: 8),
            Text(
              'BingusFy',
              style: TextStyle(color: HomeDesign.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'Termos',
                style: TextStyle(color: HomeDesign.muted, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Privacidade',
                style: TextStyle(color: HomeDesign.muted, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Feedback',
                style: TextStyle(color: HomeDesign.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            BingusBrandMark(size: 28),
            SizedBox(width: 8),
            Text('•', style: TextStyle(color: HomeDesign.muted, fontSize: 12)),
            SizedBox(width: 8),
            Text(
              'BingusFy',
              style: TextStyle(color: HomeDesign.muted, fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'Termos',
                style: TextStyle(color: HomeDesign.muted, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Privacidade',
                style: TextStyle(color: HomeDesign.muted, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Feedback',
                style: TextStyle(color: HomeDesign.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
