import 'package:flutter/material.dart';

class ThemeManager with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData getTheme() {
    return _isDarkMode ? darkTheme : lightTheme;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      colorScheme: ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.blueAccent[100] ?? Colors.blue,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.grey[500] ?? Colors.grey,
      colorScheme: ColorScheme.dark(
        primary: Colors.blue[400] ?? Colors.grey,
        secondary: Colors.grey[300] ?? Colors.grey,
      ),
    );
  }
}
