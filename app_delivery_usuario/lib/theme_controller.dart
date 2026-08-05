import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> initialize() async {
    try {
      _mode = modeFromStorage(await _storage.read(key: _storageKey));
    } catch (error) {
      debugPrint('No se pudo leer la preferencia de tema: $error');
      _mode = ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _storage.write(key: _storageKey, value: mode.storageValue);
    } catch (error) {
      debugPrint('No se pudo guardar la preferencia de tema: $error');
    }
  }

  @visibleForTesting
  static ThemeMode modeFromStorage(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

extension ThemeModePresentation on ThemeMode {
  String get storageValue => switch (this) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  String get displayName => switch (this) {
    ThemeMode.light => 'Claro',
    ThemeMode.dark => 'Oscuro',
    ThemeMode.system => 'Según el sistema',
  };
}
