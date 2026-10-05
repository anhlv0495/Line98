import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_type.dart';
import '../services/audio_service.dart';
import '../services/analytics_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _showNextBalls = true;
  bool _hapticsEnabled = true;
  GameTheme _currentTheme = GameTheme.classic;
  List<GameTheme> _unlockedThemes = [GameTheme.classic];

  bool get showNextBalls => _showNextBalls;
  bool get hapticsEnabled => _hapticsEnabled;
  GameTheme get currentTheme => _currentTheme;
  List<GameTheme> get unlockedThemes => _unlockedThemes;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showNextBalls = prefs.getBool('show_next_balls') ?? true;
    _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
    
    final themeIndex = prefs.getInt('current_theme') ?? 0;
    if (themeIndex >= 0 && themeIndex < GameTheme.values.length) {
      _currentTheme = GameTheme.values[themeIndex];
    }
    
    final unlocked = prefs.getStringList('unlocked_themes');
    if (unlocked != null) {
      _unlockedThemes = unlocked.map((e) => GameTheme.values[int.parse(e)]).toList();
    }
    
    notifyListeners();
  }

  void toggleShowNextBalls() async {
    _showNextBalls = !_showNextBalls;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_next_balls', _showNextBalls);
  }

  void toggleHaptics() async {
    _hapticsEnabled = !_hapticsEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptics_enabled', _hapticsEnabled);
  }



  void unlockTheme(GameTheme theme) async {
    if (!_unlockedThemes.contains(theme)) {
      _unlockedThemes.add(theme);
      notifyListeners();
      AnalyticsService().logThemeUnlocked(theme.name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('unlocked_themes', _unlockedThemes.map((e) => e.index.toString()).toList());
    }
  }

  void setTheme(GameTheme theme) async {
    if (_unlockedThemes.contains(theme)) {
      _currentTheme = theme;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_theme', theme.index);
    }
  }
}
