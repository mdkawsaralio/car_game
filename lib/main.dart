// main.dart
import 'package:car_game5/routes/pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/routes.dart';
import 'services/connectivity_services.dart';
import 'sound/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('❌ Firebase error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Connectivity Service
    if (!Get.isRegistered<ConnectivityService>()) {
      Get.put(ConnectivityService(), permanent: true);
    }

    // Initialize Sound Service with preloading
    if (!Get.isRegistered<SoundService>()) {
      // Register SoundService. Do not call preloadSounds here because
      // the method may not exist on some implementations of SoundService.
      Get.put(SoundService(), permanent: true);
      print('✅ SoundService registered');
    }

    return GetMaterialApp(
      title: 'Car Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: AppRoutes.home,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
