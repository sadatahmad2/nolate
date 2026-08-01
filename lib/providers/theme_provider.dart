import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  String get themeModeString {
    if (_themeMode == ThemeMode.dark) return 'DARK';
    if (_themeMode == ThemeMode.system) return 'SYSTEM';
    return 'LIGHT';
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString('themeMode') ?? 'LIGHT';
    if (modeString == 'DARK') {
      _themeMode = ThemeMode.dark;
    } else if (modeString == 'SYSTEM') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    if (mode == 'DARK') {
      _themeMode = ThemeMode.dark;
    } else if (mode == 'SYSTEM') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);
    notifyListeners();
  }
}
