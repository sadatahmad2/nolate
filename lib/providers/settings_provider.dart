import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _hideSensitiveItems = false;
  
  bool get hideSensitiveItems => _hideSensitiveItems;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _hideSensitiveItems = prefs.getBool('hideSensitiveItems') ?? false;
    notifyListeners();
  }

  Future<void> toggleSensitiveItems(bool value) async {
    _hideSensitiveItems = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hideSensitiveItems', value);
    notifyListeners();
  }
}
