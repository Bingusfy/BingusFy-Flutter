import 'package:bingo/modules/home/models/tile.model.dart';

class BingoBoard {
  final int id;
  final List<BingoTile> tiles;
  final int gridSize;

  const BingoBoard({
    required this.id,
    required this.tiles,
    required this.gridSize,
  });

  BingoBoard copyWith({int? id, List<BingoTile>? tiles, int? gridSize}) {
    return BingoBoard(
      id: id ?? this.id,
      tiles: tiles ?? this.tiles,
      gridSize: gridSize ?? this.gridSize,
    );
  }
}
