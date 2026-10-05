import 'package:flutter/material.dart';

class AppColors {
  // Gameplay screen — dark blue-gray, matches the board's blue-gray tones
  static const Color gameBackground = Color(0xFF263238);   // Blue-gray 900
  static const Color gameBoardBg    = Color(0xFF546E7A);   // Blue-gray 600 (board border)
  static const Color cellLight      = Color(0xFFECEFF1);   // Blue-gray 50
  static const Color cellDark       = Color(0xFFE0E5E8);   // Slightly darker
  static const Color cellSelected   = Color(0xFFFFEE58);   // Amber yellow

  // Header / score bar
  static const Color headerBg       = Color(0xFF1C2B33);   // Deeper blue-gray
  static const Color scoreBoxBg     = Color(0xFF102027);   // Near black blue
  static const Color scoreText      = Color(0xFF80DEEA);   // Cyan 200 — readable
  static const Color labelText      = Color(0xFF90A4AE);   // Blue-gray 300

  // Button
  static const Color buttonBg       = Color(0xFF37474F);   // Blue-gray 800
  static const Color buttonText     = Color(0xFFFFFFFF);

  // Next balls panel
  static const Color nextPanelBg    = Color(0xFF1C2B33);   // Same as header

  // General (for main menu — unchanged from original dark theme)
  static const Color background       = Color(0xFF1E1E2C);
  static const Color boardBackground  = Color(0xFF2D2D44);
  static const Color cellBackground   = Color(0xFF383854);
  static const Color textPrimary      = Colors.white;
  static const Color textSecondary    = Colors.white70;
  static const Color glassmorphismColor  = Color(0x1AFFFFFF);
  static const Color glassmorphismBorder = Color(0x33FFFFFF);

  // Keep panel colors for board widget
  static const Color panelFace       = Color(0xFFC0C0C0);
  static const Color panelHighlight  = Color(0xFFFFFFFF);
  static const Color panelShadow     = Color(0xFF808080);
  static const Color panelDarkShadow = Color(0xFF404040);
  static const Color scorePanelBg    = Color(0xFF000000);
  static const Color scorePanelText  = Color(0xFFFF0000);
}
