import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int targetScore;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.targetScore = 0,
  });
}

class AchievementProvider extends ChangeNotifier {
  List<String> _unlockedIds = [];

  final List<Achievement> _allAchievements = [
    Achievement(
      id: 'first_blood',
      title: 'First Blood',
      description: 'Score your first points.',
      icon: Icons.water_drop,
      targetScore: 10,
    ),
    Achievement(
      id: 'veteran',
      title: 'Veteran',
      description: 'Reach a score of 500.',
      icon: Icons.military_tech,
      targetScore: 500,
    ),
    Achievement(
      id: 'master',
      title: 'Master of 98',
      description: 'Reach a score of 2000.',
      icon: Icons.workspace_premium,
      targetScore: 2000,
    ),
  ];

  List<Achievement> get allAchievements => _allAchievements;
  List<String> get unlockedIds => _unlockedIds;

  AchievementProvider() {
    _loadAchievements();
  }

  void _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    _unlockedIds = prefs.getStringList('unlocked_achievements') ?? [];
    notifyListeners();
  }

  void checkScoreAchievements(int score) async {
    bool newlyUnlocked = false;
    for (var ach in _allAchievements) {
      if (ach.targetScore > 0 && score >= ach.targetScore && !_unlockedIds.contains(ach.id)) {
        _unlockedIds.add(ach.id);
        newlyUnlocked = true;
      }
    }
    
    if (newlyUnlocked) {
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('unlocked_achievements', _unlockedIds);
    }
  }
}
