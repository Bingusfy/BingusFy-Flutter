import 'dart:async';

import 'package:bingo/modules/home/models/boards.model.dart';
import 'package:bingo/modules/home/models/tile.model.dart';
import 'package:bingo/modules/entry/models/spotify_playback.dart';
import 'package:bingo/modules/entry/services/spotify_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  HomeController({
    Future<SpotifyPlayback> Function()? loadPlayback,
    Future<void> Function(String)? controlPlayback,
    this.isRoomGuest = false,
    this.onRoomTileMark,
  }) : _loadPlayback = loadPlayback ?? SpotifyAuth.loadPlayback,
       _controlPlayback = controlPlayback ?? SpotifyAuth.controlPlayback;

  final Future<SpotifyPlayback> Function() _loadPlayback;
  final Future<void> Function(String) _controlPlayback;
  final bool isRoomGuest;
  final Future<void> Function(int index, bool marked)? onRoomTileMark;
  bool get canControlPlayer => !isRoomGuest;
  bool get isRoom => onRoomTileMark != null;
  final spotifyCommandBusy = false.obs;
  final spotifyPositionMs = 0.obs;
  Timer? _pollTimer;
  Timer? _positionTimer;
  bool _spotifySyncing = false;
  static const spotifySyncInterval = Duration(seconds: 3);
  final spotifyPlayback = Rxn<SpotifyPlayback>();
  final spotifyLoading = false.obs;
  final spotifyError = ''.obs;
  final spotifyNeedsAuthorization = false.obs;
  final spotifyUpdatedAt = Rxn<DateTime>();
  DateTime? _retryAfter;
  bool _hasImportedQueue = false;

  static const primaryColor = Color(0xFF1ED760);
  static const primaryBg = Color(0x141ED760);
  static const primaryBorder = Color(0x591ED760);

  // Artist source is the authenticated user's Spotify queue.
  final artistsDb = <String>[].obs;

  // Observable state
  final searchText = ''.obs;
  final selectedArtists = <String>[].obs;
  final suggestions = <String>[].obs;
  final showSuggestions = false.obs;

  // Responsive variables
  final screenWidth = 0.0.obs;
  final screenHeight = 0.0.obs;

  bool get isMobile => screenWidth.value < 640;
  bool get isTablet => screenWidth.value >= 640 && screenWidth.value < 1024;
  bool get isDesktop => screenWidth.value >= 1024;

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
    WidgetsBinding.instance.addObserver(this);
    _startSpotifyTimers();
    updateSuggestions();
    refreshSpotify();

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
      } else {
        // Delay to allow tap on suggestions to work
        Future.delayed(Duration(milliseconds: 200), () {
          showSuggestions.value = false;
        });
      }
    });
  }

  void _startSpotifyTimers() {
    _stopSpotifyTimers();
    _pollTimer = Timer.periodic(spotifySyncInterval, (_) {
      if (!isRoomGuest &&
          !spotifyCommandBusy.value &&
          !spotifyNeedsAuthorization.value) {
        refreshSpotify(silent: true);
      }
    });
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final playback = spotifyPlayback.value;
      final updated = spotifyUpdatedAt.value;
      if (playback?.isPlaying != true ||
          updated == null ||
          spotifyError.value.isNotEmpty ||
          spotifyCommandBusy.value) {
        return;
      }
      final duration = playback!.current?.durationMs ?? 0;
      if (duration > 0) {
        spotifyPositionMs.value =
            (playback.progressMs +
                    DateTime.now().difference(updated).inMilliseconds)
                .clamp(0, duration);
      }
    });
  }

  void _stopSpotifyTimers() {
    _pollTimer?.cancel();
    _positionTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSpotifyTimers();
      if (!isRoomGuest &&
          !spotifyCommandBusy.value &&
          !spotifyNeedsAuthorization.value) {
        refreshSpotify(silent: true);
      }
    } else {
      _stopSpotifyTimers();
    }
  }

  Future<void> controlSpotify(String action) async {
    if (!canControlPlayer) return;
    if (isClosed || _spotifySyncing || spotifyCommandBusy.value) return;
    if (_retryAfter != null && DateTime.now().isBefore(_retryAfter!)) return;
    spotifyCommandBusy.value = true;
    spotifyError.value = '';
    try {
      await _controlPlayback(action);
      // Give the active Spotify device time to publish its new state.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!isClosed) await refreshSpotify();
    } on SpotifyPlaybackException catch (error) {
      if (isClosed) return;
      spotifyError.value = error.message;
      spotifyNeedsAuthorization.value = error.needsAuthorization;
      if (error.code == 'rate_limited') {
        _retryAfter = DateTime.now().add(
          Duration(seconds: error.retryAfter ?? 30),
        );
      }
    } catch (_) {
      if (!isClosed) {
        spotifyError.value =
            'Não foi possível controlar o Spotify. Tente novamente.';
      }
    } finally {
      if (!isClosed) spotifyCommandBusy.value = false;
    }
  }

  Future<void> refreshSpotify({bool silent = false}) async {
    if (_spotifySyncing || isClosed) return;
    if (_retryAfter != null && DateTime.now().isBefore(_retryAfter!)) return;
    _spotifySyncing = true;
    // Background synchronization keeps the current player and controls visible.
    if (!silent || spotifyPlayback.value == null) {
      spotifyLoading.value = true;
      spotifyError.value = '';
    }
    try {
      final playback = await _loadPlayback();
      if (isClosed) return;
      spotifyPlayback.value = playback;
      spotifyError.value = '';
      spotifyNeedsAuthorization.value = false;
      final queueArtists = playback.queueArtists;
      final artistsChanged = !listEquals(artistsDb, queueArtists);
      if (artistsChanged) artistsDb.assignAll(queueArtists);
      spotifyUpdatedAt.value = DateTime.now();
      spotifyPositionMs.value = playback.progressMs.clamp(
        0,
        playback.current?.durationMs ?? 0,
      );
      _retryAfter = null;
      if (!_hasImportedQueue && artistsDb.isNotEmpty) {
        importQueueArtists();
        _hasImportedQueue = true;
      }
      if (artistsChanged) updateSuggestions();
    } on SpotifyPlaybackException catch (error) {
      if (isClosed) return;
      spotifyError.value = error.message;
      spotifyNeedsAuthorization.value = error.needsAuthorization;
      if (error.code == 'rate_limited') {
        _retryAfter = DateTime.now().add(
          Duration(seconds: error.retryAfter ?? 30),
        );
      }
    } catch (_) {
      if (!isClosed) {
        spotifyError.value =
            'Não foi possível consultar o Spotify. Tente novamente.';
      }
    } finally {
      _spotifySyncing = false;
      if (!isClosed) spotifyLoading.value = false;
    }
  }

  Future<void> reconnectSpotify() async {
    if (isRoomGuest) return;
    try {
      await SpotifyAuth.signIn();
    } catch (_) {
      if (!isClosed) {
        spotifyError.value = 'Não foi possível abrir o login do Spotify.';
      }
    }
  }

  void onSearchFocus() {
    showSuggestions.value = true;
    updateSuggestions();
  }

  void onSearchChanged(String value) {
    searchText.value = value;
    updateSuggestions();
  }

  void onSearchSubmitted(String value) {
    if (value.trim().isNotEmpty && !selectedArtists.contains(value.trim())) {
      addArtist(value.trim());
      searchController.clear();
      searchText.value = '';
      updateSuggestions();
    }
  }

  void updateScreenSize(double width, double height) {
    screenWidth.value = width;
    screenHeight.value = height;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSpotifyTimers();
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  void updateSuggestions() {
    final query = searchText.value.trim().toLowerCase();

    if (query.isEmpty) {
      // Suggestions come only from the user's queue.
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

  void importQueueArtists() {
    for (final artist in artistsDb) {
      if (!selectedArtists.contains(artist)) {
        selectedArtists.add(artist);
      }
    }
    updateSuggestions();
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
    showToast('Seleção da fila embaralhada');
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
    if (isRoomGuest || isRoom) return;
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
    if (!board.canMark) return;
    if (isRoom) {
      if (tile.type != BingoTileType.artist) return;
      onRoomTileMark?.call(tileIndex, !tile.isMarked).catchError((Object _) {
        if (!isClosed) {
          showToast('Não foi possível salvar a marcação. Tente novamente.');
        }
      });
      return;
    }

    updatedTiles[tileIndex] = tile.copyWith(isMarked: !tile.isMarked);

    boards[boardIndex] = board.copyWith(tiles: updatedTiles);
    boards.refresh();
  }

  void clearBoardMarks(int boardIndex) {
    if (isRoomGuest || isRoom) return;
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
    if (isRoomGuest || isRoom) return;
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
