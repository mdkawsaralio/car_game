import 'package:car_game5/routes/pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/routes.dart';
import 'services/connectivity_services.dart';
import 'sound/sound_service.dart';
import 'car_customization/car_skin_service.dart';
import 'achivement/achivement_services.dart';
import 'login/user_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) {
      Get.put(ConnectivityService(), permanent: true);
    }
    if (!Get.isRegistered<SoundService>()) {
      Get.put(SoundService(), permanent: true);
    }
    if (!Get.isRegistered<CarSkinService>()) {
      Get.put(CarSkinService(), permanent: true);
    }
    if (!Get.isRegistered<AchievementService>()) {
      Get.put(AchievementService(), permanent: true);
    }
    if (!Get.isRegistered<UserDataService>()) {
      Get.put(UserDataService(), permanent: true);
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
