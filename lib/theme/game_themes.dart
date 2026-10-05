import 'package:flutter/material.dart';
import '../models/theme_type.dart';

class ThemeConfig {
  final Color desktopBg;
  final Color winBg;
  final Color titleStart;
  final Color titleEnd;
  final Color borderLight;
  final Color borderDark;
  final Color borderDarker;
  final Color textMain;
  final Color scoreBg;
  final Color scoreText;
  final Color cellFace;
  final Color cellBg;
  final Color cellShadow;
  final Color cellSelect;
  final String titleFontFamily;
  
  const ThemeConfig({
    required this.desktopBg,
    required this.winBg,
    required this.titleStart,
    required this.titleEnd,
    required this.borderLight,
    required this.borderDark,
    required this.borderDarker,
    required this.textMain,
    required this.scoreBg,
    required this.scoreText,
    required this.cellFace,
    required this.cellBg,
    required this.cellShadow,
    required this.cellSelect,
    required this.titleFontFamily,
  });
}

class GameThemes {
  static const classic = ThemeConfig(
    desktopBg: Color(0xFF008080),
    winBg: Color(0xFFD4D0C8),
    titleStart: Color(0xFF0A246A),
    titleEnd: Color(0xFF3A6EA5),
    borderLight: Color(0xFFFFFFFF),
    borderDark: Color(0xFF808080),
    borderDarker: Color(0xFF404040),
    textMain: Colors.black,
    scoreBg: Colors.black,
    scoreText: Color(0xFF00C8FF),
    cellFace: Color(0xFFD4D0C8),
    cellBg: Color(0xFFBCB8B0),
    cellShadow: Color(0xFF808080),
    cellSelect: Color(0xFFFFFF80),
    titleFontFamily: 'VT323',
  );

  static const windowsXp = ThemeConfig(
    desktopBg: Color(0xFF5A7EDC), // Bliss blue
    winBg: Color(0xFFECE9D8), // XP window color
    titleStart: Color(0xFF0055EA), // Luna blue title
    titleEnd: Color(0xFF0055EA),
    borderLight: Color(0xFFFFFFFF),
    borderDark: Color(0xFFACA899),
    borderDarker: Color(0xFF716F64),
    textMain: Colors.black,
    scoreBg: Color(0xFF1E1E1E),
    scoreText: Color(0xFF00FF00),
    cellFace: Color(0xFFECE9D8),
    cellBg: Color(0xFFDCD8C6),
    cellShadow: Color(0xFFACA899),
    cellSelect: Color(0xFFFFD700),
    titleFontFamily: 'Roboto',
  );

  static const msDos = ThemeConfig(
    desktopBg: Colors.black,
    winBg: Colors.black,
    titleStart: Color(0xFF008000),
    titleEnd: Color(0xFF008000),
    borderLight: Color(0xFF00FF00),
    borderDark: Color(0xFF008000),
    borderDarker: Color(0xFF004000),
    textMain: Color(0xFF00FF00),
    scoreBg: Colors.black,
    scoreText: Color(0xFF00FF00),
    cellFace: Colors.black,
    cellBg: Color(0xFF002200),
    cellShadow: Color(0xFF008000),
    cellSelect: Color(0xFF00FF00),
    titleFontFamily: 'VT323',
  );

  static ThemeConfig getConfig(GameTheme theme) {
    switch (theme) {
      case GameTheme.windowsXp:
        return windowsXp;
      case GameTheme.msDos:
        return msDos;
      case GameTheme.classic:
      default:
        return classic;
    }
  }
}
