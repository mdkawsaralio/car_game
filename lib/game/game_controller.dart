import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'car.dart';
import '../login/user_data.dart';
import '../leaderboard/leaderboard_service.dart';
import '../sound/sound_service.dart';
import '../car_customization/car_skin_service.dart';
import '../achivement/achivement_services.dart';

class Coin {
  double x;
  double y;
  Coin({required this.x, required this.y});
}

class RoadDecoration {
  double x;
  double y;
  IconData icon;
  Color color;
  double speedFactor;

  RoadDecoration({
    required this.x,
    required this.y,
    required this.icon,
    required this.color,
    this.speedFactor = 1.0,
  });
}

class GameController extends GetxController {
  final Random random = Random();
  final UserDataService _userDataService = UserDataService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  final CarSkinService _skinService = Get.find<CarSkinService>();
  final AchievementService _achService = Get.find<AchievementService>();

  final SoundService _soundService = Get.find<SoundService>();

  final List<double> lanes = [0.0, 0.0, 0.0, 0.0];

  RxInt currentLane = 1.obs;
  RxDouble carX = 0.0.obs;

  double screenWidth = 360;
  double screenHeight = 800;

  double playerWidth = 45;
  double playerHeight = 85;

  double get playerVisualY => screenHeight - 140 - playerHeight;

  RxInt score = 0.obs;
  RxInt coins = 0.obs;
  RxInt runCoinsGained = 0.obs;
  RxInt highScore = 0.obs;
  RxDouble distance = 0.0.obs;

  RxBool gameOver = false.obs;

  RxDouble speed = 6.0.obs;
  double normalSpeedBase = 6.0;
  double nitroSpeedMultiplier = 2.0;

  // Boost
  RxBool isBoosting = false.obs;
  RxDouble boostCooldown = 0.0.obs;
  Timer? _boostTimer;
  Timer? _cooldownTimer;
  bool _isCooldownActive = false;
  int _boostCount = 0;

  // Boost hold state

  RxList<EnemyCar> enemies = <EnemyCar>[].obs;
  RxList<Coin> coinList = <Coin>[].obs;
  RxList<RoadDecoration> decorations = <RoadDecoration>[].obs;

  int lastSpeedIncrementScore = 0;
  Map<double, int> _laneOccupancyCount = {};
  Map<double, bool> _laneHasSlowVehicle = {};

  bool _hasPlayedCrashSound = false;
  Timer? _coinSoundTimer;

  // Continuous movement timers
  Timer? _leftHoldTimer;
  Timer? _rightHoldTimer;

  // Frame counter for performance optimization

