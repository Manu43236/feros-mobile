import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

const _kEnabled  = 'audio_guidance_enabled';
const _kLanguage = 'audio_guidance_language';

const _kDefaultLang    = 'te';
const _kDefaultEnabled = true;

enum _AudioClip { attendance, startTrip, endTrip }

class AudioGuidanceService extends GetxService with WidgetsBindingObserver {
  final _storage = const FlutterSecureStorage();
  final _player  = AudioPlayer();

  final isEnabled  = true.obs;
  final language   = _kDefaultLang.obs;

  // Prevents replaying on pull-to-refresh; resets each fresh app open (onInit)
  bool _hasPlayedThisSession = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    final stored = await _storage.read(key: _kEnabled);
    isEnabled.value = stored != 'false';
    language.value  = await _storage.read(key: _kLanguage) ?? _kDefaultLang;
  }

  // Stop audio when app goes to background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      stop();
    }
  }

  Future<void> setEnabled(bool value) async {
    isEnabled.value = value;
    await _storage.write(key: _kEnabled, value: value.toString());
  }

  Future<void> setLanguage(String lang) async {
    language.value = lang;
    await _storage.write(key: _kLanguage, value: lang);
  }

  Future<void> playForDashboard(Map<String, dynamic> dashboard) async {
    if (!isEnabled.value) return;
    if (_hasPlayedThisSession) return; // skip on pull-to-refresh
    final clip = _detectClip(dashboard);
    if (clip == null) return;
    _hasPlayedThisSession = true;
    await _play(clip);
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> playTripStarted() => _playFile('trip_started.mp3');
  Future<void> playTripEnded()   => _playFile('trip_ended.mp3');

  Future<void> _play(_AudioClip clip) async {
    final fileName = switch (clip) {
      _AudioClip.attendance => 'attendance.mp3',
      _AudioClip.startTrip  => 'start_trip.mp3',
      _AudioClip.endTrip    => 'end_trip.mp3',
    };
    await _playFile(fileName);
  }

  Future<void> _playFile(String fileName) async {
    if (!isEnabled.value) return;
    final path = 'audio/${language.value}/$fileName';
    await _player.stop();
    await _player.play(AssetSource(path));
  }

  _AudioClip? _detectClip(Map<String, dynamic> dashboard) {
    final activeTrip = dashboard['activeTrip'] as Map<String, dynamic>?;
    if (activeTrip != null) return _AudioClip.endTrip;

    final upcoming = dashboard['upcomingTrips'] as List?;
    if (upcoming != null && upcoming.isNotEmpty) return _AudioClip.startTrip;

    final attended = dashboard['attendanceMarked'] as bool?;
    if (attended == false) return _AudioClip.attendance;

    return null;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.onClose();
  }
}
