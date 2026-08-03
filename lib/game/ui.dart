import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'car.dart';
import '../leaderboard/leaderboard_widget.dart';

class MovingDashedLine extends StatelessWidget {
  final double left;
  final double screenHeight;
  final AnimationController animation;
  final double currentSpeed;

  const MovingDashedLine({
    super.key,
    required this.left,
    required this.screenHeight,
    required this.animation,
    required this.currentSpeed,
  });

  @override
  Widget build(BuildContext context) {
    const double dashHeight = 40.0;
    const double dashSpace = 30.0;
    const double total = dashHeight + dashSpace;
    final int dashCount = (screenHeight / total).ceil() + 2;

    return Positioned(
      left: left - 2,
      top: -total,
      bottom: 0,
      child: ClipRect(
        child: SizedBox(
          width: 4,
          height: screenHeight + total,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              double speedFactor = currentSpeed / 6.0;
              double offset = (animation.value * total * speedFactor) % total;
              return Transform.translate(
                offset: Offset(0, offset),
                child: Stack(
                  children: List.generate(
                    dashCount,
                    (i) => Positioned(
                      top: i * total,
                      child: Container(
                        width: 4,
                        height: dashHeight,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class EnemyVehicleWidget extends StatelessWidget {
  final EnemyCar enemy;

  const EnemyVehicleWidget({super.key, required this.enemy});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: enemy.width,
      height: enemy.height,
      child: Image.asset(
        enemy.asset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: enemy.width,
            height: enemy.height,
            color: enemy.color.withOpacity(0.6),
            child: Icon(
              Icons.directions_car,
              color: Colors.white,
              size: enemy.width * 0.6,
            ),
          );
        },
      ),
    );
  }
}

class GameHud extends StatelessWidget {
  final int score;
  final int coins;
  final double speed;
  final bool isOfflineMode;
  final String? userEmail;
  final bool isBoosting;
  final double boostCooldown;

  const GameHud({
    super.key,
    required this.score,
    required this.coins,
    required this.speed,
    this.isOfflineMode = true,
    this.userEmail,
    required this.isBoosting,
    required this.boostCooldown,
  });

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    String displayName = "Guest";
    String? photoUrl;

    if (!isOfflineMode && user != null) {
      displayName = user.displayName ?? user.email?.split('@').first ?? 'User';
      photoUrl = user.photoURL;
    }

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (!isOfflineMode && user != null) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? Text(
                                  displayName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          "Racer: $displayName",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Speed: ${speed.toStringAsFixed(1)}",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(color: Colors.white12, height: 1, thickness: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Score: $score",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Bank: $coins 🪙",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: isBoosting ? Colors.orange : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                if (isBoosting)
                  const Text(
                    'BOOST ACTIVE',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                else if (boostCooldown > 0)
                  Text(
                    'Cooldown: ${boostCooldown.toStringAsFixed(0)}s',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  )
                else
                  const Text(
                    'Ready',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                const Spacer(),
                if (boostCooldown > 0)
                  Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: boostCooldown / 30.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// GAME CONTROL PANEL - HOLD TO BOOST
// ============================================================
class GameControlPanel extends StatelessWidget {
  final VoidCallback onMoveLeftStart;
  final VoidCallback onMoveLeftStop;
  final VoidCallback onMoveRightStart;
  final VoidCallback onMoveRightStop;
  final VoidCallback onBoostStart;
  final VoidCallback onBoostStop;
  final VoidCallback onBuyBoost;
  final bool isGameOver;
  final bool isBoosting;
  final bool canBoost;
  // Boost ring state
  final double boostTimeLeft;
  final double maxBoostSeconds;
  final double boostCooldown;
  final double maxCooldownSeconds;

  const GameControlPanel({
    super.key,
    required this.onMoveLeftStart,
    required this.onMoveLeftStop,
    required this.onMoveRightStart,
    required this.onMoveRightStop,
    required this.onBoostStart,
    required this.onBoostStop,
    required this.onBuyBoost,
    required this.isGameOver,
    required this.isBoosting,
    required this.canBoost,
    this.boostTimeLeft = 0.0,
    this.maxBoostSeconds = 5.0,
    this.boostCooldown = 0.0,
    this.maxCooldownSeconds = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT ARROW
          GestureDetector(
            onTapDown: (_) => onMoveLeftStart(),
            onTapUp: (_) => onMoveLeftStop(),
            onTapCancel: onMoveLeftStop,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          // BOOST BUTTON - HOLD TO ACTIVATE
          _BoostButton(
            onBoostStart: onBoostStart,
            onBoostStop: onBoostStop,
            onBuyBoost: onBuyBoost,
            isGameOver: isGameOver,
            isBoosting: isBoosting,
            canBoost: canBoost,
            boostTimeLeft: boostTimeLeft,
            maxBoostSeconds: maxBoostSeconds,
            boostCooldown: boostCooldown,
            maxCooldownSeconds: maxCooldownSeconds,
          ),
          // RIGHT ARROW
          GestureDetector(
            onTapDown: (_) => onMoveRightStart(),
            onTapUp: (_) => onMoveRightStop(),
            onTapCancel: onMoveRightStop,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostButton extends StatefulWidget {
  final VoidCallback onBoostStart;
  final VoidCallback onBoostStop;
  final VoidCallback onBuyBoost;
  final bool isGameOver;
  final bool isBoosting;
  final bool canBoost;
  final double boostTimeLeft;
  final double maxBoostSeconds;
  final double boostCooldown;
  final double maxCooldownSeconds;

  const _BoostButton({
    required this.onBoostStart,
    required this.onBoostStop,
    required this.onBuyBoost,
    required this.isGameOver,
    required this.isBoosting,
    required this.canBoost,
    required this.boostTimeLeft,
    required this.maxBoostSeconds,
    required this.boostCooldown,
    required this.maxCooldownSeconds,
  });

  @override
  State<_BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends State<_BoostButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  bool _pressStartedBoost = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = widget.canBoost && !widget.isBoosting;
    final bool onCooldown = widget.boostCooldown > 0 && !widget.isBoosting;

    // Ring progress: 1.0 = full green ring, drains/fills based on state.
    double ringValue;
    Color ringColor;
    if (widget.isBoosting) {
      ringValue = (widget.boostTimeLeft / widget.maxBoostSeconds).clamp(
        0.0,
        1.0,
      );
      ringColor = Colors.orangeAccent;
    } else if (onCooldown) {
      ringValue =
          1.0 -
          (widget.boostCooldown / widget.maxCooldownSeconds).clamp(0.0, 1.0);
      ringColor = Color.lerp(
        Colors.grey.shade600,
        Colors.greenAccent,
        ringValue,
      )!;
    } else {
      ringValue = 1.0;
      ringColor = Colors.greenAccent;
    }

    final Color baseColor = widget.isBoosting
        ? Colors.deepOrange
        : (ready ? Colors.blueAccent : Colors.grey.shade700);

    return Listener(
      onPointerDown: (_) {
        if (widget.isGameOver) return;
        if (!widget.isBoosting && widget.canBoost) {
          _pressStartedBoost = true;
          widget.onBoostStart();
        } else {
          _pressStartedBoost = false;
        }
      },
      onPointerUp: (_) {
        if (_pressStartedBoost) {
          _pressStartedBoost = false;
          widget.onBoostStop();
        } else if (!widget.isBoosting && !widget.isGameOver) {
          // Tapped while boost wasn't available (e.g. on cooldown) —
          // treat the tap as an attempt to buy an instant boost.
          widget.onBuyBoost();
        }
      },
      onPointerCancel: (_) {
        if (_pressStartedBoost) {
          _pressStartedBoost = false;
          widget.onBoostStop();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          // Only animate the glow pulse when ready or firing.
          final double t = (ready || widget.isBoosting)
              ? _pulseController.value
              : 0.0;
          final double ringScale = 1.0 + (t * 0.35);
          final double ringOpacity =
              (1.0 - t) * (ready || widget.isBoosting ? 0.55 : 0.0);

          return SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring showing boost/cooldown state
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: ringValue,
                    strokeWidth: 5,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  ),
                ),
                // Expanding pulse ring (only when ready or boosting)
                if (ready || widget.isBoosting)
                  Transform.scale(
                    scale: ringScale,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: baseColor.withOpacity(ringOpacity),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                // Main button
                Transform.scale(
                  scale: widget.isBoosting ? 1.0 + (t * 0.05) : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: widget.isBoosting
                            ? [Colors.orangeAccent, Colors.deepOrange.shade700]
                            : (ready
                                  ? [
                                      Colors.lightBlueAccent,
                                      Colors.blue.shade800,
                                    ]
                                  : [
                                      Colors.grey.shade600,
                                      Colors.grey.shade800,
                                    ]),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: baseColor.withOpacity(
                            widget.isBoosting ? 0.7 : (ready ? 0.45 : 0.0),
                          ),
                          blurRadius: widget.isBoosting ? 20 : 12,
                          spreadRadius: widget.isBoosting ? 3 : 1,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          color: Colors.white,
                          size: widget.isBoosting ? 30 : 28,
                        ),
                        if (!widget.isBoosting && !widget.canBoost)
                          const Text(
                            '💰100',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (widget.isBoosting)
                          Text(
                            '${widget.boostTimeLeft.toStringAsFixed(1)}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// GAME OVER MODAL
// ============================================================
class GameOverModal extends StatelessWidget {
  final double screenWidth;
  final int finalScore;
  final int runCoins;
  final int totalCoins;
  final int highScore;
  final VoidCallback onRestart;
  final VoidCallback? onRevive;
  final VoidCallback onHome;
  final bool isLoggedIn;

  const GameOverModal({
    super.key,
    required this.screenWidth,
    required this.finalScore,
    required this.runCoins,
    required this.totalCoins,
    required this.highScore,
    required this.onRestart,
    required this.onRevive,
    required this.onHome,
    this.isLoggedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool canRevive = onRevive != null && totalCoins >= 500;

    // GUEST MODE - Original UI
    if (!isLoggedIn) {
      return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.85),
          child: Center(
            child: Container(
              width: screenWidth * 0.82,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "CRASHED!",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Text(
                    "Final Score: $finalScore",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Coins collected: +$runCoins 🪙",
                    style: const TextStyle(color: Colors.amber, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total coins: $totalCoins 🪙",
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Highest Score: $highScore",
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canRevive
                          ? Colors.green.shade700
                          : Colors.transparent,
                      disabledBackgroundColor: Colors.black26,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: canRevive
                              ? Colors.transparent
                              : Colors.white12,
                          width: 1.5,
                        ),
                      ),
                      elevation: canRevive ? 4 : 0,
                    ),
                    onPressed: canRevive ? onRevive : null,
                    icon: Icon(
                      Icons.favorite,
                      color: canRevive
                          ? Colors.redAccent
                          : Colors.redAccent.withOpacity(0.2),
                    ),
                    label: Text(
                      canRevive
                          ? "Resume (500 🪙)"
                          : "Need 500 coins to Resume",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: canRevive ? Colors.white : Colors.white30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onRestart,
                    child: const Text(
                      "Race Again",
                      style: TextStyle(letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white60,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    onPressed: onHome,
                    icon: const Icon(Icons.home, size: 18),
                    label: const Text(
                      "Back to Home",
                      style: TextStyle(letterSpacing: 1, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // LOGGED-IN MODE - Full dashboard with leaderboard
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.92),
        child: Center(
          child: Container(
            width: screenWidth * 0.92,
            constraints: const BoxConstraints(maxHeight: 650),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "💥 CRASHED!",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Score',
                          finalScore.toString(),
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Coins',
                          '+$runCoins 🪙',
                          Icons.monetization_on,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Best',
                          highScore.toString(),
                          Icons.emoji_events,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Total Coins',
                          totalCoins.toString(),
                          Icons.account_balance_wallet,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  LeaderboardWidget(
                    currentScore: finalScore,
                    currentCoins: totalCoins,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canRevive
                          ? Colors.green.shade700
                          : Colors.transparent,
                      disabledBackgroundColor: Colors.black26,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: canRevive
                              ? Colors.transparent
                              : Colors.white12,
                          width: 1.5,
                        ),
                      ),
                      elevation: canRevive ? 4 : 0,
                    ),
                    onPressed: canRevive ? onRevive : null,
                    icon: Icon(
                      Icons.favorite,
                      color: canRevive
                          ? Colors.redAccent
                          : Colors.redAccent.withOpacity(0.2),
                    ),
                    label: Text(
                      canRevive
                          ? "Resume (500 🪙)"
                          : "Need 500 coins to Resume",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: canRevive ? Colors.white : Colors.white30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onRestart,
                    child: const Text(
                      "Race Again",
                      style: TextStyle(letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white60,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    onPressed: onHome,
                    icon: const Icon(Icons.home, size: 18),
                    label: const Text(
                      "Back to Home",
                      style: TextStyle(letterSpacing: 1, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }
}
