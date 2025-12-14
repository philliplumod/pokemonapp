import 'package:flutter/material.dart';

/// Simple singleton controller exposing a ValueNotifier for ThemeMode.
/// Use DarkModeController.instance.toggle() to switch modes.
class DarkModeController {
  DarkModeController._();
  static final DarkModeController instance = DarkModeController._();

  /// The notifier that holds the current ThemeMode.
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  ThemeMode get current => mode.value;

  void setLight() => mode.value = ThemeMode.light;

  void setDark() => mode.value = ThemeMode.dark;

  void toggle() {
    mode.value = mode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}
