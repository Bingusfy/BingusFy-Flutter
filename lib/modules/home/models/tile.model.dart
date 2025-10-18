import 'package:bingo/modules/home/presents/home_controller.dart';

class BingoTile {
  final BingoTileType type;
  final String? content;
  final bool isMarked;

  const BingoTile({required this.type, this.content, this.isMarked = false});

  BingoTile copyWith({BingoTileType? type, String? content, bool? isMarked}) {
    return BingoTile(
      type: type ?? this.type,
      content: content ?? this.content,
      isMarked: isMarked ?? this.isMarked,
    );
  }
}
