import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ball.dart';
import '../models/game_mode.dart';
import '../utils/game_logic.dart';
import '../providers/economy_provider.dart';
import '../services/audio_service.dart';
import '../services/analytics_service.dart';

class FloatingScore {
  final Point position;
  final int amount;
  final String id;
  final String? message;
  FloatingScore({required this.position, required this.amount, required this.id, this.message});
}

class GameProvider extends ChangeNotifier {
  static const int boardSize = 9;
  static const int nextBallsCount = 3;

  List<List<Ball?>> _board = List.generate(boardSize, (_) => List.filled(boardSize, null));
  List<Ball> _nextBalls = [];
  
  int _score = 0;
  int _comboCount = 0;
  List<int> _highScores = [];
  bool _isGameOver = false;
  bool _isNewHighScore = false;
  bool _isAnimating = false;
  bool _rewardGiven = false;
  GameMode _gameMode = GameMode.classic;
  ItemType? _activeItem;
  
  Point? _selectedPoint;
  List<FloatingScore> _floatingScores = [];
  bool _hasSavedGame = false;
  
  // Undo state
  List<List<Ball?>>? _prevBoard;
  List<Ball>? _prevNextBalls;
  int? _prevScore;
  
  final Random _random = Random();

  List<List<Ball?>> get board => _board;
  List<Ball> get nextBalls => _nextBalls;
  int get score => _score;
  int get comboCount => _comboCount;
  int get highScore => _highScores.isNotEmpty ? _highScores.first : 0;
  List<int> get highScores => _highScores;
  bool get isGameOver => _isGameOver;
  bool get isNewHighScore => _isNewHighScore;
  bool get rewardGiven => _rewardGiven;
  Point? get selectedPoint => _selectedPoint;
  bool get canUndo => _prevBoard != null;
  GameMode get gameMode => _gameMode;
  ItemType? get activeItem => _activeItem;
  List<FloatingScore> get floatingScores => _floatingScores;
  bool get hasSavedGame => _hasSavedGame;

  // Helper to get colors for the UI header
  List<BallColor> get nextColors => _nextBalls.map((b) => b.color).toList();

  GameProvider() {
    _loadHighScore();
    _checkSavedGame();
  }
  
