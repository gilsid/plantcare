import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ThemeProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  late bool _isDarkMode;

  ThemeProvider(this._dbService) {
    _isDarkMode = _dbService.getThemeMode();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _dbService.saveThemeMode(_isDarkMode);
    notifyListeners();
  }
}
