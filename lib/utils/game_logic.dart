import 'dart:collection';
import 'package:flutter/material.dart';
import '../models/ball.dart';

class Point {
  final int x;
  final int y;
  const Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class GameLogic {
  static const int boardSize = 9;

  // BFS to find if there is a path from start to end
  static List<Point>? findPath(Point start, Point end, List<List<Ball?>> board) {
    if (start == end) return [];
    if (board[end.y][end.x] != null) return null; // Destination is blocked

    final queue = Queue<List<Point>>();
    final visited = <Point>{};

    queue.add([start]);
    visited.add(start);

    final dx = [0, 1, 0, -1];
    final dy = [-1, 0, 1, 0];

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final current = path.last;

      if (current == end) {
        return path;
      }

      for (int i = 0; i < 4; i++) {
        final nx = current.x + dx[i];
        final ny = current.y + dy[i];
        final neighbor = Point(nx, ny);

        if (nx >= 0 && nx < boardSize && ny >= 0 && ny < boardSize) {
          if (!visited.contains(neighbor) && board[ny][nx] == null) {
            visited.add(neighbor);
            queue.add([...path, neighbor]);
          }
        }
      }
    }

    return null; // No path found
  }

  // Check for lines of 5 or more balls of the same color
  static List<Point> checkLines(List<List<Ball?>> board) {
    final ballsToRemove = <Point>{};

    // Helper to check a specific direction
    void checkDirection(int startX, int startY, int dx, int dy) {
      int x = startX;
      int y = startY;
      BallColor? currentColor;
      List<Point> currentLine = [];

      while (x >= 0 && x < boardSize && y >= 0 && y < boardSize) {
        final ball = board[y][x];
        
        if (ball != null) {
          bool isRainbow = ball.specialType == SpecialBallType.rainbow;
          bool isMatch = false;

          if (currentLine.isEmpty) {
            isMatch = true;
            currentColor = isRainbow ? null : ball.color;
          } else {
            if (currentColor == null) {
              // Current line is all rainbows so far
              isMatch = true;
              if (!isRainbow) currentColor = ball.color;
            } else {
              if (isRainbow || ball.color == currentColor) {
                isMatch = true;
              }
            }
          }

          if (isMatch) {
            currentLine.add(Point(x, y));
          } else {
            if (currentLine.length >= 5) {
              ballsToRemove.addAll(currentLine);
            }
            
            // Re-start line. But we can keep trailing rainbows from the previous line.
            int trailingRainbows = 0;
            for (int i = currentLine.length - 1; i >= 0; i--) {
              final p = currentLine[i];
              if (board[p.y][p.x]!.specialType == SpecialBallType.rainbow) {
                trailingRainbows++;
              } else {
                break;
              }
            }
            
            List<Point> newLine = [];
            for (int i = currentLine.length - trailingRainbows; i < currentLine.length; i++) {
              newLine.add(currentLine[i]);
            }
            newLine.add(Point(x, y));
            currentLine = newLine;
            currentColor = isRainbow ? null : ball.color;
          }
        } else {
          if (currentLine.length >= 5) {
            ballsToRemove.addAll(currentLine);
          }
          currentColor = null;
          currentLine = [];
        }

        x += dx;
        y += dy;
      }
      
      if (currentLine.length >= 5) {
        ballsToRemove.addAll(currentLine);
      }
    }

    // Check Horizontal
    for (int y = 0; y < boardSize; y++) {
      checkDirection(0, y, 1, 0);
    }

    // Check Vertical
    for (int x = 0; x < boardSize; x++) {
      checkDirection(x, 0, 0, 1);
    }

    // Check Diagonal (Top-Left to Bottom-Right)
    for (int y = 0; y < boardSize; y++) {
      checkDirection(0, y, 1, 1);
    }
    for (int x = 1; x < boardSize; x++) {
      checkDirection(x, 0, 1, 1);
    }

    // Check Diagonal (Top-Right to Bottom-Left)
    for (int y = 0; y < boardSize; y++) {
      checkDirection(boardSize - 1, y, -1, 1);
    }
    for (int x = boardSize - 2; x >= 0; x--) {
      checkDirection(x, 0, -1, 1);
    }

    return ballsToRemove.toList();
  }
}
