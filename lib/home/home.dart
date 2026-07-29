import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_controller.dart';
import '../routes/routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HomeController());
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onResume();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06060B),
      body: Stack(
        children: [
          _buildBackground(),
          _buildGlowOrbs(),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 48,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.04),
                          Colors.white.withOpacity(0.01),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCarIcon(),
                        const SizedBox(height: 28),
                        _buildTitle(),
                        const SizedBox(height: 44),
                        Obx(() => _buildPrimaryButton(controller)),
                        const SizedBox(height: 16),
                        Obx(() => _buildSecondaryButton(controller)),
                        // ========== NEW GARAGE BUTTON ==========
                        const SizedBox(height: 16),
                        _buildGarageButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Obx(() {
            if (!controller.isLoggedIn) return const SizedBox.shrink();
            return _buildProfileSection(context);
          }),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF05050A),
            Color(0xFF140707),
            Color(0xFF05050A),
            Color(0xFF070714),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildGlowOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.redAccent.withOpacity(0.14),
                  Colors.redAccent.withOpacity(0.03),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.06),
                  Colors.blueAccent.withOpacity(0.01),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarIcon() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161626), Color(0xFF0E0E18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_car_filled_rounded,
        size: 56,
        color: Color(0xFFFF4D4D),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 280,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text(
              'CAR GAME',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: Color(0xFFFFF2F2),
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
                shadows: [
                  Shadow(
                    color: Colors.redAccent,
                    blurRadius: 15,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'DRIVE TO SURVIVE',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(HomeController controller) {
    return Container(
      width: 260,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3B30), Color(0xFFC62828)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (controller.isLoggedIn) {
            Get.toNamed(AppRoutes.game, arguments: {'isOffline': false});
          } else {
            controller.handleAuthAction();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.isLoggedIn
                  ? Icons.play_arrow_rounded
                  : Icons.login_rounded,
              size: 22,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              controller.isLoggedIn ? 'START RACING' : 'GET STARTED',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(HomeController controller) {
    return SizedBox(
      width: 260,
      height: 54,
      child: OutlinedButton(
        onPressed: () {
          if (controller.isLoggedIn) {
            _showLogoutDialog(Get.context!, controller);
          } else {
            Get.toNamed(AppRoutes.game, arguments: {'isOffline': true});
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: controller.isLoggedIn
                ? Colors.redAccent.withOpacity(0.4)
                : Colors.white.withOpacity(0.12),
            width: 1.2,
          ),
          backgroundColor: Colors.white.withOpacity(0.01),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.isLoggedIn
                  ? Icons.logout_rounded
                  : Icons.person_outline_rounded,
              size: 18,
              color: controller.isLoggedIn
                  ? Colors.redAccent.shade100
                  : Colors.grey[400],
            ),
            const SizedBox(width: 10),
            Text(
              controller.isLoggedIn ? 'SIGN OUT' : 'PLAY AS GUEST',
              style: TextStyle(
                color: controller.isLoggedIn
                    ? Colors.redAccent.shade100
                    : Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== NEW GARAGE BUTTON ==========
  Widget _buildGarageButton() {
    return SizedBox(
      width: 260,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => Get.toNamed(AppRoutes.garage),
        icon: const Icon(Icons.car_repair, color: Colors.white, size: 18),
        label: const Text(
          'GARAGE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E18).withOpacity(0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF161626),
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName!
                            : user?.email?.split('@').first ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, HomeController controller) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B12),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'EXIT SESSION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Disconnect your driver profile stream?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            controller.handleAuthAction();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text(
                            'LOGOUT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
