import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'dart:math' as math;
import 'dart:async';

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Chess',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _isCountDown = false;
  int _selectedSeconds = 300;

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int? _parseCustomTime(String text) {
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final minutes = int.tryParse(parts[0].trim());
    final seconds = int.tryParse(parts[1].trim());
    if (minutes == null || seconds == null) return null;
    if (minutes < 0 || seconds < 0 || seconds >= 60) return null;
    final totalSeconds = minutes * 60 + seconds;
    if (totalSeconds <= 0) return null;
    return totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Chess'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select Timer Mode:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Padding(padding: EdgeInsets.all(8.0), child: Text('Count Up', style: TextStyle(fontSize: 18))),
                  selected: !_isCountDown,
                  onSelected: (selected) {
                    if (selected) setState(() => _isCountDown = false);
                  },
                ),
                const SizedBox(width: 20),
                ChoiceChip(
                  label: const Padding(padding: EdgeInsets.all(8.0), child: Text('Count Down', style: TextStyle(fontSize: 18))),
                  selected: _isCountDown,
                  onSelected: (selected) {
                    if (selected) setState(() => _isCountDown = true);
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 120,
              child: _isCountDown 
                  ? Column(
                      children: [
                        const Text('Select Duration:', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 10),
                        DropdownButton<int>(
                          value: [60, 180, 300, 600].contains(_selectedSeconds) ? _selectedSeconds : -1,
                          items: [
                            const DropdownMenuItem(value: 60, child: Text('1 min', style: TextStyle(fontSize: 18))),
                            const DropdownMenuItem(value: 180, child: Text('3 min', style: TextStyle(fontSize: 18))),
                            const DropdownMenuItem(value: 300, child: Text('5 min', style: TextStyle(fontSize: 18))),
                            const DropdownMenuItem(value: 600, child: Text('10 min', style: TextStyle(fontSize: 18))),
                            DropdownMenuItem(
                              value: -1, 
                              child: Text(
                                [60, 180, 300, 600].contains(_selectedSeconds) 
                                    ? 'Custom...' 
                                    : 'Custom (${_formatTime(_selectedSeconds)})', 
                                style: const TextStyle(fontSize: 18)
                              )
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == -1) {
                              final int? custom = await showDialog<int>(
                                context: context,
                                builder: (context) {
                                  final TextEditingController controller = TextEditingController(
                                    text: _formatTime(_selectedSeconds)
                                  );
                                  String? errorMessage;
                                  return StatefulBuilder(
                                    builder: (context, setDialogState) {
                                      return AlertDialog(
                                        title: const Text('Custom Timer'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: controller,
                                              keyboardType: TextInputType.datetime,
                                              autofocus: true,
                                              decoration: InputDecoration(
                                                labelText: 'Duration (MM:SS)',
                                                hintText: 'e.g. 01:30',
                                                errorText: errorMessage,
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              final int? val = _parseCustomTime(controller.text);
                                              if (val != null) {
                                                Navigator.pop(context, val);
                                              } else {
                                                setDialogState(() {
                                                  errorMessage = 'Invalid format. Use MM:SS (e.g., 01:30)';
                                                });
                                              }
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    }
                                  );
                                }
                              );
                              if (custom != null) {
                                setState(() => _selectedSeconds = custom);
                              }
                            } else if (value != null) {
                              setState(() => _selectedSeconds = value);
                            }
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChessGameScreen(
                      isCountDown: _isCountDown,
                      selectedSeconds: _selectedSeconds,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Text('Start Game', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChessGameScreen extends StatefulWidget {
  final bool isCountDown;
  final int selectedSeconds;

  const ChessGameScreen({
    super.key,
    required this.isCountDown,
    required this.selectedSeconds,
  });

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  late chess.Chess game;
  String? selectedSquare;
  List<String> validDestinations = [];

  Timer? _gameTimer;
  late int _whiteTime;
  late int _blackTime;
  bool _gameStarted = false;
  bool _isTimeOut = false;

  // Unicode mapping - using solid shapes with \uFE0E to force text presentation (prevents emoji fallback)
  static const Map<String, String> pieceUnicodes = {
    'k': '♚\uFE0E', 'q': '♛\uFE0E', 'r': '♜\uFE0E', 'b': '♝\uFE0E', 'n': '♞\uFE0E', 'p': '♟\uFE0E',
  };

  @override
  void initState() {
    super.initState();
    game = chess.Chess();
    if (widget.isCountDown) {
      _whiteTime = widget.selectedSeconds;
      _blackTime = widget.selectedSeconds;
    } else {
      _whiteTime = 0;
      _blackTime = 0;
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _gameStarted = true;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (game.game_over) {
        timer.cancel();
        return;
      }
      setState(() {
        if (widget.isCountDown) {
          if (game.turn == chess.Color.WHITE) {
            if (_whiteTime > 0) _whiteTime--;
          } else {
            if (_blackTime > 0) _blackTime--;
          }
          
          if (_whiteTime <= 0 || _blackTime <= 0) {
            timer.cancel();
            _isTimeOut = true;
            _showTimeoutDialog(_whiteTime <= 0 ? "White" : "Black");
          }
        } else {
          if (game.turn == chess.Color.WHITE) {
            _whiteTime++;
          } else {
            _blackTime++;
          }
        }
      });
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _resetGame() {
    _gameTimer?.cancel();
    setState(() {
      game = chess.Chess();
      selectedSquare = null;
      validDestinations = [];
      _gameStarted = false;
      _isTimeOut = false;
      if (widget.isCountDown) {
        _whiteTime = widget.selectedSeconds;
        _blackTime = widget.selectedSeconds;
      } else {
        _whiteTime = 0;
        _blackTime = 0;
      }
    });
  }

  String get _turnText => game.turn == chess.Color.WHITE ? "White's Turn" : "Black's Turn";

  void _handleDragMove(String from, String to) async {
    if (game.game_over || _isTimeOut) return;
    if (from == to) return;
    
    final piece = game.get(from);
    if (piece == null || piece.color != game.turn) return;

    final moves = game.generate_moves({'square': from});
    final validMove = moves.any((m) => m.toAlgebraic == to);

    if (validMove) {
      String? promotionType;
      bool isWhite = game.turn == chess.Color.WHITE;
      bool isPawn = piece.type.toString().toLowerCase() == 'p';
      bool isPromotionRank = (isWhite && to.endsWith('8')) || (!isWhite && to.endsWith('1'));

      if (isPawn && isPromotionRank) {
        promotionType = await _showPromotionDialog(isWhite);
        if (promotionType == null) return;
      }

      final Map<String, dynamic> moveObj = {
        'from': from,
        'to': to,
      };
      if (promotionType != null) {
        moveObj['promotion'] = promotionType;
      }
      
      final moveSuccess = game.move(moveObj);

      if (moveSuccess) {
        if (!_gameStarted) {
          _startTimer();
        }
        setState(() {
          selectedSquare = null;
          validDestinations = [];
        });

        if (game.game_over) {
          _showGameOverDialog();
        }
      }
    }
  }

  void _onSquareTap(String square) async {
    if (game.game_over || _isTimeOut) return;

    if (selectedSquare == null) {
      final piece = game.get(square);
      if (piece != null && piece.color == game.turn) {
        setState(() {
          selectedSquare = square;
          _updateValidDestinations(square);
        });
      }
    } else {
      if (selectedSquare == square) {
        setState(() {
          selectedSquare = null;
          validDestinations = [];
        });
        return;
      }

      final piece = game.get(square);
      if (piece != null && piece.color == game.turn) {
        setState(() {
          selectedSquare = square;
          _updateValidDestinations(square);
        });
        return;
      }

      if (validDestinations.contains(square)) {
        String? promotionType;
        final selectedPiece = game.get(selectedSquare!);
        
        bool isWhite = game.turn == chess.Color.WHITE;
        bool isPawn = selectedPiece?.type.toString().toLowerCase() == 'p';
        bool isPromotionRank = (isWhite && square.endsWith('8')) || (!isWhite && square.endsWith('1'));

        if (isPawn && isPromotionRank) {
          promotionType = await _showPromotionDialog(isWhite);
          if (promotionType == null) {
            setState(() {
              selectedSquare = null;
              validDestinations = [];
            });
            return;
          }
        }

        final Map<String, dynamic> moveObj = {
          'from': selectedSquare,
          'to': square,
        };
        if (promotionType != null) {
          moveObj['promotion'] = promotionType;
        }
        final moveSuccess = game.move(moveObj);

        if (moveSuccess) {
          if (!_gameStarted) {
            _startTimer();
          }
          setState(() {
            selectedSquare = null;
            validDestinations = [];
          });

          if (game.game_over) {
            _showGameOverDialog();
          }
        } else {
          setState(() {
            selectedSquare = null;
            validDestinations = [];
          });
        }
      } else {
        setState(() {
          selectedSquare = null;
          validDestinations = [];
        });
      }
    }
  }

  void _updateValidDestinations(String square) {
    validDestinations.clear();
    final moves = game.generate_moves({'square': square});
    for (var m in moves) {
      validDestinations.add(m.toAlgebraic);
    }
  }

  Future<String?> _showPromotionDialog(bool isWhite) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Widget dialogContent = AlertDialog(
          title: const Text('Promote Pawn'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _promotionOption('q', 'q', isWhite),
              _promotionOption('r', 'r', isWhite),
              _promotionOption('b', 'b', isWhite),
              _promotionOption('n', 'n', isWhite),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
          ],
        );

        // Rotate dialog if it is black's turn so they can read it!
        if (!isWhite) {
          dialogContent = RotatedBox(
            quarterTurns: 2,
            child: dialogContent,
          );
        }

        return dialogContent;
      },
    );
  }

  Widget _promotionOption(String value, String pieceKey, bool isWhite) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          pieceUnicodes[pieceKey]!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            height: 1.0,
            color: isWhite ? Colors.white : Colors.black,
            fontFamily: 'Segoe UI Symbol',
            fontFamilyFallback: const [
              'Apple Symbols',
              'DejaVu Sans',
              'Noto Sans Symbols',
              'FreeSans',
              'sans-serif',
            ],
            shadows: const [
              Shadow(color: Colors.grey, blurRadius: 2)
            ]
          ),
        ),
      ),
    );
  }

  void _showGameOverDialog() {
    String message = "Game Over!";
    if (game.in_checkmate) {
      String winner = game.turn == chess.Color.WHITE ? "Black" : "White";
      message = "Checkmate! $winner wins.";
    } else if (game.in_draw) {
      message = "Draw!";
    } else if (game.in_stalemate) {
      message = "Stalemate!";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Widget dialogContent = AlertDialog(
          title: const Text('Game Over'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
          ],
        );

        if (game.turn == chess.Color.BLACK) {
           dialogContent = RotatedBox(
            quarterTurns: 2,
            child: dialogContent,
          );
        }

        return dialogContent;
      },
    );
  }

  void _showTimeoutDialog(String loser) {
    String winner = loser == "White" ? "Black" : "White";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Widget dialogContent = AlertDialog(
          title: const Text('Time\'s Up!'),
          content: Text('$loser ran out of time. $winner wins!'),
          actions: [
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
          ],
        );

        if (game.turn == chess.Color.BLACK) {
           dialogContent = RotatedBox(
            quarterTurns: 2,
            child: dialogContent,
          );
        }

        return dialogContent;
      },
    );
  }

  Widget _buildTimerCard({required bool isActive, required int timeInSeconds, required bool isWhite}) {
    final displayTime = _formatTime(timeInSeconds);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive 
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceVariant.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
              ? colorScheme.primary 
              : colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ] : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 12,
            color: isActive ? Colors.greenAccent : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            isWhite ? "White: $displayTime" : "Black: $displayTime",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    bool isWhiteTurn = game.turn == chess.Color.WHITE;
    
    // Board stays fixed now. White at bottom.
    List<String> ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];
    List<String> files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown, width: 4),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            int row = index ~/ 8;
            int col = index % 8;
            String square = '${files[col]}${ranks[row]}';
            
            bool isDarkSquare = (row + col) % 2 != 0;
            Color squareColor = isDarkSquare ? Colors.brown.shade700 : Colors.brown.shade200;

            if (selectedSquare == square) {
              squareColor = Colors.yellow.withValues(alpha: 0.8);
            } else if (validDestinations.contains(square)) {
              final piece = game.get(square);
              if (piece != null && piece.color != game.turn) {
                squareColor = Colors.redAccent.withValues(alpha: 0.8);
              } else {
                squareColor = Colors.greenAccent.withValues(alpha: 0.8);
              }
            }

            final piece = game.get(square);
            String pieceText = '';
            Color pieceColor = Colors.transparent;
            if (piece != null) {
              String typeString = piece.type.toString().toLowerCase();
              pieceText = pieceUnicodes[typeString] ?? '';
              pieceColor = piece.color == chess.Color.WHITE ? Colors.white : Colors.black;
            }

            Widget pieceWidget = pieceText.isNotEmpty ? Text(
              pieceText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                height: 1.0,
                color: pieceColor,
                shadows: const [
                  Shadow(color: Colors.grey, blurRadius: 2, offset: Offset(1, 1))
                ]
              ),
            ) : const SizedBox.shrink();

            // Flip pieces for the current player
            if (!isWhiteTurn && pieceText.isNotEmpty) {
              pieceWidget = RotatedBox(
                quarterTurns: 2,
                child: pieceWidget,
              );
            }

            Widget squareContent = Container(
              color: squareColor,
              child: Center(
                child: pieceText.isNotEmpty && piece?.color == game.turn
                  ? Draggable<String>(
                      key: ValueKey('draggable_${square}_${piece?.type}_${piece?.color}'),
                      data: square,
                      feedback: Material(
                        color: Colors.transparent,
                        child: pieceWidget,
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: pieceWidget,
                      ),
                      child: pieceWidget,
                    )
                  : pieceWidget,
              ),
            );

            return DragTarget<String>(
              key: ValueKey('drag_target_$square'),
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                _handleDragMove(details.data, square);
              },
              builder: (context, candidateData, rejectedData) {
                return GestureDetector(
                  onTap: () => _onSquareTap(square),
                  child: squareContent,
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isCheck = game.in_check;
    bool isWhiteTurn = game.turn == chess.Color.WHITE;
    
    Widget turnIndicator = Text(
      _turnText,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isCheck ? Colors.red : null,
      ),
    );

    if (!isWhiteTurn) {
      turnIndicator = RotatedBox(
        quarterTurns: 2,
        child: turnIndicator,
      );
    }

    Widget checkIndicator = const Text(
      'CHECK',
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
    );

    if (!isWhiteTurn && isCheck) {
      checkIndicator = RotatedBox(
        quarterTurns: 2,
        child: checkIndicator,
      );
    }

    Widget blackTimer = _buildTimerCard(
      isActive: _gameStarted && !game.game_over && game.turn == chess.Color.BLACK,
      timeInSeconds: _blackTime,
      isWhite: false,
    );
    if (!isWhiteTurn) {
      blackTimer = RotatedBox(
        quarterTurns: 2,
        child: blackTimer,
      );
    }

    Widget whiteTimer = _buildTimerCard(
      isActive: _gameStarted && !game.game_over && game.turn == chess.Color.WHITE,
      timeInSeconds: _whiteTime,
      isWhite: true,
    );
    if (!isWhiteTurn) {
      whiteTimer = RotatedBox(
        quarterTurns: 2,
        child: whiteTimer,
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Chess'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          tooltip: 'Back to Menu',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Restart Game',
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: turnIndicator,
                ),
                if (isCheck) checkIndicator,
                const SizedBox(height: 16),
                blackTimer,
                const SizedBox(height: 16),
                Flexible(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: _buildBoard(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                whiteTimer,
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChessPawnPainter extends CustomPainter {
  final Color color;
  const ChessPawnPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    double w = size.width;
    double h = size.height;

    // Draw base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.75, w * 0.5, h * 0.1),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.75, w * 0.5, h * 0.1),
        const Radius.circular(3),
      ),
      borderPaint,
    );

    // Draw body/pedestal
    final bodyPath = Path()
      ..moveTo(w * 0.32, h * 0.75)
      ..cubicTo(w * 0.37, h * 0.55, w * 0.42, h * 0.45, w * 0.44, h * 0.42)
      ..lineTo(w * 0.56, h * 0.42)
      ..cubicTo(w * 0.58, h * 0.45, w * 0.63, h * 0.55, w * 0.68, h * 0.75)
      ..close();
    canvas.drawPath(bodyPath, paint);
    canvas.drawPath(bodyPath, borderPaint);

    // Draw collar
    canvas.drawOval(
      Rect.fromLTWH(w * 0.38, h * 0.4, w * 0.24, h * 0.05),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.38, h * 0.4, w * 0.24, h * 0.05),
      borderPaint,
    );

    // Draw head
    canvas.drawCircle(Offset(w * 0.5, h * 0.28), w * 0.15, paint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.28), w * 0.15, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

