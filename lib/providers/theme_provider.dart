import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({ThemeMode initial = ThemeMode.light})
      : _themeMode = initial;

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    DatabaseHelper.instance.setSetting('theme_mode', _themeMode.index.toString());
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    DatabaseHelper.instance.setSetting('theme_mode', mode.index.toString());
    notifyListeners();
  }
}
