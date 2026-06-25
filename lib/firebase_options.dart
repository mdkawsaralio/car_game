import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class SoundService extends GetxService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();

  RxBool isSoundEnabled = true.obs;
  RxBool isMusicEnabled = true.obs;

  static const String carSound = 'sound/car.mp3';
  static const String crushSound = 'sound/crush.mp3';
  static const String turboSound = 'sound/turbo.mp3';
  static const String homePageSound = 'sound/home_page.mp3';
  static const String coinSound = 'sound/coin.mp3';

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    _backgroundPlayer.dispose();
    super.onClose();
  }

  Future<void> _loadSettings() async {
    // Load from SharedPreferences if needed
  }

  void toggleSound(bool enabled) {
    isSoundEnabled.value = enabled;
    if (!enabled) {
      _audioPlayer.stop();
      _backgroundPlayer.stop();
    }
  }

  void toggleMusic(bool enabled) {
    isMusicEnabled.value = enabled;
    if (enabled) {
      playHomePageMusic();
    } else {
      stopHomePageMusic();
    }
  }

  Future<void> playSound(String assetPath, {double volume = 0.5}) async {
    if (!isSoundEnabled.value) return;

    try {
      String cleanPath = assetPath;
      if (cleanPath.startsWith('assets/')) {
        cleanPath = cleanPath.substring(7);
      }
      if (cleanPath.startsWith('lib/')) {
        cleanPath = cleanPath.substring(4);
      }

      print('🔊 Playing sound: $cleanPath');

      // IMPORTANT: Reset release mode to normal before playing
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(cleanPath), volume: volume);
    } catch (e) {
      print('❌ Error playing sound ($assetPath): $e');
    }
  }

  // 1. CAR ENGINE SOUND - FIXED
  Future<void> playCarSound() async {
    if (!isSoundEnabled.value) return;

    try {
      print('🚗 Playing car sound');

      // Set to loop mode
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(carSound), volume: 0.4);
    } catch (e) {
      print('❌ Error playing car sound: $e');
    }
  }

  void stopCarSound() {
    try {
      _audioPlayer.stop();
      // Reset to stop mode after stopping
      _audioPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      print('❌ Error stopping car sound: $e');
    }
  }

  // 2. CRUSH SOUND
  void playCrushSound() {
    print('💥 Playing crush sound');
    playSound(crushSound, volume: 0.8);
  }

  // 3. TURBO SOUND - FIXED
  void playTurboSound() {
    print('⚡ Playing turbo sound');
    // Play without loop
    playSound(turboSound, volume: 0.6);
  }

  // 4. HOME PAGE MUSIC
  Future<void> playHomePageMusic() async {
    if (!isMusicEnabled.value) return;

    try {
      print('🎵 Playing home page music');
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.stop();
      await _backgroundPlayer.play(AssetSource(homePageSound), volume: 0.3);
    } catch (e) {
      print('❌ Error playing home page music: $e');
    }
  }

  void stopHomePageMusic() {
    try {
      _backgroundPlayer.stop();
      _backgroundPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      print('❌ Error stopping home page music: $e');
    }
  }

  void pauseHomePageMusic() {
    try {
      _backgroundPlayer.pause();
    } catch (e) {
      print('❌ Error pausing home page music: $e');
    }
  }

  void resumeHomePageMusic() {
    if (isMusicEnabled.value) {
      try {
        _backgroundPlayer.resume();
      } catch (e) {
        print('❌ Error resuming home page music: $e');
      }
    }
  }

  // 5. COIN SOUND - FIXED
  void playCoinSound() {
    print('🪙 Playing coin sound');
    // This will now play normally because playSound resets the mode
    playSound(coinSound, volume: 0.5);
  }

  // Preload all sounds
  Future<void> preloadSounds() async {
    try {
      final assets = [
        carSound,
        crushSound,
        turboSound,
        coinSound,
        homePageSound,
      ];

      for (final asset in assets) {
        try {
          await _audioPlayer.setSourceAsset(asset);
          print('✅ Sound loaded: $asset');
        } catch (e) {
          print('❌ Failed to load sound: $asset - $e');
        }
      }
      print('✅ All sounds preloaded successfully');
    } catch (e) {
      print('❌ Error preloading sounds: $e');
    }
  }

  void stopAllSounds() {
    try {
      _audioPlayer.stop();
      _audioPlayer.setReleaseMode(ReleaseMode.stop);
      _backgroundPlayer.stop();
      _backgroundPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      print('❌ Error stopping all sounds: $e');
    }
  }
}
