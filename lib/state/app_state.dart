import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String _language = 'Български';
  bool _isDarkMode = false;

  String get language => _language;
  bool get isDarkMode => _isDarkMode;

  void setLanguage(String lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }
}
