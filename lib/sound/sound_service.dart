import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class SoundService extends GetxService {
  // ============================================================
  // SEPARATE PLAYERS - Each with its own audio context
  // ============================================================
  final AudioPlayer _carPlayer = AudioPlayer(); // Car engine - DEDICATED
  final AudioPlayer _musicPlayer = AudioPlayer(); // Home music
  final AudioPlayer _sfxPlayer = AudioPlayer(); // Coin, Crash
  final AudioPlayer _turboPlayer = AudioPlayer(); // Turbo loop

  // ============================================================
  // SETTINGS
  // ============================================================
  RxBool isSoundEnabled = true.obs;
  RxBool isMusicEnabled = true.obs;

  // ============================================================
  // SOUND PATHS
  // ============================================================
  static const String carSound = 'sound/car.mp3';
  static const String crushSound = 'sound/crush.mp3';
  static const String turboSound = 'sound/turbo.mp3';
  static const String homePageSound = 'sound/home_page.mp3';
  static const String coinSound = 'sound/coin.mp3';

  // ============================================================
  // STATE TRACKING
  // ============================================================
  bool _isCarPlaying = false;
  bool _isMusicPlaying = false;
  bool _isTurboPlaying = false;
  bool _isInitialized = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================
  @override
  void onInit() {
    super.onInit();
    _setupAudioContexts();
    _preloadSounds();
  }

  @override
  void onClose() {
    _carPlayer.dispose();
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    _turboPlayer.dispose();
    super.onClose();
  }

  // ============================================================
  // SETUP - WITH INDEPENDENT AUDIO CONTEXTS
  // ============================================================
  void _setupAudioContexts() {
    try {
      // Car player - MUSIC type with NO ducking
      _carPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none, // NO focus = no ducking
          ),
        ),
      );

      // Music player - MUSIC type
      _musicPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );

      // SFX player - SONIFICATION type (short sounds)
      _sfxPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none, // NO ducking
          ),
        ),
      );

      // Turbo player - SONIFICATION type
      _turboPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none, // NO ducking
          ),
        ),
      );

      print('✅ Audio contexts configured - NO ducking');
    } catch (e) {
      print('❌ Audio context error: $e');
    }
  }

  void _preloadSounds() async {
    if (_isInitialized) return;
    try {
      print('🎵 Preloading sounds...');

      await _carPlayer.setSource(AssetSource(carSound));
      await _musicPlayer.setSource(AssetSource(homePageSound));
      await _sfxPlayer.setSource(AssetSource(coinSound));
      await _sfxPlayer.setSource(AssetSource(crushSound));
      await _sfxPlayer.setSource(AssetSource(turboSound));
      await _turboPlayer.setSource(AssetSource(turboSound));

      _isInitialized = true;
      print('✅ Sounds preloaded');
    } catch (e) {
      print('❌ Preload error: $e');
    }
  }

  void toggleSound(bool enabled) {
    isSoundEnabled.value = enabled;
    if (!enabled) stopAllSounds();
  }

  void toggleMusic(bool enabled) {
    isMusicEnabled.value = enabled;
    if (enabled) {
      playHomePageMusic();
    } else {
      stopHomePageMusic();
    }
  }

  // ============================================================
  // CAR ENGINE - DEDICATED PLAYER (NO FADING)
  // ============================================================
  Future<void> playCarSound() async {
    if (!isSoundEnabled.value || _isCarPlaying) return;
    try {
      await _carPlayer.stop();
      await _carPlayer.setReleaseMode(ReleaseMode.loop);
      await _carPlayer.play(AssetSource(carSound), volume: 0.3);
      _isCarPlaying = true;
      print('🚗 Car sound started');
    } catch (e) {
      _isCarPlaying = false;
      print('❌ Car sound error: $e');
    }
  }

  void stopCarSound() {
    try {
      _carPlayer.stop();
      _isCarPlaying = false;
      print('🛑 Car sound stopped');
    } catch (_) {}
  }

  // ✅ CRITICAL: Keep car volume constant
  Future<void> setCarVolume(double volume) async {
    if (!_isCarPlaying) return;
    await _carPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  bool get isCarPlaying => _isCarPlaying;

  // ============================================================
  // TURBO SOUND
  // ============================================================
  Future<void> startTurboSound() async {
    print('⚡ Turbo start requested');

    if (!isSoundEnabled.value) {
      print('⚠️ Sound disabled');
      return;
    }

    if (_isTurboPlaying) {
      print('⚠️ Turbo already playing');
      return;
    }

    try {
      await _turboPlayer.stop();
      await _turboPlayer.setReleaseMode(ReleaseMode.loop);
      await _turboPlayer.play(AssetSource(turboSound), volume: 0.5);
      _isTurboPlaying = true;
      print('⚡ Turbo sound STARTED');
    } catch (e) {
      _isTurboPlaying = false;
      print('❌ Turbo start error: $e');

      try {
        await Future.delayed(const Duration(milliseconds: 100));
        await _turboPlayer.stop();
        await _turboPlayer.setReleaseMode(ReleaseMode.loop);
        await _turboPlayer.play(AssetSource(turboSound), volume: 0.5);
        _isTurboPlaying = true;
        print('⚡ Turbo sound STARTED (retry)');
      } catch (e2) {
        print('❌ Turbo retry failed: $e2');
      }
    }
  }

  Future<void> stopTurboSound() async {
    try {
      await _turboPlayer.stop();
      _isTurboPlaying = false;
      print('⚡ Turbo sound STOPPED');
    } catch (e) {
      _isTurboPlaying = false;
      print('❌ Turbo stop error: $e');
    }
  }

  bool get isTurboPlaying => _isTurboPlaying;

  // ============================================================
  // SFX SOUNDS - Coin, Crash (Car continues playing)
  // ============================================================
  Future<void> playCoinSound() async {
    if (!isSoundEnabled.value) return;
    try {
      // ✅ Stop only SFX, NOT car
      await _sfxPlayer.stop();
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);
      await _sfxPlayer.play(AssetSource(coinSound), volume: 0.4);
      print('🪙 Coin sound (car continues)');
    } catch (e) {
      print('❌ Coin error: $e');
    }
  }

  Future<void> playCrushSound() async {
    if (!isSoundEnabled.value) return;
    try {
      // ✅ Stop only SFX, NOT car
      await _sfxPlayer.stop();
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);
      await _sfxPlayer.play(AssetSource(crushSound), volume: 0.7);
      print('💥 Crash sound (car continues)');
    } catch (e) {
      print('❌ Crash error: $e');
    }
  }

  // ============================================================
  // HOME MUSIC
  // ============================================================
  Future<void> playHomePageMusic() async {
    if (!isMusicEnabled.value) return;
    if (_isMusicPlaying) {
      print('🎵 Music already playing');
      return;
    }

    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource(homePageSound), volume: 0.2);
      _isMusicPlaying = true;
      print('✅ Home music started');
    } catch (e) {
      _isMusicPlaying = false;
      print('❌ Music error: $e');
    }
  }

  void stopHomePageMusic() {
    try {
      _musicPlayer.stop();
      _isMusicPlaying = false;
      print('🎵 Home music stopped');
    } catch (_) {
      _isMusicPlaying = false;
    }
  }

  bool get isMusicPlaying => _isMusicPlaying;

  // ============================================================
  // STOP ALL
  // ============================================================
  void stopAllSounds() {
    try {
      _carPlayer.stop();
      _musicPlayer.stop();
      _sfxPlayer.stop();
      _turboPlayer.stop();
      _isCarPlaying = false;
      _isMusicPlaying = false;
      _isTurboPlaying = false;
      print('🛑 All sounds stopped');
    } catch (_) {}
  }

  bool get isInitialized => _isInitialized;
}
