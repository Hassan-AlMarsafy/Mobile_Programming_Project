import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _ttsEnabled = true;
  bool _srEnabled = true;

  bool get ttsEnabled => _ttsEnabled;
  bool get srEnabled => _srEnabled;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
    _srEnabled = prefs.getBool('sr_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', value);
  }

  Future<void> setSrEnabled(bool value) async {
    _srEnabled = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sr_enabled', value);
  }
}
