import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

enum ItemType {
  hammer,
  brush,
  undo
}

class EconomyProvider extends ChangeNotifier {
  int _gold = 0;
  int _loginStreak = 1;
  bool _hasClaimedToday = false;
  Map<ItemType, int> _inventory = {
    ItemType.hammer: 0,
    ItemType.brush: 0,
    ItemType.undo: 0,
  };

  int get gold => _gold;
  int get loginStreak => _loginStreak;
  bool get hasClaimedToday => _hasClaimedToday;
  int getItemCount(ItemType type) => _inventory[type] ?? 0;
  int getItemPrice(ItemType type) => itemPrices[type] ?? 0;

  static const Map<ItemType, int> itemPrices = {
    ItemType.hammer: 50,
    ItemType.brush: 100,
    ItemType.undo: 30,
  };

  EconomyProvider() {
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _gold = prefs.getInt('player_gold') ?? 0;
    _inventory[ItemType.hammer] = prefs.getInt('item_hammer') ?? 0;
    _inventory[ItemType.brush] = prefs.getInt('item_brush') ?? 0;
    _inventory[ItemType.undo] = prefs.getInt('item_undo') ?? 0;
    
    // Check daily login
    final lastLoginStr = prefs.getString('last_login_date');
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final yesterdayStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    
    int savedStreak = prefs.getInt('login_streak') ?? 0;
    
    if (lastLoginStr == todayStr) {
      _hasClaimedToday = true;
      _loginStreak = savedStreak == 0 ? 1 : savedStreak;
    } else if (lastLoginStr == yesterdayStr) {
      _hasClaimedToday = false;
      _loginStreak = (savedStreak % 7) + 1;
    } else {
      _hasClaimedToday = false;
      _loginStreak = 1; // Reset streak
    }
    
    notifyListeners();
  }

  void claimDailyReward() async {
    if (_hasClaimedToday) return;

    switch (_loginStreak) {
      case 1: _gold += 50; break;
      case 2: _gold += 100; break;
      case 3: _inventory[ItemType.hammer] = (_inventory[ItemType.hammer] ?? 0) + 1; break;
      case 4: _gold += 150; break;
      case 5: _inventory[ItemType.brush] = (_inventory[ItemType.brush] ?? 0) + 1; break;
      case 6: _gold += 200; break;
      case 7: 
        _gold += 500; 
        _inventory[ItemType.undo] = (_inventory[ItemType.undo] ?? 0) + 1; 
        break;
      default: _gold += 50; break;
    }

    _hasClaimedToday = true;
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('last_login_date', todayStr);
    await prefs.setInt('login_streak', _loginStreak);
    
    _saveData();
    AnalyticsService().logDailyRewardClaimed(_loginStreak, _gold);
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_gold', _gold);
    await prefs.setInt('item_hammer', _inventory[ItemType.hammer]!);
    await prefs.setInt('item_brush', _inventory[ItemType.brush]!);
    await prefs.setInt('item_undo', _inventory[ItemType.undo]!);
  }

  void addGold(int amount) {
    if (amount <= 0) return;
    _gold += amount;
    _saveData();
    notifyListeners();
  }

  bool spendGold(int amount) {
    if (amount <= 0) return true;
    if (_gold >= amount) {
      _gold -= amount;
      _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool buyItem(ItemType type) {
    final price = itemPrices[type] ?? 0;
    if (_gold >= price) {
      _gold -= price;
      _inventory[type] = (_inventory[type] ?? 0) + 1;
      _saveData();
      AnalyticsService().logItemPurchased(type.name, price, _gold);
      notifyListeners();
      return true;
    }
    return false;
  }

  bool useItem(ItemType type) {
    if ((_inventory[type] ?? 0) > 0) {
      _inventory[type] = _inventory[type]! - 1;
      _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }
}
