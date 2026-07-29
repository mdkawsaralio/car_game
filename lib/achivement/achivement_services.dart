import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final int threshold;
  final String type; // 'distance', 'run_coins', 'total_coins', 'boosts'
  final int rewardCoins;
  bool unlocked = false;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.threshold,
    required this.type,
    this.rewardCoins = 50,
  });
}

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  SharedPreferences? _prefs;

  // Define all available achievements
  static final List<Achievement> allAchievements = [
    Achievement(
      id: 'first_ride',
      title: 'First Ride',
      description: 'Drive 100 meters',
      threshold: 100,
      type: 'distance',
      rewardCoins: 50,
    ),
    Achievement(
      id: 'coin_hoarder',
      title: 'Coin Hoarder',
      description: 'Collect 50 coins in one run',
      threshold: 50,
      type: 'run_coins',
      rewardCoins: 100,
    ),
    Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Use boost 10 times',
      threshold: 10,
      type: 'boosts',
      rewardCoins: 150,
    ),
    Achievement(
      id: 'survivor',
      title: 'Survivor',
      description: 'Drive 1000 meters without crashing',
      threshold: 1000,
      type: 'distance',
      rewardCoins: 200,
    ),
    Achievement(
      id: 'rich',
      title: 'Rich',
      description: 'Collect 500 total coins',
      threshold: 500,
      type: 'total_coins',
      rewardCoins: 300,
    ),
  ];

  // Callback to award coins when an achievement is unlocked
  Function(int)? onAchievementUnlocked;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Load unlocked status from storage
    for (var a in allAchievements) {
      a.unlocked = _prefs?.getBool('ach_${a.id}') ?? false;
    }
  }

  List<Achievement> getUnlockedAchievements() {
    return allAchievements.where((a) => a.unlocked).toList();
  }

  List<Achievement> getLockedAchievements() {
    return allAchievements.where((a) => !a.unlocked).toList();
  }

  // Call this method after a game round ends with the player's stats
  void checkAchievements({
    int? distance,
    int? runCoins,
    int? totalCoins,
    int? boostsUsed,
  }) {
    for (var a in allAchievements) {
      if (a.unlocked) continue; // already achieved

      bool achieved = false;
      switch (a.type) {
        case 'distance':
          achieved = (distance ?? 0) >= a.threshold;
          break;
        case 'run_coins':
          achieved = (runCoins ?? 0) >= a.threshold;
          break;
        case 'total_coins':
          achieved = (totalCoins ?? 0) >= a.threshold;
          break;
        case 'boosts':
          achieved = (boostsUsed ?? 0) >= a.threshold;
          break;
        default:
          break;
      }

      if (achieved) {
        // Mark as unlocked
        a.unlocked = true;
        _prefs?.setBool('ach_${a.id}', true);

        // Show popup
        Get.dialog(
          AlertDialog(
            title: Text('🏆 ${a.title}'),
            content: Text('${a.description}\n+${a.rewardCoins} coins!'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        );

        // Award coins via callback (handled in game_controller)
        onAchievementUnlocked?.call(a.rewardCoins);
      }
    }
  }

  // Reset all achievements (for testing)
  Future<void> resetAll() async {
    for (var a in allAchievements) {
      a.unlocked = false;
      await _prefs?.remove('ach_${a.id}');
    }
  }
}
