import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class SoundService extends GetxService {
  final AudioPlayer _carPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer(); // crash sound (rare, one-off)
  final AudioPlayer _turboPlayer = AudioPlayer(); // kept, no longer used for boost

  // Small pool of pre-configured players for the coin pickup sound.
  // Coins can be collected in quick succession, and PlayerMode.lowLatency
  // turned out to be unreliable (silent on some devices/formats). A pool
  // of normal players, each already loaded with the source and release
  // mode set ONCE up front, gets the same result — no per-call
  // stop()/setReleaseMode() round trips — without the platform quirks.
  final List<AudioPlayer> _coinPlayers = List.generate(4, (_) => AudioPlayer());
  int _coinPlayerIndex = 0;

  RxBool isSoundEnabled = true.obs;
  RxBool isMusicEnabled = true.obs;

  static const String carSound = 'sound/car.mp3';
  static const String crushSound = 'sound/crush.mp3';
  static const String turboSound = 'sound/turbo.mp3';
  static const String homePageSound = 'sound/home_page.mp3';
  static const String coinSound = 'sound/coin.mp3';

  bool _isCarPlaying = false;
  bool _isMusicPlaying = false;
  bool _isTurboPlaying = false;
  bool _isInitialized = false;

  // Baseline car engine volume — lowered from 0.2 so it isn't so loud
  // during normal driving.
  static const double _baseCarVolume = 0.13;
  // How much extra volume normal speed ramps up to on top of the base.
  static const double _speedVolumeRange = 0.20;
  // Extra volume bump applied while boosting (replaces the separate
  // turbo sound — the engine just gets audibly louder/higher-pitched).
  static const double _boostVolumeBump = 0.22;
  static const double _boostPitchBump = 0.12;

  double _currentCarVolume = _baseCarVolume;

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
    for (final p in _coinPlayers) {
      p.dispose();
    }
    super.onClose();
  }

  void _setupAudioContexts() {
    try {
      // All players use the same audio context to avoid ducking
      final audioContext = AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none, // Prevents ducking
        ),
      );

      _carPlayer.setAudioContext(audioContext);
      _musicPlayer.setAudioContext(audioContext);
      _sfxPlayer.setAudioContext(audioContext);
      _turboPlayer.setAudioContext(audioContext);
      for (final p in _coinPlayers) {
        p.setAudioContext(audioContext);
      }
    } catch (_) {}
  }

  void _preloadSounds() async {
    if (_isInitialized) return;
    try {
      await _carPlayer.setSource(AssetSource(carSound));
      await _musicPlayer.setSource(AssetSource(homePageSound));

      // Crash sound: rare, one-off, normal player is fine.
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setSource(AssetSource(crushSound));

      // Coin pool: configure release mode + source ONCE per player here,
      // so playCoinSound() below only ever calls .play() — no repeated
      // stop()/setReleaseMode() calls on the hot path, which is what was
      // causing the stutter on every pickup.
      for (final p in _coinPlayers) {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource(coinSound));
      }

      await _turboPlayer.setSource(AssetSource(turboSound));
      _isInitialized = true;
    } catch (_) {}
  }

  void toggleSound(bool enabled) {
    isSoundEnabled.value = enabled;
    if (!enabled) stopAllSounds();
  }

  void toggleMusic(bool enabled) {
    isMusicEnabled.value = enabled;
    if (enabled)
      playHomePageMusic();
    else
      stopHomePageMusic();
  }

  Future<void> playCarSound() async {
    if (!isSoundEnabled.value || _isCarPlaying) return;
    try {
      await _carPlayer.stop();
      await _carPlayer.setReleaseMode(ReleaseMode.loop);
      await _carPlayer.play(AssetSource(carSound), volume: _baseCarVolume);
      _isCarPlaying = true;
      _currentCarVolume = _baseCarVolume;
    } catch (_) {
      _isCarPlaying = false;
    }
  }

  void stopCarSound() {
    try {
      _carPlayer.stop();
      _isCarPlaying = false;
    } catch (_) {}
  }

  /// Updates engine volume/pitch based on current speed. When [boosting]
  /// is true, the engine gets audibly louder and a bit higher-pitched
  /// instead of layering a separate turbo sound on top.
  Future<void> setCarSpeed(double speedNormalized, {bool boosting = false}) async {
    if (!_isCarPlaying) return;
    final speed = speedNormalized.clamp(0.0, 1.0);

    double volume = _baseCarVolume + (speed * _speedVolumeRange);
    double pitch = 0.85 + (speed * 0.35);

    if (boosting) {
      volume += _boostVolumeBump;
      pitch += _boostPitchBump;
    }

    volume = volume.clamp(0.0, 1.0);
    pitch = pitch.clamp(0.5, 2.0);

    _currentCarVolume = volume;
    try {
      await _carPlayer.setVolume(volume);
      await _carPlayer.setPlaybackRate(pitch);
    } catch (_) {}
  }

  bool get isCarPlaying => _isCarPlaying;

  // Kept for potential future use, but no longer called for boost —
  // boosting now just raises the car engine's own volume/pitch via
  // setCarSpeed(boosting: true) instead of layering a second sound.
  Future<void> startTurboSound() async {
    if (!isSoundEnabled.value || _isTurboPlaying) return;
    try {
      await _turboPlayer.stop();
      await _turboPlayer.setReleaseMode(ReleaseMode.loop);
      if (_isCarPlaying) {
        await _carPlayer.setVolume(_currentCarVolume * 0.7);
      }
      await _turboPlayer.play(AssetSource(turboSound), volume: 0.5);
      _isTurboPlaying = true;
    } catch (_) {
      _isTurboPlaying = false;
    }
  }

  Future<void> stopTurboSound() async {
    try {
      await _turboPlayer.stop();
      _isTurboPlaying = false;
      if (_isCarPlaying) {
        await _carPlayer.setVolume(_currentCarVolume);
      }
    } catch (_) {
      _isTurboPlaying = false;
    }
  }

  Future<void> playCoinSound() async {
    if (!isSoundEnabled.value) return;
    try {
      final player = _coinPlayers[_coinPlayerIndex];
      _coinPlayerIndex = (_coinPlayerIndex + 1) % _coinPlayers.length;
      // Fire-and-forget: this player is already loaded and configured,
      // so play() is the only call — nothing to reconfigure per pickup.
      unawaited(player.play(AssetSource(coinSound), volume: 0.35));
    } catch (_) {}
  }

  Future<void> playCrushSound() async {
    if (!isSoundEnabled.value) return;
    try {
      unawaited(_sfxPlayer.play(AssetSource(crushSound), volume: 0.7));
    } catch (_) {}
  }

  Future<void> playHomePageMusic() async {
    if (!isMusicEnabled.value) return;
    if (_isMusicPlaying) return;
    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource(homePageSound), volume: 0.2);
      _isMusicPlaying = true;
    } catch (_) {
      _isMusicPlaying = false;
    }
  }

  void stopHomePageMusic() {
    try {
      _musicPlayer.stop();
      _isMusicPlaying = false;
    } catch (_) {
      _isMusicPlaying = false;
    }
  }

  void stopAllSounds() {
    try {
      _carPlayer.stop();
      _musicPlayer.stop();
      _sfxPlayer.stop();
      _turboPlayer.stop();
      for (final p in _coinPlayers) {
        p.stop();
      }
      _isCarPlaying = false;
      _isMusicPlaying = false;
      _isTurboPlaying = false;
    } catch (_) {}
  }
}