  @override
  void onInit() {
    super.onInit();
    _initStorageAndStart();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _loadUserData();
    });

    _achService.onAchievementUnlocked = (reward) {
      coins.value += reward;
      _userDataService.saveCoins(coins.value);
    };
  }

  Future<void> _initStorageAndStart() async {
    await _userDataService.init();
    await _skinService.init();
    await _achService.init();
    await _loadUserData();
    startGame();
  }

  Future<void> _loadUserData() async {
    coins.value = await _userDataService.getCoins();
    highScore.value = await _userDataService.getHighScore();
  }

  String get playerCarAsset => _skinService.getCurrentSkinAsset();

  void setupPlayingField(double width, double height) {
    if (screenWidth == width && screenHeight == height && lanes[0] != 0.0) {
      return;
    }

    screenWidth = width;
    screenHeight = height;

    playerWidth = screenWidth * 0.11;
    playerHeight = playerWidth * 1.8;

    double start = screenWidth * 0.125;
    double laneWidth = (screenWidth * 0.75) / 4;

    for (int i = 0; i < 4; i++) {
      lanes[i] = start + (i * laneWidth) + (laneWidth / 2) - (playerWidth / 2);
    }

    carX.value = lanes[currentLane.value];
  }

  void startGame() {
    _coinSoundTimer?.cancel();

    _boostTimer?.cancel();
    _cooldownTimer?.cancel();
    _isCooldownActive = false;
    isBoosting.value = false;
    boostCooldown.value = 0.0;

    enemies.clear();
    coinList.clear();
    decorations.clear();

    distance.value = 0;
    score.value = 0;
    runCoinsGained.value = 0;

    normalSpeedBase = 6.0;
    speed.value = normalSpeedBase;
    lastSpeedIncrementScore = 0;

    gameOver.value = false;
    _hasPlayedCrashSound = false;

    _laneOccupancyCount.clear();
    _laneHasSlowVehicle.clear();

    _generateDecorations();
    _spawnEnemyWithSafetyCheck();
    _spawnCoin();

    _soundService.stopHomePageMusic();
    _soundService.stopCarSound();
    _soundService.stopTurboSound();
    _soundService.playCarSound();
  }

  void updateGameFrame(double deltaTime) {
    if (gameOver.value) return;

    distance.value += speed.value * deltaTime * 4.5;
    score.value = distance.value ~/ 10;

    if (score.value > 0 &&
        score.value % 25 == 0 &&
        score.value != lastSpeedIncrementScore) {
      lastSpeedIncrementScore = score.value;
      normalSpeedBase += 0.3;
      if (!isBoosting.value) speed.value = normalSpeedBase;
      _updateEnemySpeeds();
    }

    if (score.value >= 30 && enemies.length < 2) _spawnEnemyWithSafetyCheck();
    if (score.value >= 80 && enemies.length < 3) _spawnEnemyWithSafetyCheck();

    _updateLaneOccupancy();
    _moveEnemiesWithTrafficRules(deltaTime * 30);
    _moveCoins(deltaTime * 30);
    _moveDecorationsFrame(deltaTime * 30);
    _checkCollision(deltaTime);

    // Update sound every frame but only if car is playing
    if (_soundService.isCarPlaying) {
      double maxSpeed = normalSpeedBase * nitroSpeedMultiplier;
      double speedNormalized = speed.value / maxSpeed;
      _soundService.setCarSpeed(speedNormalized, boosting: isBoosting.value);
    }
  }

  void _updateEnemySpeeds() {
    for (var enemy in enemies) {
      double speedRatio = enemy.speed / normalSpeedBase;
      enemy.speed = (normalSpeedBase * speedRatio).clamp(
        0.3,
        normalSpeedBase * 1.3,
      );
    }
  }

  void _updateLaneOccupancy() {
    _laneOccupancyCount.clear();
    _laneHasSlowVehicle.clear();
    for (var lane in lanes) {
      _laneOccupancyCount[lane] = 0;
      _laneHasSlowVehicle[lane] = false;
    }
    for (var enemy in enemies) {
      _laneOccupancyCount[enemy.x] = (_laneOccupancyCount[enemy.x] ?? 0) + 1;
      if (enemy.speed < normalSpeedBase * 0.3) {
        _laneHasSlowVehicle[enemy.x] = true;
      }
    }
  }

  void _spawnEnemyWithSafetyCheck() {
    double spawnY = -(200 + random.nextDouble() * 250);
    EnemyCar tentativeEnemy = _createEnemy(spawnY);

    int laneIndex = lanes.indexOf(tentativeEnemy.x);
    if (laneIndex != -1) {
      int countInLane = _laneOccupancyCount[tentativeEnemy.x] ?? 0;
      if (countInLane >= 2) {
        double bestLane = tentativeEnemy.x;
        int minCount = countInLane;
        for (var lane in lanes) {
          int count = _laneOccupancyCount[lane] ?? 0;
          if (count < minCount) {
            minCount = count;
            bestLane = lane;
          }
        }
        bool safe = !enemies.any(
          (e) => e.x == bestLane && (e.y - spawnY).abs() < 200,
        );
        if (safe) tentativeEnemy.x = bestLane;
      }
    }
    enemies.add(tentativeEnemy);
  }

  EnemyCar _createEnemy(double startY) {
    return CarFactory.createEnemy(
      random: random,
      lanes: lanes,
      playerWidth: playerWidth,
      playerHeight: playerHeight,
      startY: startY,
      baseSpeed: normalSpeedBase,
    );
  }

  void _moveEnemiesWithTrafficRules(double f) {
    for (int i = enemies.length - 1; i >= 0; i--) {
      EnemyCar enemy = enemies[i];
      double enemySpeed = enemy.speed;
      if (enemySpeed > speed.value * 0.85) enemySpeed = speed.value * 0.85;
      enemy.y += (speed.value - enemySpeed) * f;

      bool shouldSlowDown = false;
      for (var other in enemies) {
        if (other == enemy) continue;
        if (other.x != enemy.x) continue;
        if (other.y > enemy.y) continue;
        double distance = enemy.y - other.y;
        if (distance < 180 && distance > 0) {
          shouldSlowDown = true;
          break;
        }
      }
      if (shouldSlowDown) {
        enemy.speed = enemy.speed * 0.97;
        if (enemy.speed < 0.5) enemy.speed = 0.5;
        enemy.y = enemy.y - (speed.value - enemySpeed) * f * 0.1;
      } else {
        double targetSpeed = _getTargetSpeed(enemy);
        if (enemy.speed < targetSpeed) {
          enemy.speed += 0.02;
          if (enemy.speed > targetSpeed) enemy.speed = targetSpeed;
        }
      }
      if (enemy.y > screenHeight + 100) {
        enemies.removeAt(i);
        _spawnEnemyWithSafetyCheck();
      }
    }
    enemies.refresh();
  }

  double _getTargetSpeed(EnemyCar enemy) {
    switch (enemy.type) {
      case 'sports_car':
        return normalSpeedBase * 1.0;
      case 'bike':
        return normalSpeedBase * 1.1;
      case 'ambulance':
        return normalSpeedBase * 0.95;
      case 'taxi':
        return normalSpeedBase * 0.7;
      case 'van':
        return normalSpeedBase * 0.55;
      case 'truck':
        return normalSpeedBase * 0.35;
      case 'bus':
      case 'school_bus':
        return normalSpeedBase * 0.3;
      case 'cycle':
        return normalSpeedBase * 0.45;
      case 'scooter':
        return normalSpeedBase * 0.6;
      default:
        return normalSpeedBase * 0.75;
    }
  }

  void _spawnCoin() {
    int lane = random.nextInt(lanes.length);
    coinList.add(
      Coin(
        x: lanes[lane] + playerWidth / 2 - 14,
        y: -(100 + random.nextDouble() * 300),
      ),
    );
  }

  void _moveCoins(double f) {
    for (int i = coinList.length - 1; i >= 0; i--) {
      coinList[i].y += speed.value * f;
      if (coinList[i].y > screenHeight + 50) coinList.removeAt(i);
    }
    if (coinList.length < 2) _spawnCoin();
    coinList.refresh();
  }

  void _generateDecorations() {
    decorations.clear();
    for (int i = 0; i < 8; i++) {
      decorations.add(
        RoadDecoration(
          x: random.nextBool() ? random.nextDouble() * 40 : screenWidth - 50,
          y: random.nextDouble() * screenHeight,
          icon: Icons.park,
          color: Colors.green.shade700,
          speedFactor: 1.5,
        ),
      );
    }
    for (int i = 0; i < 6; i++) {
      decorations.add(
        RoadDecoration(
          x: random.nextBool()
              ? 60 + random.nextDouble() * 30
              : screenWidth - 80 - random.nextDouble() * 30,
          y: random.nextDouble() * screenHeight,
          icon: Icons.apartment,
          color: Colors.grey.shade600,
          speedFactor: 1.0,
        ),
      );
    }
    for (int i = 0; i < 4; i++) {
      decorations.add(
        RoadDecoration(
          x: random.nextBool()
              ? 20 + random.nextDouble() * 20
              : screenWidth - 40 - random.nextDouble() * 20,
          y: random.nextDouble() * screenHeight,
          icon: Icons.cloud,
          color: Colors.white.withOpacity(0.2),
          speedFactor: 0.3,
        ),
      );
    }
  }

  void _moveDecorationsFrame(double f) {
    for (int i = 0; i < decorations.length; i++) {
      final dec = decorations[i];
      dec.y += speed.value * f * dec.speedFactor;
      if (dec.y > screenHeight) {
        dec.y = -(20 + random.nextDouble() * 50);
        dec.x = random.nextBool() ? random.nextDouble() * 40 : screenWidth - 50;
      }
    }
    decorations.refresh();
  }

  void _checkCollision(double deltaTime) {
    const double hitboxScale = 0.75;

    final double visualCarWidth = playerWidth * 0.72;
    final double visualCarHeight = playerHeight * 0.72;
    final double hitboxWidth = visualCarWidth * hitboxScale;
    final double hitboxHeight = visualCarHeight * hitboxScale;

    final double visualLeftOffset =
        carX.value + (playerWidth - visualCarWidth) / 2;
    final double visualTopOffset =
        playerVisualY + (playerHeight - visualCarHeight) / 2;

    final double hitboxLeft =
        visualLeftOffset + (visualCarWidth - hitboxWidth) / 2;
    final double hitboxTop =
        visualTopOffset + (visualCarHeight - hitboxHeight) / 2;

    final playerRect = Rect.fromLTWH(
      hitboxLeft,
      hitboxTop,
      hitboxWidth,
      hitboxHeight,
    );

    for (final e in enemies) {
      final double enemyHitboxWidth = e.width * hitboxScale;
      final double enemyHitboxHeight = e.height * hitboxScale;
      final double enemyHitboxLeft = e.x + (e.width - enemyHitboxWidth) / 2;
      final double enemyHitboxTop = e.y + (e.height - enemyHitboxHeight) / 2;

      final double relativeSpeed = speed.value - e.speed;
      final double displacement = relativeSpeed * deltaTime * 30;

      final sweptEnemyRect = Rect.fromLTRB(
        enemyHitboxLeft,
        displacement > 0 ? enemyHitboxTop - displacement : enemyHitboxTop,
        enemyHitboxLeft + enemyHitboxWidth,
        displacement > 0
            ? enemyHitboxTop + enemyHitboxHeight
            : enemyHitboxTop + enemyHitboxHeight - displacement,
      );

      if (playerRect.overlaps(sweptEnemyRect)) {
        _gameOver();
        return;
      }
    }

    for (int i = coinList.length - 1; i >= 0; i--) {
      final coinRect = Rect.fromLTWH(coinList[i].x, coinList[i].y, 24, 24);
      if (playerRect.overlaps(coinRect)) {
        coins.value++;
        runCoinsGained.value++;
        coinList.removeAt(i);
        _playCoinSoundDebounced();
      }
    }
  }

  void _playCoinSoundDebounced() {
    _coinSoundTimer?.cancel();
    _coinSoundTimer = Timer(const Duration(milliseconds: 30), () {
      _soundService.playCoinSound();
    });
  }

  // ============================================================
  // SINGLE-STEP MOVEMENT (for swipe)
  // ============================================================
  void moveLeft() {
    if (gameOver.value) return;
    if (currentLane.value > 0) {
      currentLane.value--;
      carX.value = lanes[currentLane.value];
    }
  }

  void moveRight() {
    if (gameOver.value) return;
    if (currentLane.value < lanes.length - 1) {
      currentLane.value++;
      carX.value = lanes[currentLane.value];
    }
  }

  void startMoveLeft() {
    if (gameOver.value) return;
    _stopMoveRight();
    _leftHoldTimer?.cancel();
    // Move immediately on press
    if (currentLane.value > 0) {
      currentLane.value--;
      carX.value = lanes[currentLane.value];
    }
    // Then continue moving
    _leftHoldTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!gameOver.value && currentLane.value > 0) {
        currentLane.value--;
        carX.value = lanes[currentLane.value];
      }
    });
  }

  void stopMoveLeft() {
    _leftHoldTimer?.cancel();
    _leftHoldTimer = null;
  }

  void startMoveRight() {
    if (gameOver.value) return;
    _stopMoveLeft();
    _rightHoldTimer?.cancel();
    // Move immediately on press
    if (currentLane.value < lanes.length - 1) {
      currentLane.value++;
      carX.value = lanes[currentLane.value];
    }
    // Then continue moving
    _rightHoldTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!gameOver.value && currentLane.value < lanes.length - 1) {
        currentLane.value++;
        carX.value = lanes[currentLane.value];
      }
    });
  }

  void stopMoveRight() {
    _rightHoldTimer?.cancel();
    _rightHoldTimer = null;
  }

  void _stopMoveLeft() => stopMoveLeft();
  void _stopMoveRight() => stopMoveRight();

  static const double maxBoostSeconds = 5.0;
  static const double maxCooldownSeconds = 30.0;

  // Seconds of boost remaining while active — drives the UI ring animation.
  RxDouble boostTimeLeft = 0.0.obs;

  void startBoostHold() {
    if (gameOver.value) return;
    if (isBoosting.value) return;
    if (_isCooldownActive) return;

    _startBoost();
  }

  void stopBoostHold() {
    if (isBoosting.value) {
      _stopBoost();
    }
  }

  void buyBoost() {
    if (gameOver.value) return;
    if (isBoosting.value) return;
    if (coins.value < 100) {
      Get.snackbar('Not enough coins', 'You need 100 coins to buy a boost');
      return;
    }
    coins.value -= 100;
    _userDataService.saveCoins(coins.value);
    _cooldownTimer?.cancel();
    _isCooldownActive = false;
    boostCooldown.value = 0.0;
    _startBoost();
    Get.snackbar('Boost Purchased!', 'Instant boost activated!');
  }

  void _startBoost() {
    isBoosting.value = true;
    speed.value = normalSpeedBase * nitroSpeedMultiplier;
    _boostCount++;
    boostTimeLeft.value = maxBoostSeconds;

    _boostTimer?.cancel();
    _boostTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      boostTimeLeft.value = (boostTimeLeft.value - 0.1).clamp(
        0.0,
        maxBoostSeconds,
      );
      if (boostTimeLeft.value <= 0) {
        timer.cancel();
        _stopBoost();
      }
    });
  }

  void _stopBoost() {
    if (!isBoosting.value) return;
    isBoosting.value = false;
    speed.value = normalSpeedBase;
    _boostTimer?.cancel();

    final double usedSeconds = maxBoostSeconds - boostTimeLeft.value;
    final double cooldownSeconds =
        (usedSeconds / maxBoostSeconds) * maxCooldownSeconds;
    boostTimeLeft.value = 0.0;

    if (cooldownSeconds <= 0.05) {
      _isCooldownActive = false;
      boostCooldown.value = 0.0;
      return;
    }

    _isCooldownActive = true;
    boostCooldown.value = cooldownSeconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      boostCooldown.value = (boostCooldown.value - 0.1).clamp(
        0.0,
        maxCooldownSeconds,
      );
      if (boostCooldown.value <= 0) {
        boostCooldown.value = 0.0;
        _isCooldownActive = false;
        timer.cancel();
      }
    });
  }

  void _cancelBoostTimers() {
    _boostTimer?.cancel();
    _cooldownTimer?.cancel();
    _isCooldownActive = false;
    isBoosting.value = false;
    boostCooldown.value = 0.0;
    boostTimeLeft.value = 0.0;
    speed.value = normalSpeedBase;
  }

  Future<void> _saveToLeaderboard() async {
    try {
      await _leaderboardService.updatePlayerStats(
        bestScore: highScore.value,
        totalCoins: coins.value,
      );
    } catch (_) {}
  }

  void _gameOver() async {
    gameOver.value = true;
    _coinSoundTimer?.cancel();
    _cancelBoostTimers();
    if (!_hasPlayedCrashSound) {
      _hasPlayedCrashSound = true;
      _soundService.stopCarSound();
      _soundService.playCrushSound();
    }
    if (score.value > highScore.value) {
      highScore.value = score.value;
      await _userDataService.saveHighScore(highScore.value);
    }
    await _userDataService.saveCoins(coins.value);
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) await _saveToLeaderboard();

    _achService.checkAchievements(
      distance: distance.value.toInt(),
      runCoins: runCoinsGained.value,
      totalCoins: coins.value,
      boostsUsed: _boostCount,
    );
  }

  bool buyLifeBack() {
    if (coins.value >= 500) {
      coins.value -= 500;
      _userDataService.saveCoins(coins.value);
      _coinSoundTimer?.cancel();
      _cancelBoostTimers();
      enemies.clear();
      coinList.clear();
      _spawnEnemyWithSafetyCheck();
      _spawnCoin();
      gameOver.value = false;
      _hasPlayedCrashSound = false;
      _laneOccupancyCount.clear();
      _laneHasSlowVehicle.clear();
      _soundService.stopCarSound();
      _soundService.playCarSound();
      return true;
    }
    return false;
  }

  void restartGame() {
    _coinSoundTimer?.cancel();
    _cancelBoostTimers();
    _soundService.stopCarSound();
    startGame();
  }

  @override
  void onClose() {
    _coinSoundTimer?.cancel();
    _cancelBoostTimers();

    _soundService.stopTurboSound();
    _soundService.stopCarSound();
    _leftHoldTimer?.cancel();
    _rightHoldTimer?.cancel();
    super.onClose();
  }
}
