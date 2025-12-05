import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _ttsEnabled = true;

  bool get ttsEnabled => _ttsEnabled;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', value);
  }
}
