import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'game_controller.dart';
import 'car.dart';
import 'ui.dart';
import '../home/home_controller.dart';

class GamePage extends StatefulWidget {
  final bool isOffline;
  const GamePage({super.key, this.isOffline = false});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  final GameController controller = Get.put(GameController());

  late Ticker gameTicker;
  Duration lastElapsed = Duration.zero;
  double normalizedAnimationValue = 0.0;
  late AnimationController trackLinesAnimation;
  bool isFieldLayoutReady = false;
  late bool checkOfflineMode;

  @override
  void initState() {
    super.initState();
    checkOfflineMode = Get.arguments?['isOffline'] ?? widget.isOffline;
    trackLinesAnimation = AnimationController(vsync: this, value: 0.0);

    gameTicker = createTicker((elapsed) {
      if (!isFieldLayoutReady || controller.gameOver.value) {
        lastElapsed = Duration.zero;
        return;
      }
      if (lastElapsed == Duration.zero) {
        lastElapsed = elapsed;
        return;
      }
      double deltaTime =
          (elapsed.inMicroseconds - lastElapsed.inMicroseconds) /
          Duration.microsecondsPerSecond;
      lastElapsed = elapsed;
      controller.updateGameFrame(deltaTime);

      double speedFactor = controller.speed.value / 6.0;
      normalizedAnimationValue += deltaTime * speedFactor * 1.5;
      if (normalizedAnimationValue > 1.0) {
        normalizedAnimationValue -= 1.0;
      }
      trackLinesAnimation.value = normalizedAnimationValue;
    });
    gameTicker.start();
  }

  @override
  void dispose() {
    gameTicker.dispose();
    trackLinesAnimation.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to quit the race?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('YES'),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      Get.back();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().onResume();
        }
      });
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.green.shade800,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;

              if (screenWidth > 0 && screenHeight > 0 && !isFieldLayoutReady) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    controller.setupPlayingField(screenWidth, screenHeight);
                    setState(() {
                      isFieldLayoutReady = true;
                    });
                  }
                });
              }

              if (!isFieldLayoutReady) {
                return Container(color: Colors.green.shade800);
              }

              return Stack(
                children: [
                  // BACKGROUND – SWIPE AREA
                  Positioned.fill(
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        final delta = details.delta.dx;
                        if (delta > 10) {
                          controller.moveRight();
                        } else if (delta < -10) {
                          controller.moveLeft();
                        }
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  // DECORATIONS
                  Obx(
                    () => Stack(
                      children: controller.decorations
                          .map(
                            (d) => Positioned(
                              key: ValueKey(identityHashCode(d)),
                              left: d.x,
                              top: d.y,
                              child: RepaintBoundary(
                                child: Icon(d.icon, color: d.color, size: 32),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  // ROAD
                  Positioned(
                    left: screenWidth * 0.125,
                    right: screenWidth * 0.125,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      color: const Color.fromARGB(255, 62, 57, 57),
                    ),
                  ),
                  Positioned(
                    left: screenWidth * 0.125,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 4, color: Colors.white),
                  ),
                  Positioned(
                    right: screenWidth * 0.125,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 4, color: Colors.white),
                  ),
                  MovingDashedLine(
                    left: screenWidth * 0.3125,
                    screenHeight: screenHeight,
                    animation: trackLinesAnimation,
                    currentSpeed: controller.speed.value,
                  ),
                  MovingDashedLine(
                    left: screenWidth * 0.50,
                    screenHeight: screenHeight,
                    animation: trackLinesAnimation,
                    currentSpeed: controller.speed.value,
                  ),
                  MovingDashedLine(
                    left: screenWidth * 0.6875,
                    screenHeight: screenHeight,
                    animation: trackLinesAnimation,
                    currentSpeed: controller.speed.value,
                  ),

                  // COINS
                  Obx(
                    () => Stack(
                      children: controller.coinList
                          .map(
                            (c) => Positioned(
                              key: ValueKey(identityHashCode(c)),
                              left: c.x,
                              top: c.y,
                              child: RepaintBoundary(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "🪙",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  // ENEMIES
                  Obx(
                    () => Stack(
                      children: controller.enemies
                          .map(
                            (e) => Positioned(
                              key: ValueKey(identityHashCode(e)),
                              left: e.x,
                              top: e.y,
                              child: RepaintBoundary(
                                child: EnemyVehicleWidget(enemy: e),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  // PLAYER CAR
                  Obx(
                    () => Positioned(
                      top: controller.playerVisualY,
                      left: controller.carX.value,
                      child: RepaintBoundary(
                        child: PlayerCarWidget(
                          width: controller.playerWidth,
                          height: controller.playerHeight,
                          nitroActive: controller.isBoosting.value,
                          assetPath: controller.playerCarAsset,
                        ),
                      ),
                    ),
                  ),

                  // HUD
                  Obx(
                    () => GameHud(
                      score: controller.score.value,
                      coins: controller.coins.value,
                      speed: controller.speed.value,
                      isOfflineMode: checkOfflineMode,
                      userEmail: currentUser?.email,
                      isBoosting: controller.isBoosting.value,
                      boostCooldown: controller.boostCooldown.value,
                    ),
                  ),

                  // CONTROLS - HOLD TO BOOST
                  Obx(
                    () => GameControlPanel(
                      onMoveLeftStart: controller.startMoveLeft,
                      onMoveLeftStop: controller.stopMoveLeft,
                      onMoveRightStart: controller.startMoveRight,
                      onMoveRightStop: controller.stopMoveRight,
                      onBoostStart: controller.startBoostHold,
                      onBoostStop: controller.stopBoostHold,
                      onBuyBoost: controller.buyBoost,
                      isGameOver: controller.gameOver.value,
                      isBoosting: controller.isBoosting.value,
                      canBoost:
                          controller.boostCooldown.value <= 0 &&
                          !controller.isBoosting.value,
                      boostTimeLeft: controller.boostTimeLeft.value,
                      maxBoostSeconds: GameController.maxBoostSeconds,
                      boostCooldown: controller.boostCooldown.value,
                      maxCooldownSeconds: GameController.maxCooldownSeconds,
                    ),
                  ),

                  // GAME OVER
                  Obx(() {
                    if (!controller.gameOver.value)
                      return const SizedBox.shrink();
                    final bool isLoggedIn =
                        !checkOfflineMode && currentUser != null;
                    return Positioned.fill(
                      child: GameOverModal(
                        screenWidth: screenWidth,
                        finalScore: controller.score.value,
                        runCoins: controller.runCoinsGained.value,
                        totalCoins: controller.coins.value,
                        highScore: controller.highScore.value,
                        onRestart: () {
                          lastElapsed = Duration.zero;
                          normalizedAnimationValue = 0.0;
                          controller.restartGame();
                        },
                        onRevive: () {
                          lastElapsed = Duration.zero;
                          controller.buyLifeBack();
                        },
                        onHome: () {
                          Get.back();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (Get.isRegistered<HomeController>()) {
                              Get.find<HomeController>().onResume();
                            }
                          });
                        },
                        isLoggedIn: isLoggedIn,
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
