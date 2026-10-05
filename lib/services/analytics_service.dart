import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  void initialize() {
    try {
      _analytics = FirebaseAnalytics.instance;
      _initialized = true;
      debugPrint("AnalyticsService initialized.");
    } catch (e) {
      debugPrint("FirebaseAnalytics is not available. Did you run flutterfire configure? Error: $e");
    }
  }

  Future<void> logGameStart(String mode, String theme) async {
    if (!_initialized) return;
    try {
      await _analytics!.logEvent(
        name: 'game_start',
        parameters: {
          'mode': mode,
          'theme': theme,
        },
      );
      debugPrint("Firebase logged: game_start");
    } catch (e) {
      debugPrint("Failed to log game_start: $e");
    }
  }

  Future<void> logGameOver(int score, bool isNewHighScore, int maxCombo) async {
    if (!_initialized) return;
    try {
      await _analytics!.logEvent(
        name: 'game_over',
        parameters: {
          'score': score,
          'is_new_high_score': isNewHighScore ? 1 : 0,
          'max_combo': maxCombo,
        },
      );
      debugPrint("Firebase logged: game_over");
    } catch (e) {
      debugPrint("Failed to log game_over: $e");
    }
  }

  Future<void> logItemPurchased(String itemType, int price, int currentGold) async {
    if (!_initialized) return;
    try {
      await _analytics!.logEvent(
        name: 'item_purchased',
        parameters: {
          'item_type': itemType,
          'price': price,
          'current_gold': currentGold,
        },
      );
    } catch (e) {
      debugPrint("Failed to log item_purchased: $e");
    }
  }

  Future<void> logItemUsed(String itemType) async {
    if (!_initialized) return;
    try {
      await _analytics!.logEvent(
        name: 'item_used',
        parameters: {
          'item_type': itemType,
        },
      );
    } catch (e) {
      debugPrint("Failed to log item_used: $e");
    }
  }

  Future<void> logThemeUnlocked(String themeName) async {
    if (!_initialized) return;
    try {
      await _analytics!.logEvent(
        name: 'theme_unlocked',
        parameters: {
          'theme_name': themeName,
        },
      );
    } catch (e) {
      debugPrint("Failed to log theme_unlocked: $e");
    }
  }

  Future<void> logDailyRewardClaimed(int streak, int goldReward) async {
    if (!_initialized) return;
    try {
      await _analytics!.logEvent(
        name: 'daily_reward_claimed',
        parameters: {
          'streak': streak,
          'gold_reward': goldReward,
        },
      );
    } catch (e) {
      debugPrint("Failed to log daily_reward_claimed: $e");
    }
  }
}
