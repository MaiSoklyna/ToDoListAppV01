import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsViewModel extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _themeKey = 'themeMode';
  static const _localeKey = 'locale';
  static const _onboardingKey = 'onboardingSeen';
  static const _biometricKey = 'biometricEnabled';
  static const _notificationsKey = 'notificationsEnabled';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _onboardingSeen = false;
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get onboardingSeen => _onboardingSeen;
  bool get biometricEnabled => _biometricEnabled;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final savedTheme = box.get(_themeKey, defaultValue: 'system') as String;
    final savedLocale = box.get(_localeKey, defaultValue: 'en') as String;
    _onboardingSeen = box.get(_onboardingKey, defaultValue: false) as bool;
    _biometricEnabled = box.get(_biometricKey, defaultValue: false) as bool;
    _notificationsEnabled = box.get(_notificationsKey, defaultValue: true) as bool;

    _themeMode = _parseThemeMode(savedTheme);
    _locale = Locale(savedLocale);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_themeKey, _themeModeToString(mode));
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_localeKey, locale.languageCode);
  }

  Future<void> completeOnboarding() async {
    _onboardingSeen = true;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_onboardingKey, true);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_biometricKey, enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_notificationsKey, enabled);
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
