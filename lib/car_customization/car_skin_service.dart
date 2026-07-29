import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarSkin {
  final String id;
  final String name;
  final String assetPath;
  final int cost;
  final Color primaryColor;

  CarSkin({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.cost,
    required this.primaryColor,
  });
}

class CarSkinService {
  static final CarSkinService _instance = CarSkinService._internal();
  factory CarSkinService() => _instance;
  CarSkinService._internal();

  SharedPreferences? _prefs;

  static final List<CarSkin> allSkins = [
    CarSkin(
      id: 'red',
      name: 'Red Fury',
      assetPath: 'lib/assets/car_red.png',
      cost: 0,
      primaryColor: Colors.red,
    ),
    CarSkin(
      id: 'blue',
      name: 'Blue Thunder',
      assetPath: 'lib/assets/car_blue.png',
      cost: 500,
      primaryColor: Colors.blue,
    ),
    CarSkin(
      id: 'gold',
      name: 'Golden Dragon',
      assetPath: 'lib/assets/car_gold.png',
      cost: 1000,
      primaryColor: Colors.amber,
    ),
    CarSkin(
      id: 'pink',
      name: 'Pink Panther',
      assetPath: 'lib/assets/car_pink.png',
      cost: 800,
      primaryColor: Colors.pink,
    ),
  ];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String getSelectedSkinId() {
    return _prefs?.getString('selected_skin') ?? 'red';
  }

  Future<void> setSelectedSkinId(String id) async {
    await _prefs?.setString('selected_skin', id);
  }

  List<String> getUnlockedSkinIds() {
    return _prefs?.getStringList('unlocked_skins') ?? ['red'];
  }

  Future<void> unlockSkin(String id) async {
    final unlocked = getUnlockedSkinIds();
    if (!unlocked.contains(id)) {
      unlocked.add(id);
      await _prefs?.setStringList('unlocked_skins', unlocked);
    }
  }

  bool isSkinUnlocked(String id) {
    return getUnlockedSkinIds().contains(id);
  }

  CarSkin getSkin(String id) {
    return allSkins.firstWhere((s) => s.id == id, orElse: () => allSkins.first);
  }

  String getCurrentSkinAsset() {
    return getSkin(getSelectedSkinId()).assetPath;
  }
}
