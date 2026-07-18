import 'package:chess/chess.dart'; 
void main() { 
  var game = Chess(); 
  var p = game.get('e2')!;
  print('toString: "${p.type.toString()}"');
  print('runtimeType: ${p.type.runtimeType}');
  print('PieceType.PAWN: ${PieceType.PAWN}');
}
