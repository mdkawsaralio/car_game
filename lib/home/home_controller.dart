import 'package:car_game5/login/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/routes.dart';
import '../sound/sound_service.dart';

class HomeController extends GetxController {
  final Rx<User?> _firebaseUser = Rx<User?>(FirebaseAuth.instance.currentUser);

  final SoundService _soundService = Get.find<SoundService>();

  User? get user => _firebaseUser.value;
  bool get isLoggedIn => _firebaseUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _firebaseUser.bindStream(FirebaseAuth.instance.authStateChanges());

    // ✅ Play home page music when home screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playHomeMusic();
    });
  }

  @override
  void onClose() {
    // Don't stop music here
    super.onClose();
  }

  // ✅ Called when returning from game
  void onResume() {
    print('🔄 HomeController onResume called');
    _playHomeMusic();
  }

  Future<void> _playHomeMusic() async {
    print('🎵 Starting home music...');

    // Only stop game sounds
    _soundService.stopCarSound();
    _soundService.stopTurboSound();

    // Small delay for cleanup
    await Future.delayed(const Duration(milliseconds: 100));

    // Play home music
    await _soundService.playHomePageMusic();
  }

  void playOffline() {
    Get.toNamed(AppRoutes.game, arguments: {'isOffline': true});
  }

  void handleAuthAction() async {
    if (isLoggedIn) {
      try {
        await FirebaseAuth.instance.signOut();
        _firebaseUser.value = null;

        Get.snackbar(
          'Logged Out',
          'You have been logged out successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.grey[800],
          colorText: Colors.white,
        );
      } catch (e) {
        print('Logout error: $e');
      }
    } else {
      try {
        await Get.toNamed(AppRoutes.login);
      } catch (e) {
        Get.to(() => const LoginPage());
      }
    }
  }
}
