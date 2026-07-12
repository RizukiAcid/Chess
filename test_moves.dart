import 'package:chess/chess.dart'; 
void main() { 
  var game = Chess(); 
  game.move({'from': 'e2', 'to': 'e4'});
  game.move({'from': 'e7', 'to': 'e5'});
  game.move({'from': 'g1', 'to': 'f3'});
  game.move({'from': 'b8', 'to': 'c6'});
  
  for (var sq in ['e4', 'e5', 'f3', 'c6']) {
    var p = game.get(sq);
    print('Square: $sq, type: ${p?.type}, color: ${p?.color}');
  }
}