  Future<void> _checkSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSavedGame = prefs.getString('saved_board') != null;
    notifyListeners();
  }

  Future<void> resumeGame() async {
    final prefs = await SharedPreferences.getInstance();
    final boardStr = prefs.getString('saved_board');
    if (boardStr != null) {
      _score = prefs.getInt('saved_score') ?? 0;
      _gameMode = GameMode.values[prefs.getInt('saved_game_mode') ?? 0];
      
      final List<dynamic> jsonList = jsonDecode(boardStr);
      for (int i = 0; i < boardSize; i++) {
        for (int j = 0; j < boardSize; j++) {
          _board[i][j] = null;
        }
      }
      for (var bJson in jsonList) {
        final b = Ball.fromJson(bJson);
        _board[b.y][b.x] = b;
        if (b.isNext) {
          _nextBalls.add(b);
        }
      }
      _isGameOver = false;
      _rewardGiven = false;
      _comboCount = 0;
      notifyListeners();
    } else {
      restartGame();
    }
  }

  Future<void> saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isGameOver) {
      await prefs.remove('saved_board');
      await prefs.remove('saved_score');
      await prefs.remove('saved_game_mode');
      _hasSavedGame = false;
      return;
    }
    
    List<Map<String, dynamic>> boardJson = [];
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (_board[i][j] != null) {
          boardJson.add(_board[i][j]!.toJson());
        }
      }
    }
    await prefs.setString('saved_board', jsonEncode(boardJson));
    await prefs.setInt('saved_score', _score);
    await prefs.setInt('saved_game_mode', _gameMode.index);
    _hasSavedGame = true;
  }

  void _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? scores = prefs.getStringList('high_scores');
    if (scores != null) {
      _highScores = scores.map((e) => int.parse(e)).toList();
    } else {
      // Fallback for old single high score
      int oldHigh = prefs.getInt('high_score') ?? 0;
      if (oldHigh > 0) _highScores = [oldHigh];
    }
    notifyListeners();
  }

  void _saveHighScore() async {
    if (_score > 0) {
      if (_highScores.isEmpty || _score > _highScores.first) {
        _isNewHighScore = true;
      }
      _highScores.add(_score);
      _highScores.sort((a, b) => b.compareTo(a));
      if (_highScores.length > 5) {
        _highScores = _highScores.sublist(0, 5);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('high_scores', _highScores.map((e) => e.toString()).toList());
    }
  }

  void _startNewGame({GameMode mode = GameMode.classic}) {
    _gameMode = mode;
    _board = List.generate(boardSize, (_) => List.filled(boardSize, null));
    _score = 0;
    _isGameOver = false;
    _isNewHighScore = false;
    _rewardGiven = false;
    _comboCount = 0;
    _selectedPoint = null;
    _activeItem = null;
    _nextBalls = [];
    _prevBoard = null;
    _prevNextBalls = null;
    _prevScore = null;
    _floatingScores = [];
    _spawnInitialBalls();
    saveGameState();
    
    AnalyticsService().logGameStart(_gameMode.name, 'unknown');
    
    notifyListeners();
  }
  
  void restartGame() {
    _startNewGame(mode: _gameMode);
  }

  void restartGameMode(GameMode mode) {
    _startNewGame(mode: mode);
  }

  List<Point> _getEmptyCells() {
    List<Point> emptyCells = [];
    for (int y = 0; y < boardSize; y++) {
      for (int x = 0; x < boardSize; x++) {
        if (_board[y][x] == null) {
          emptyCells.add(Point(x, y));
        }
      }
    }
    return emptyCells;
  }

  void markRewardGiven() {
    _rewardGiven = true;
    notifyListeners();
  }

  void _spawnInitialBalls() {
    final emptyCells = _getEmptyCells();
    emptyCells.shuffle(_random);
    
    // Spawn 5 random balls
    for (int i = 0; i < min(5, emptyCells.length); i++) {
      final point = emptyCells[i];
      final color = BallColor.values[_random.nextInt(BallColor.values.length)];
      _board[point.y][point.x] = Ball(x: point.x, y: point.y, color: color);
    }
    
    // Then generate next balls
    _generateNextBalls();
  }

  void _generateNextBalls() {
    final emptyCells = _getEmptyCells();
    if (emptyCells.isEmpty) return;
    
    emptyCells.shuffle(_random);
    int count = min(nextBallsCount, emptyCells.length);
    
    _nextBalls = [];
    for (int i = 0; i < count; i++) {
      final point = emptyCells[i];
      final color = BallColor.values[_random.nextInt(BallColor.values.length)];
      SpecialBallType type = SpecialBallType.none;
      
      if (_gameMode == GameMode.arcade) {
        int rand = _random.nextInt(100);
        if (rand < 5) type = SpecialBallType.rainbow;
        else if (rand < 10) type = SpecialBallType.bomb;
      }
      
      _nextBalls.add(Ball(
        x: point.x, 
        y: point.y, 
        color: color, 
        isNext: true,
        specialType: type,
      ));
    }
  }

  Future<void> _spawnNextBalls({bool haptics = true}) async {
    if (_nextBalls.isEmpty) {
      _generateNextBalls();
    }

    int spawnedCount = 0;

    for (final nextBall in _nextBalls) {
      Point spawnPoint = Point(nextBall.x, nextBall.y);
      
      // If the intended cell is now occupied, find a new random empty cell
      if (_board[spawnPoint.y][spawnPoint.x] != null) {
        final emptyCells = _getEmptyCells();
        if (emptyCells.isEmpty) break; // Board is full
        
        emptyCells.shuffle(_random);
        spawnPoint = emptyCells.first;
      }
      
      _board[spawnPoint.y][spawnPoint.x] = nextBall.copyWith(
        x: spawnPoint.x, 
        y: spawnPoint.y, 
        isNext: false
      );
      spawnedCount++;
    }

    _nextBalls = [];
    
    // Check if new balls form any lines
    await _processLines(haptics: haptics);
    
    // Check game over
    if (_getEmptyCells().isEmpty) {
      _isGameOver = true;
      _saveHighScore();
      AnalyticsService().logGameOver(_score, _isNewHighScore, _comboCount); // Assuming maxCombo is roughly comboCount here or we can just send _score
    } else {
      _generateNextBalls();
    }
    saveGameState();
    notifyListeners();
  }

  void toggleActiveItem(ItemType type) {
    if (_activeItem == type) {
      _activeItem = null;
    } else {
      _activeItem = type;
      _selectedPoint = null;
    }
    notifyListeners();
  }

  void cancelActiveItem() {
    _activeItem = null;
    saveGameState();
    notifyListeners();
  }

  bool applyActiveItem(int x, int y) {
    if (_activeItem == null) return false;
    if (_board[y][x] == null) return false;

    if (_activeItem == ItemType.hammer) {
      // Destroy ball
      _board[y][x] = _board[y][x]!.copyWith(isPopping: true);
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 300), () {
        _board[y][x] = null;
        _activeItem = null;
        saveGameState();
        notifyListeners();
      });
      AnalyticsService().logItemUsed(ItemType.hammer.name);
      return true;
    } else if (_activeItem == ItemType.brush) {
      // Change color
      final color = BallColor.values[_random.nextInt(BallColor.values.length)];
      _board[y][x] = _board[y][x]!.copyWith(color: color, specialType: SpecialBallType.none);
      _activeItem = null;
      notifyListeners();
      
      // Check lines after brush
      _processLines().then((formed) {
        saveGameState();
        if (!formed) {
          notifyListeners();
        }
      });
      AnalyticsService().logItemUsed(ItemType.brush.name);
      return true;
    }
    
    return false;
  }

  void selectCell(int x, int y, EconomyProvider? economy, {bool haptics = true}) {
    if (_isGameOver || _isAnimating) return;

    if (_activeItem != null && economy != null) {
      if (_board[y][x] != null) {
        // Try to use item
        if (economy.getItemCount(_activeItem!) > 0) {
          if (applyActiveItem(x, y)) {
            if (haptics) HapticFeedback.heavyImpact();
            economy.useItem(_activeItem!);
          }
        } else {
          _activeItem = null;
          notifyListeners();
        }
      }
      return;
    }

    if (_board[y][x] != null) {
      // Select a ball
      if (_selectedPoint != null) {
        final prev = _selectedPoint!;
        _board[prev.y][prev.x] = _board[prev.y][prev.x]!.copyWith(isSelected: false);
      }
      _selectedPoint = Point(x, y);
      _board[y][x] = _board[y][x]!.copyWith(isSelected: true);
      AudioService().playSelect();
      if (haptics) HapticFeedback.selectionClick();
      notifyListeners();
    } else if (_selectedPoint != null) {
      // Try to move to empty cell
      final path = GameLogic.findPath(_selectedPoint!, Point(x, y), _board);
      if (path != null) {
        _moveBall(_selectedPoint!, path, haptics: haptics);
      } else {
        AudioService().playError();
        if (haptics) HapticFeedback.vibrate();
      }
    }
  }

  void _saveUndoState() {
    _prevBoard = _board.map((row) => row.map((b) => b?.copyWith()).toList()).toList();
    _prevNextBalls = _nextBalls.map((b) => b.copyWith()).toList();
    _prevScore = _score;
  }

  void undo() {
    if (_prevBoard == null || _isAnimating) return;
    
    _board = _prevBoard!;
    _nextBalls = _prevNextBalls!;
    _score = _prevScore!;
    _comboCount = 0; // Reset combo on undo
    _isGameOver = false;
    _selectedPoint = null;
    
    // Clear undo state
    _prevBoard = null;
    _prevNextBalls = null;
    _prevScore = null;
    
    saveGameState();
    AnalyticsService().logItemUsed(ItemType.undo.name);
    notifyListeners();
  }

  Future<void> _moveBall(Point from, List<Point> path, {bool haptics = true}) async {
    if (_isGameOver || _isAnimating) return;
    
    _saveUndoState();
    
    _isAnimating = true;
    final ball = _board[from.y][from.x]!.copyWith(isSelected: false);
    _board[from.y][from.x] = null;
    _selectedPoint = null;
    
    // Animate along path
    for (int i = 1; i < path.length; i++) {
      final point = path[i];
      _board[point.y][point.x] = ball.copyWith(x: point.x, y: point.y, isMoving: true);
      AudioService().playMove();
      if (haptics) HapticFeedback.lightImpact();
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 40));
      
      if (i < path.length - 1) {
        _board[point.y][point.x] = null;
      } else {
        _board[point.y][point.x] = ball.copyWith(x: point.x, y: point.y, isMoving: false);
      }
    }

    // Check lines after move
    bool lineFormed = await _processLines(haptics: haptics);
    
    if (!lineFormed) {
      _comboCount = 0;
      // Spawn new balls if no line formed
      await _spawnNextBalls(haptics: haptics);
    } else {
      saveGameState();
    }
    
    _isAnimating = false;
    notifyListeners();
  }

  Future<bool> _processLines({bool haptics = true}) async {
    final initialToRemove = GameLogic.checkLines(_board);
    if (initialToRemove.isEmpty) return false;

    Set<Point> allToRemove = initialToRemove.toSet();
    bool hasBomb = false;
    
    // Check for chain-reaction bomb explosions
    do {
      hasBomb = false;
      List<Point> currentPoints = allToRemove.toList();
      for (final point in currentPoints) {
        if (_board[point.y][point.x]?.specialType == SpecialBallType.bomb) {
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              int ny = point.y + dy;
              int nx = point.x + dx;
              if (ny >= 0 && ny < boardSize && nx >= 0 && nx < boardSize) {
                if (_board[ny][nx] != null) {
                  final p = Point(nx, ny);
                  if (!allToRemove.contains(p)) {
                    allToRemove.add(p);
                    if (_board[ny][nx]!.specialType == SpecialBallType.bomb) {
                      hasBomb = true; // Trigger next iteration for new bomb
                    }
                  }
                }
              }
            }
          }
        }
      }
    } while (hasBomb);

    // Mark for popping
    for (final point in allToRemove) {
      _board[point.y][point.x] = _board[point.y][point.x]!.copyWith(isPopping: true);
    }
    AudioService().playPop();
    if (haptics) HapticFeedback.heavyImpact();
    notifyListeners();

    // Wait for pop animation
    await Future.delayed(const Duration(milliseconds: 300));

    for (final point in allToRemove) {
      _board[point.y][point.x] = null;
    }
    
    int pts = allToRemove.length * 2;
    if (allToRemove.length > 5) {
      pts += (allToRemove.length - 5) * 5; 
    }
    
    _comboCount++;
    int finalPts = pts * _comboCount;
    _score += finalPts;
    
    // Spawn floating score
    if (finalPts > 0) {
      final centerPoint = allToRemove.first;
      final fScore = FloatingScore(
        position: centerPoint,
        amount: finalPts,
        id: DateTime.now().millisecondsSinceEpoch.toString() + pts.toString(),
        message: _comboCount > 1 ? 'COMBO x$_comboCount!' : null,
      );
      _floatingScores.add(fScore);
      
      // Auto-remove after 1.5 seconds
      Future.delayed(const Duration(milliseconds: 1500), () {
        _floatingScores.remove(fScore);
        notifyListeners();
      });
    }
    
    notifyListeners();
    return true;
  }
}
