import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;
  final RxString connectionType = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkConnectivity();
    _listenToConnectivityChanges();
  }

  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> result = await _connectivity
          .checkConnectivity();
      _updateConnectionStatus(
        result.isNotEmpty ? result.first : ConnectivityResult.none,
      );
    } catch (e) {
      isConnected.value = false;
    }
  }

  void _listenToConnectivityChanges() {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      _updateConnectionStatus(
        result.isNotEmpty ? result.first : ConnectivityResult.none,
      );
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      isConnected.value = false;
      connectionType.value = 'No Internet';
    } else {
      isConnected.value = true;
      connectionType.value = result == ConnectivityResult.wifi
          ? 'WiFi'
          : result == ConnectivityResult.mobile
          ? 'Mobile Data'
          : 'Connected';
    }
  }

  Future<bool> checkConnection() async {
    try {
      final List<ConnectivityResult> result = await _connectivity
          .checkConnectivity();
      final bool isConnectedNow =
          result.isNotEmpty && result.first != ConnectivityResult.none;
      isConnected.value = isConnectedNow;
      return isConnectedNow;
    } catch (e) {
      isConnected.value = false;
      return false;
    }
  }

  void showNoInternetSnackbar() {
    Get.snackbar(
      'No Internet Connection',
      'Please check your internet connection and try again.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade900,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.wifi_off, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      shouldIconPulse: true,
    );
  }

  void showInternetRestoredSnackbar() {
    Get.snackbar(
      'Internet Restored',
      'Your connection has been restored.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.wifi, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}
