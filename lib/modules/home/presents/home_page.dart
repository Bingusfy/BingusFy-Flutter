import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:get_it/get_it.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    // Get the controller from GetIt and register it with GetX
    controller = GetIt.I.get<HomeController>();
    Get.put(controller);

    // Aguarda o próximo frame para garantir que o GetX esteja pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Controller está pronto para uso
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Background gradients overlay
                      Stack(
                        children: [
                          // Gradient backgrounds
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

                          // Main content
                          Column(
                            children: [
                              // Hero/Search section
                              _buildMainSection(context),
                              const SizedBox(height: 32),

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
          ),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.7),
        border: const Border(
          bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
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
                    'MB',
                    style: TextStyle(
                      color: HomeController.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bingofy',
                    style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
                  ),
                  Text(
                    'Pesquise artistas, selecione e gere painéis',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),

              // Actions
              Row(
                children: [
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 1024;

        if (isLargeScreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSearchSection()),
              const SizedBox(width: 24),
              SizedBox(width: 380, child: _buildOptionsPanel()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildSearchSection(),
              const SizedBox(height: 24),
              _buildOptionsPanel(),
            ],
          );
        }
      },
    );
  }

  Widget _buildSearchSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x1AFFFFFF)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x99262626),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
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
                  style: TextStyle(
                    color: HomeController.primaryColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText:
                        'Pesquise artistas ou pressione Enter para adicionar…',
                    hintStyle: TextStyle(color: Color(0xFF6B7280)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
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
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 288),
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
                            style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.add,
                            color: Color(0xFF9CA3AF),
                            size: 16,
                          ),
                          onTap: () => controller.addArtist(artist),
                          dense: true,
                          hoverColor: const Color(0x0DFFFFFF),
                        );
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Selected artists header
          Row(
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
                    child: const Text(
                      'Limpar tudo',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Selected artists display
          Obx(() {
            if (controller.selectedArtists.isEmpty) {
              return Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF0A0A0A),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_upward,
                      color: Color(0xFF6B7280),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Comece adicionando artistas da pesquisa acima.',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x1AFFFFFF)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF0A0A0A),
              ),
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.selectedArtists
                    .map((artist) => _buildArtistChip(artist))
                    .toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildArtistChip(String artist) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 14),
          const SizedBox(width: 6),
          Text(
            artist,
            style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 14),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => controller.removeArtist(artist),
            child: const Icon(Icons.close, color: Color(0xFF6B7280), size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x1AFFFFFF)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x99262626),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opções de tabelas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Number of boards
          _buildNumberOfBoardsControl(),
          const SizedBox(height: 16),

          // Grid size
          _buildGridSizeControl(),
          const SizedBox(height: 16),

          // Blank tiles percentage
          _buildBlankTilesControl(),
          const SizedBox(height: 16),

          // Free center switch
          _buildFreeCenterControl(),
          const SizedBox(height: 20),

          // Action buttons
          Row(
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
                    fixedSize: Size(double.maxFinite, 40),
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
          ),
        ],
      ),
    );
  }

  Widget _buildNumberOfBoardsControl() {
    return Obx(
      () => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Número de tabelas',
                style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
              ),
              Text(
                '${controller.numBoards.value}',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: controller.decrementBoards,
                icon: const Icon(Icons.remove, size: 16),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0x1AFFFFFF)),
                  foregroundColor: Colors.white,
                  fixedSize: const Size(36, 36),
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
                icon: const Icon(Icons.add, size: 16),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0x1AFFFFFF)),
                  foregroundColor: Colors.white,
                  fixedSize: const Size(36, 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridSizeControl() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tamanho da grade',
            style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
          ),
          const SizedBox(height: 8),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                            fontSize: 14,
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

  Widget _buildBlankTilesControl() {
    return Obx(
      () => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Azulejos em branco',
                style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
              ),
              Text(
                '${controller.blankPercent.value}%',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: controller.blankPercent.value.toDouble(),
            min: 0,
            max: 60,
            divisions: 12,
            activeColor: HomeController.primaryColor,
            onChanged: (value) => controller.setBlankPercent(value.round()),
          ),
          const Text(
            'As tabelas incluirão aleatoriamente azulejos em branco para variar a dificuldade.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeCenterControl() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Centro livre (grades ímpares)',
            style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
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
    return Obx(
      () => Column(
        children: [
          // Header
          Row(
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
              const Text(
                'Clique nos artistas para marcar enquanto joga',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (controller.showEmptyState.value)
            _buildEmptyState()
          else
            _buildBoardsGrid(),
        ],
      ),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width >= 1280
            ? 3
            : MediaQuery.of(context).size.width >= 768
            ? 2
            : 1,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.0,
      ),
      itemCount: controller.boards.length,
      itemBuilder: (context, index) {
        final board = controller.boards[index];
        return _buildBoardCard(board, index);
      },
    );
  }

  Widget _buildBoardCard(BingoBoard board, int boardIndex) {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Board header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card ${board.id}',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => controller.clearBoardMarks(boardIndex),
                      icon: const Icon(Icons.clear, size: 16),
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Color(0x1AFFFFFF)),
                        foregroundColor: Colors.white,
                        fixedSize: const Size(32, 32),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => controller.shuffleBoard(boardIndex),
                      icon: const Icon(Icons.casino, size: 16),
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Color(0x1AFFFFFF)),
                        foregroundColor: Colors.white,
                        fixedSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Board grid com scroll próprio e interceptação de eventos
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calcula o tamanho necessário para a grid
                  final tileSize =
                      (constraints.maxWidth - (board.gridSize - 1) * 6) /
                      board.gridSize;
                  final totalHeight =
                      tileSize * board.gridSize + (board.gridSize - 1) * 6;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height: totalHeight > constraints.maxHeight
                          ? totalHeight
                          : constraints.maxHeight,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: board.gridSize,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: board.tiles.length,
                        itemBuilder: (context, tileIndex) {
                          final tile = board.tiles[tileIndex];
                          return _buildBoardTile(tile, boardIndex, tileIndex);
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
  }

  Widget _buildBoardTile(BingoTile tile, int boardIndex, int tileIndex) {
    return GestureDetector(
      onTap: () => controller.toggleTileMark(boardIndex, tileIndex),
      child: Container(
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
        child: _buildTileContent(tile),
      ),
    );
  }

  Widget _buildTileContent(BingoTile tile) {
    switch (tile.type) {
      case BingoTileType.free:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FREE',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Center',
              style: TextStyle(
                color: HomeController.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case BingoTileType.blank:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, color: Color(0xFF6B7280), size: 16),
            SizedBox(height: 2),
            Text(
              'Em branco',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        );
      case BingoTileType.artist:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Artista',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              tile.content ?? '',
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
    }
  }

  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'BF',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
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
          ),
        ),
      ),
    );
  }
}
