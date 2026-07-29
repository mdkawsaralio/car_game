import 'package:car_game5/car_customization/garage_page.dart';
import 'package:car_game5/home/home.dart';
import 'package:car_game5/routes/routes.dart';
import 'package:car_game5/login/login.dart';
import 'package:car_game5/signup/signup.dart';
import 'package:get/get.dart';
import '../game/game_page.dart';

class AppPages {
  static List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.game,
      page: () => const GamePage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.signup, // Add this
      page: () => const SignUpPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.garage,
      page: () => GaragePage(),
      transition: Transition.fade,
    ),
  ];
}
