import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'game_controller.dart';
import 'car.dart';
import 'ui.dart';

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

    // Check arguments from GetX route fallback to widget parameter configuration
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

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in via Firebase Auth
    final User? currentUser = FirebaseAuth.instance.currentUser;
    // No connectivity check for guest mode!

    return Scaffold(
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
                // TREES & ROAD DECORATIONS
                ...controller.decorations.map(
                  (d) => Positioned(
                    key: ValueKey(d.hashCode),
                    left: d.x,
                    top: d.y,
                    child: Icon(d.icon, color: d.color, size: 32),
                  ),
                ),

                // MAIN ROAD ASPHALT
                Positioned(
                  left: screenWidth * 0.125,
                  right: screenWidth * 0.125,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    color: const Color.fromARGB(255, 62, 57, 57),
                  ),
                ),

                // TRACK BOUNDARIES
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

                // TRACK DASHED LANES
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
                            left: c.x,
                            top: c.y,
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
                            left: e.x,
                            top: e.y,
                            child: EnemyVehicleWidget(enemy: e),
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
                    child: PlayerCarWidget(
                      width: controller.playerWidth,
                      height: controller.playerHeight,
                      nitroActive: controller.nitroActive.value,
                    ),
                  ),
                ),

                // HUD OVERLAY
                Obx(
                  () => GameHud(
                    score: controller.score.value,
                    coins: controller.coins.value,
                    speed: controller.speed.value,
                    isOfflineMode: checkOfflineMode,
                    userEmail: currentUser?.email,
                  ),
                ),

                // USER CONTROLS PANEL
                GameControlPanel(
                  onMoveLeft: controller.moveLeft,
                  onMoveRight: controller.moveRight,
                  onNitroChanged: controller.setNitro,
                  isGameOver: controller.gameOver.value,
                ),

                // GAME OVER MODAL
                Obx(() {
                  if (!controller.gameOver.value) {
                    return const SizedBox.shrink();
                  }

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
                      isLoggedIn: isLoggedIn,
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
