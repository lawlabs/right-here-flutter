import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences.dart';

extension ThemeModeLabels on ThemeMode {
  String get label => switch (this) {
    ThemeMode.system => 'Как в системе',
    ThemeMode.light => 'Светлая',
    ThemeMode.dark => 'Тёмная',
  };

  String get hint => switch (this) {
    ThemeMode.system => 'Следовать настройке Android',
    ThemeMode.light => 'Всегда светлая',
    ThemeMode.dark => 'Всегда тёмная',
  };
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'righthere.themeMode';

  @override
  ThemeMode build() {
    final saved = ref.read(sharedPreferencesProvider)?.getString(_key);
    return ThemeMode.values.where((mode) => mode.name == saved).firstOrNull ??
        ThemeMode.system;
  }

  void select(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider)?.setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
