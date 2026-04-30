import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsViewModel extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _themeKey = 'themeMode';
  static const _localeKey = 'locale';
  static const _onboardingKey = 'onboardingSeen';
  static const _biometricKey = 'biometricEnabled';
  static const _notificationsKey = 'notificationsEnabled';
  // New-task defaults — applied by AddTaskScreen and QuickAddSheet when
  // the user creates a fresh task. -1 on the offset means "no default
  // reminder"; values 0+ are minutes-before-due.
  static const _defaultPriorityKey = 'defaultPriority';
  static const _defaultCategoryKey = 'defaultCategory';
  static const _defaultReminderOffsetKey = 'defaultReminderOffsetMinutes';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _onboardingSeen = false;
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  int _defaultPriority = 2;
  String _defaultCategory = 'General';
  int _defaultReminderOffsetMinutes = -1;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get onboardingSeen => _onboardingSeen;
  bool get biometricEnabled => _biometricEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  int get defaultPriority => _defaultPriority;
  String get defaultCategory => _defaultCategory;

  /// Minutes-before-due to schedule a default reminder, or null when the
  /// user opted out. UI uses null for "Off"; storage uses -1 to keep the
  /// box value-typed.
  int? get defaultReminderOffsetMinutes =>
      _defaultReminderOffsetMinutes < 0
          ? null
          : _defaultReminderOffsetMinutes;

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final savedTheme = box.get(_themeKey, defaultValue: 'system') as String;
    final savedLocale = box.get(_localeKey, defaultValue: 'en') as String;
    _onboardingSeen = box.get(_onboardingKey, defaultValue: false) as bool;
    _biometricEnabled = box.get(_biometricKey, defaultValue: false) as bool;
    _notificationsEnabled = box.get(_notificationsKey, defaultValue: true) as bool;
    _defaultPriority =
        box.get(_defaultPriorityKey, defaultValue: 2) as int;
    _defaultCategory =
        box.get(_defaultCategoryKey, defaultValue: 'General') as String;
    _defaultReminderOffsetMinutes =
        box.get(_defaultReminderOffsetKey, defaultValue: -1) as int;

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

  Future<void> setDefaultPriority(int priority) async {
    _defaultPriority = priority;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_defaultPriorityKey, priority);
  }

  Future<void> setDefaultCategory(String category) async {
    _defaultCategory = category;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_defaultCategoryKey, category);
  }

  /// Pass null to disable the default reminder.
  Future<void> setDefaultReminderOffsetMinutes(int? minutes) async {
    _defaultReminderOffsetMinutes = minutes ?? -1;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_defaultReminderOffsetKey, _defaultReminderOffsetMinutes);
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
