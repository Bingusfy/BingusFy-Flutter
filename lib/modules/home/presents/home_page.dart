import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController controller;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Get the controller from GetIt and register it with GetX
    controller = GetIt.I.get<HomeController>();
    Get.put(controller);

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _isInitializing ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animado
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: HomeController.primaryBg,
              border: Border.all(color: HomeController.primaryBorder, width: 2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: HomeController.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'BF',
                style: TextStyle(
                  color: HomeController.primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
            'Carregando BingoFy...',
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

              return SingleChildScrollView(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    margin: EdgeInsets.symmetric(
                      horizontal: isMobile
                          ? 16
                          : isTablet
                          ? 24
                          : 32,
                    ),
                    padding: EdgeInsets.all(
                      isMobile
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
                                        HomeController.primaryColor.withOpacity(
                                          0.2,
                                        ),
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
                                        HomeController.primaryColor.withOpacity(
                                          0.1,
                                        ),
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
              );
            },
          ),
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
            color: const Color(0xFF0A0A0A).withOpacity(0.7),
            border: const Border(
              bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1),
            ),
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1400),
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
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
        // Logo compacto
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: HomeController.primaryBg,
            border: Border.all(color: HomeController.primaryBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: Text(
              'BF',
              style: TextStyle(
                color: HomeController.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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
        // Logo
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: HomeController.primaryBg,
            border: Border.all(color: HomeController.primaryBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'BF',
              style: TextStyle(
                color: HomeController.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bingofy',
                style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
              ),
              if (!isTablet)
                const Text(
                  'Pesquise artistas, selecione e gere painéis',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
            ],
          ),
        ),

        // Actions
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x1AFFFFFF)),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0x99262626),
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              isMobile
                  ? _buildMobileSearchHeader()
                  : _buildDesktopSearchHeader(),
              SizedBox(height: isMobile ? 10 : 12),

              // Search input
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF0A0A0A),
                    ),
                    child: TextField(
                      controller: controller.searchController,
                      focusNode: controller.searchFocusNode,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 14,
                      ),
                      decoration: InputDecoration(
                        hintText: isMobile
                            ? 'Pesquise artistas...'
                            : 'Pesquise artistas ou pressione Enter para adicionar…',
                        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: isMobile ? 12 : 10,
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

                    return Positioned(
                      top: isMobile ? 52 : 50,
                      left: 0,
                      right: 0,
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: isMobile ? 200 : 288,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xF50A0A0A),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
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
                                  fontSize: isMobile ? 16 : 14,
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
                              dense: !isMobile,
                              hoverColor: const Color(0x0DFFFFFF),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // Selected artists header
              isMobile
                  ? _buildMobileArtistsHeader()
                  : _buildDesktopArtistsHeader(),
              SizedBox(height: isMobile ? 6 : 8),

              // Selected artists display
              Obx(() {
                if (controller.selectedArtists.isEmpty) {
                  return Container(
                    height: isMobile ? 48 : 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF0A0A0A),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_upward,
                          color: Color(0xFF6B7280),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMobile
                                ? 'Adicione artistas acima.'
                                : 'Comece adicionando artistas da pesquisa acima.',
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: isMobile ? 14 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  constraints: BoxConstraints(minHeight: isMobile ? 48 : 44),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF0A0A0A),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: isMobile ? 6 : 8,
                    runSpacing: isMobile ? 6 : 8,
                    children: controller.selectedArtists
                        .map((artist) => _buildArtistChip(artist, isMobile))
                        .toList(),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileSearchHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crie seu grupo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF262626),
            border: Border.all(color: HomeController.primaryBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '#1ED760',
            style: TextStyle(color: HomeController.primaryColor, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSearchHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Crie seu grupo de artistas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF262626),
            border: Border.all(color: HomeController.primaryBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '#1ED760',
            style: TextStyle(color: HomeController.primaryColor, fontSize: 10),
          ),
        ),
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
                onPressed: controller.importPopularArtists,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD1D5DB),
                  side: const BorderSide(color: Color(0x1AFFFFFF)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text('Populares', style: TextStyle(fontSize: 12)),
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
                  minimumSize: Size.zero,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Artistas selecionados',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
        Row(
          children: [
            TextButton(
              onPressed: controller.importPopularArtists,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD1D5DB),
                side: const BorderSide(color: Color(0x1AFFFFFF)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Adicionar artistas populares',
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
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
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
        color: const Color(0xFF262626),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 8 : 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            color: const Color(0xFF9CA3AF),
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
              color: const Color(0xFF6B7280),
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
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x1AFFFFFF)),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0x99262626),
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Opções de tabelas',
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
          onPressed: controller.generateBoards,
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text(
            'Gerar tabelas',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(double.maxFinite, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
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
                        borderRadius: BorderRadius.circular(8),
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
              Text(
                'Azulejos em branco',
                style: TextStyle(
                  color: const Color(0xFFD1D5DB),
                  fontSize: isMobile ? 16 : 14,
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
            'As tabelas incluirão aleatoriamente azulejos em branco para variar a dificuldade.',
            style: TextStyle(
              color: const Color(0xFF6B7280),
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
        Column(
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
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
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
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
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
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x1AFFFFFF)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x80262626),
      ),
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
            'Nenhuma placa ainda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pesquise e adicione artistas, ajuste as opções e, em seguida, gere tabelas.',
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

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: constraints.maxWidth < 640 ? 16 : 20,
            mainAxisSpacing: constraints.maxWidth < 640 ? 16 : 20,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: controller.boards.length,
          itemBuilder: (context, index) {
            final board = controller.boards[index];
            return _buildBoardCard(board, index);
          },
        );
      },
    );
  }

  Widget _buildBoardCard(BingoBoard board, int boardIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 300;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Intercepta e consome o scroll dentro da tabela
            return true;
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x1AFFFFFF)),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0x80262626),
            ),
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              children: [
                // Board header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Card ${board.id}',
                      style: TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontSize: isMobile ? 16 : 14,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              controller.clearBoardMarks(boardIndex),
                          icon: Icon(Icons.clear, size: isMobile ? 18 : 16),
                          style: IconButton.styleFrom(
                            side: const BorderSide(color: Color(0x1AFFFFFF)),
                            foregroundColor: Colors.white,
                            fixedSize: Size(
                              isMobile ? 36 : 32,
                              isMobile ? 36 : 32,
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 6 : 4),
                        IconButton(
                          onPressed: () => controller.shuffleBoard(boardIndex),
                          icon: Icon(Icons.casino, size: isMobile ? 18 : 16),
                          style: IconButton.styleFrom(
                            side: const BorderSide(color: Color(0x1AFFFFFF)),
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
    return GestureDetector(
      onTap: () => controller.toggleTileMark(boardIndex, tileIndex),
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: _buildTileContent(tile, isMobile),
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
                color: const Color(0xFF6B7280),
                size: isMobile ? 12 : 14,
              ),
              SizedBox(height: isMobile ? 1 : 2),
              Text(
                'Em branco',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
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
            horizontal: isMobile ? 16 : 32,
            vertical: isMobile ? 16 : 24,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1400),
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
            Text(
              'BF',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
            SizedBox(width: 8),
            Text('•', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            SizedBox(width: 8),
            Text(
              'BingoFy',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'Termos',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Privacidade',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Feedback',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
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
            Text(
              'BF',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
            SizedBox(width: 8),
            Text('•', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            SizedBox(width: 8),
            Text(
              'BingoFy',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'Termos',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Privacidade',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Feedback',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
