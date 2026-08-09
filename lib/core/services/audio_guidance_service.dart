import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

const _kEnabled  = 'audio_guidance_enabled';
const _kLanguage = 'audio_guidance_language';

const _kDefaultLang    = 'te';
const _kDefaultEnabled = true;

enum _AudioClip { attendance, startTrip, endTrip }

class AudioGuidanceService extends GetxService {
  final _storage = const FlutterSecureStorage();
  final _player  = AudioPlayer();

  final isEnabled  = true.obs;
  final language   = _kDefaultLang.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    final stored = await _storage.read(key: _kEnabled);
    // default ON — only false if explicitly saved as 'false'
    isEnabled.value  = stored != 'false';
    language.value   = await _storage.read(key: _kLanguage) ?? _kDefaultLang;
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
    final clip = _detectClip(dashboard);
    if (clip == null) return;
    await _play(clip);
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
    // Active trip = already started
    final activeTrip = dashboard['activeTrip'] as Map<String, dynamic>?;
    if (activeTrip != null) return _AudioClip.endTrip;

    // Upcoming trips = assigned but not started
    final upcoming = dashboard['upcomingTrips'] as List?;
    if (upcoming != null && upcoming.isNotEmpty) return _AudioClip.startTrip;

    // No trips — check attendance
    final attended = dashboard['attendanceMarked'] as bool?;
    if (attended == false) return _AudioClip.attendance;

    return null;
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
