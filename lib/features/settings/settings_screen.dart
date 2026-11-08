import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../store/preferences.dart';
import '../../store/theme_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Оформление'),
            subtitle: Text(theme.label),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AppearanceScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Выгрузить отмеченные'),
            subtitle: const Text('CSV копируется в буфер обмена'),
            onTap: () async {
              final csv = ref.read(addressStoreProvider).exportPinnedCsv();
              await Clipboard.setData(ClipboardData(text: csv));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Список отмеченных домов скопирован.'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('О программе'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(Metrics.pagePadding),
            child: Text(
              'Сейчас в базе учебные адреса посёлка Примерный. '
              'Выгрузка всего реестра подключится отдельно. '
              'Точные точки из кадастра эта кнопка не заменяет.',
            ),
          ),
        ],
      ),
    );
  }
}

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Оформление')),
      body: RadioGroup<ThemeMode>(
        groupValue: selected,
        onChanged: (mode) {
          if (mode != null) ref.read(themeModeProvider.notifier).select(mode);
        },
        child: ListView(
          children: [
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                value: mode,
                title: Text(mode.label),
                subtitle: Text(mode.hint),
              ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О программе')),
      body: ListView(
        padding: const EdgeInsets.all(Metrics.pagePadding),
        children: [
          Text('Это тут', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Версия 1.0.0'),
          const SizedBox(height: Metrics.sectionGap),
          const Text(
            'Водитель доезжает по приближённой точке улицы или посёлка, '
            'находит номер дома и сохраняет координату места.',
          ),
          const SizedBox(height: Metrics.sectionGap),
          const Text('Карта — Яндекс Карты.'),
          const SizedBox(height: 8),
          const SelectableText(
            'Условия использования: https://yandex.ru/legal/maps_api/ru/',
          ),
        ],
      ),
    );
  }
}
