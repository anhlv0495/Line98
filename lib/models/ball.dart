import 'package:flutter/material.dart';

enum BallColor {
  red    (Color(0xFFFF0000)),   // Classic pure red
  blue   (Color(0xFF0000FF)),   // Classic pure blue
  green  (Color(0xFF00FF00)),   // Classic pure green
  yellow (Color(0xFFFFFF00)),   // Classic pure yellow
  purple (Color(0xFFFF00FF)),   // Classic magenta/purple
  cyan   (Color(0xFF00FFFF)),   // Classic cyan
  orange (Color(0xFFFF8000));   // Classic orange

  final Color color;
  const BallColor(this.color);
}

enum SpecialBallType {
  none,
  rainbow,
  bomb
}

class Ball {
  final int x;
  final int y;
  final BallColor color;
  final bool isSelected;
  final bool isNext;
  final bool isPopping;
  final bool isMoving;
  final SpecialBallType specialType;

  Ball({
    required this.x,
    required this.y,
    required this.color,
    this.isSelected = false,
    this.isNext = false,
    this.isPopping = false,
    this.isMoving = false,
    this.specialType = SpecialBallType.none,
  });

  Ball copyWith({
    int? x,
    int? y,
    BallColor? color,
    bool? isSelected,
    bool? isNext,
    bool? isPopping,
    bool? isMoving,
    SpecialBallType? specialType,
  }) {
    return Ball(
      x: x ?? this.x,
      y: y ?? this.y,
      color: color ?? this.color,
      isSelected: isSelected ?? this.isSelected,
      isNext: isNext ?? this.isNext,
      isPopping: isPopping ?? this.isPopping,
      isMoving: isMoving ?? this.isMoving,
      specialType: specialType ?? this.specialType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'color': color.index,
      'isSelected': isSelected,
      'isNext': isNext,
      'isPopping': isPopping,
      'isMoving': isMoving,
      'specialType': specialType.index,
    };
  }

  factory Ball.fromJson(Map<String, dynamic> json) {
    return Ball(
      x: json['x'] as int,
      y: json['y'] as int,
      color: BallColor.values[json['color'] as int],
      isSelected: json['isSelected'] as bool? ?? false,
      isNext: json['isNext'] as bool? ?? false,
      isPopping: json['isPopping'] as bool? ?? false,
      isMoving: json['isMoving'] as bool? ?? false,
      specialType: SpecialBallType.values[json['specialType'] as int? ?? 0],
    );
  }
}
