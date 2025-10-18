import 'package:bingo/modules/home/models/boards.model.dart';
import 'package:bingo/modules/home/models/tile.model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  static const primaryColor = Color(0xFF1ED760);
  static const primaryBg = Color(0x141ED760);
  static const primaryBorder = Color(0x591ED760);

  // Sample artist dataset
  static const List<String> artistsDb = [
    "Taylor Swift",
    "Drake",
    "The Weeknd",
    "Ariana Grande",
    "Bad Bunny",
    "Billie Eilish",
    "Dua Lipa",
    "Post Malone",
    "Harry Styles",
    "Olivia Rodrigo",
    "Ed Sheeran",
    "Beyoncé",
    "Rihanna",
    "Kendrick Lamar",
    "Travis Scott",
    "SZA",
    "Doja Cat",
    "Bruno Mars",
    "Lady Gaga",
    "Justin Bieber",
    "Coldplay",
    "Imagine Dragons",
    "Lana Del Rey",
    "J. Cole",
    "Metro Boomin",
    "Nicki Minaj",
    "Kanye West",
    "Frank Ocean",
    "Lil Nas X",
    "Shawn Mendes",
    "Adele",
    "KAROL G",
    "Rosalía",
    "Shakira",
    "Feid",
    "J Balvin",
    "Anitta",
    "BLACKPINK",
    "BTS",
    "NewJeans",
    "Arctic Monkeys",
    "Tame Impala",
    "The 1975",
    "Lorde",
    "Hozier",
    "Paramore",
    "The Killers",
    "The Neighbourhood",
    "Billie Marten",
    "Phoebe Bridgers",
    "Miley Cyrus",
    "Sam Smith",
    "Calvin Harris",
    "Zedd",
    "Kygo",
    "David Guetta",
    "Avicii",
    "Swedish House Mafia",
    "Marshmello",
    "Skrillex",
    "Queen",
    "The Beatles",
    "Fleetwood Mac",
    "Elton John",
    "Michael Jackson",
    "Prince",
    "Nirvana",
    "Red Hot Chili Peppers",
    "U2",
    "Radiohead",
    "Linkin Park",
    "Twenty One Pilots",
    "Muse",
    "Gorillaz",
    "Daft Punk",
    "ODESZA",
    "Porter Robinson",
    "Madeon",
    "Imagine Dragons",
    "Jon Bellion",
    "Childish Gambino",
    "Tyler, The Creator",
    "A\$AP Rocky",
    "Lil Uzi Vert",
    "Future",
    "21 Savage",
    "Offset",
    "Quavo",
    "Megan Thee Stallion",
    "Ice Spice",
    "Noah Kahan",
    "Zach Bryan",
    "Morgan Wallen",
    "Luke Combs",
    "Kacey Musgraves",
    "Childish Gambino",
    "Jack Harlow",
    "Lil Wayne",
    "Eminem",
    "Sia",
    "The Chainsmokers",
    "Charli XCX",
    "The Cure",
    "Depeche Mode",
    "Joy Division",
    "The Smiths",
    "Pixies",
    "Bon Iver",
    "The National",
    "Joji",
  ];

  // Observable state
  final searchText = ''.obs;
  final selectedArtists = <String>[].obs;
  final suggestions = <String>[].obs;
  final showSuggestions = false.obs;

  final numBoards = 6.obs;
  final gridSize = 5.obs;
  final blankPercent = 20.obs;
  final freeCenter = true.obs;

  final boards = <BingoBoard>[].obs;
  final showEmptyState = true.obs;

  // Controllers
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    updateSuggestions();

    // Listen to search text changes
    searchController.addListener(() {
      searchText.value = searchController.text;
      updateSuggestions();
    });

    // Listen to focus changes
    searchFocusNode.addListener(() {
      if (searchFocusNode.hasFocus) {
        showSuggestions.value = true;
        updateSuggestions();
      }
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  void updateSuggestions() {
    final query = searchText.value.trim().toLowerCase();

    if (query.isEmpty) {
      // Show random artists when no search
      final available = artistsDb
          .where((artist) => !selectedArtists.contains(artist))
          .toList();
      available.shuffle();
      suggestions.value = available.take(8).toList();
    } else {
      // Filter by search query
      final filtered = artistsDb
          .where(
            (artist) =>
                artist.toLowerCase().contains(query) &&
                !selectedArtists.contains(artist),
          )
          .take(8)
          .toList();
      suggestions.value = filtered;
    }
  }

  void addArtist(String artist) {
    final clean = artist.trim();
    if (clean.isEmpty || selectedArtists.contains(clean)) return;

    selectedArtists.add(clean);
    updateSuggestions();
    clearSearch();
    showToast('Artist added: $clean');
  }

  void removeArtist(String artist) {
    selectedArtists.remove(artist);
    updateSuggestions();
    showToast('Artist removed: $artist');
  }

  void clearSelectedArtists() {
    selectedArtists.clear();
    updateSuggestions();
    showToast('All artists cleared');
  }

  void importPopularArtists() {
    const popular = [
      "Taylor Swift",
      "Drake",
      "The Weeknd",
      "Ariana Grande",
      "Bad Bunny",
      "Billie Eilish",
      "Dua Lipa",
      "Post Malone",
      "Olivia Rodrigo",
      "SZA",
      "Kendrick Lamar",
      "Harry Styles",
      "Ed Sheeran",
      "Beyoncé",
      "Rihanna",
      "Travis Scott",
      "Doja Cat",
      "Bruno Mars",
      "Lady Gaga",
      "Justin Bieber",
    ];

    for (final artist in popular) {
      if (!selectedArtists.contains(artist)) {
        selectedArtists.add(artist);
      }
    }
    updateSuggestions();
    showToast('Popular artists added');
  }

  void clearSearch() {
    searchController.clear();
    searchText.value = '';
    showSuggestions.value = false;
  }

  void hideSuggestions() {
    showSuggestions.value = false;
  }

  void shuffleSample() {
    clearSearch();
    final shuffled = List<String>.from(artistsDb)..shuffle();
    selectedArtists.value = shuffled.take(25).toList();
    updateSuggestions();
    showToast('Sample selection shuffled');
  }

  void setNumBoards(int value) {
    numBoards.value = value.clamp(1, 24);
  }

  void incrementBoards() {
    setNumBoards(numBoards.value + 1);
  }

  void decrementBoards() {
    setNumBoards(numBoards.value - 1);
  }

  void setGridSize(int size) {
    gridSize.value = size;
  }

  void setBlankPercent(int percent) {
    blankPercent.value = percent.clamp(0, 60);
  }

  void toggleFreeCenter() {
    freeCenter.value = !freeCenter.value;
  }

  void generateBoards() {
    if (selectedArtists.isEmpty) {
      showToast('Please add some artists first');
      return;
    }

    final List<BingoBoard> newBoards = [];
    final totalTiles = gridSize.value * gridSize.value;
    final useFreeCenter = freeCenter.value && gridSize.value % 2 == 1;
    final nBlanks = (totalTiles * blankPercent.value / 100).floor();
    final nFill = totalTiles - nBlanks - (useFreeCenter ? 1 : 0);

    bool warnFew = false;

    for (int b = 0; b < numBoards.value; b++) {
      final tiles = <BingoTile>[];

      // Get artists for this board
      List<String> pool = List.from(selectedArtists)..shuffle();
      if (pool.length < nFill) warnFew = true;

      final chosen = <String>[];
      for (int i = 0; i < nFill; i++) {
        if (pool.isNotEmpty) {
          chosen.add(pool[i % pool.length]);
        }
      }

      // Create tiles
      final artistTiles = chosen
          .map(
            (artist) => BingoTile(type: BingoTileType.artist, content: artist),
          )
          .toList();
      final blankTiles = List.generate(
        nBlanks,
        (_) => const BingoTile(type: BingoTileType.blank),
      );

      tiles.addAll(artistTiles);
      tiles.addAll(blankTiles);

      // Shuffle and add free center if needed
      tiles.shuffle();
      if (useFreeCenter) {
        final centerIndex = (totalTiles / 2).floor();
        tiles.insert(
          centerIndex,
          const BingoTile(type: BingoTileType.free, content: 'FREE'),
        );
      }

      newBoards.add(
        BingoBoard(id: b + 1, tiles: tiles, gridSize: gridSize.value),
      );
    }

    boards.value = newBoards;
    showEmptyState.value = false;

    if (warnFew) {
      showToast('Not enough artists for full boards. Consider adding more.');
    } else {
      showToast('${newBoards.length} boards generated!');
    }
  }

  void toggleTileMark(int boardIndex, int tileIndex) {
    if (boardIndex >= boards.length ||
        tileIndex >= boards[boardIndex].tiles.length) {
      return;
    }

    final board = boards[boardIndex];
    final updatedTiles = List<BingoTile>.from(board.tiles);
    final tile = updatedTiles[tileIndex];

    updatedTiles[tileIndex] = tile.copyWith(isMarked: !tile.isMarked);

    boards[boardIndex] = board.copyWith(tiles: updatedTiles);
    boards.refresh();
  }

  void clearBoardMarks(int boardIndex) {
    if (boardIndex >= boards.length) return;

    final board = boards[boardIndex];
    final clearedTiles = board.tiles
        .map((tile) => tile.copyWith(isMarked: false))
        .toList();

    boards[boardIndex] = board.copyWith(tiles: clearedTiles);
    boards.refresh();
    showToast('Board marks cleared');
  }

  void shuffleBoard(int boardIndex) {
    if (boardIndex >= boards.length) return;

    final board = boards[boardIndex];
    final tiles = board.tiles
        .map((tile) => tile.copyWith(isMarked: false))
        .toList();

    // Separate different tile types
    final artistTiles = tiles
        .where((t) => t.type == BingoTileType.artist)
        .toList();
    final blankTiles = tiles
        .where((t) => t.type == BingoTileType.blank)
        .toList();
    final freeTile = tiles.where((t) => t.type == BingoTileType.free).toList();

    // Shuffle only artist tiles
    artistTiles.shuffle();

    // Rebuild tiles list
    final newTiles = <BingoTile>[];
    newTiles.addAll(artistTiles);
    newTiles.addAll(blankTiles);

    newTiles.shuffle();

    // Add free tile back in center if needed
    if (freeTile.isNotEmpty && gridSize.value % 2 == 1) {
      final centerIndex = (gridSize.value * gridSize.value / 2).floor();
      newTiles.insert(centerIndex, freeTile.first);
    }

    boards[boardIndex] = board.copyWith(tiles: newTiles);
    boards.refresh();
    showToast('Board shuffled');
  }

  void showToast(String message) {
    Future.delayed(const Duration(milliseconds: 50), () {
      try {
        if (Get.context != null) {
          Get.snackbar(
            '',
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
            duration: const Duration(seconds: 2),
            titleText: const SizedBox.shrink(),
            messageText: Row(
              children: [
                const Icon(Icons.check_circle, color: primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        // Fallback silencioso se o GetX não estiver pronto
        print('Toast message: $message');
      }
    });
  }
}

enum BingoTileType { artist, blank, free }
