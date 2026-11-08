import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yandex_maps_mapkit_lite/init.dart' as mapkit_init;

import 'app/root_tab_view.dart';
import 'app/theme.dart';
import 'data/address_store.dart';
import 'mapkit_config.dart';
import 'store/preferences.dart';
import 'store/theme_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (mapkitApiKey.isNotEmpty) {
    await mapkit_init.initMapkit(apiKey: mapkitApiKey, locale: 'ru_RU');
  }
  final prefs = await SharedPreferences.getInstance();
  final store = await AddressStore.open();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        addressStoreProvider.overrideWithValue(store),
      ],
      child: const RightHereApp(),
    ),
  );
}

class RightHereApp extends ConsumerWidget {
  const RightHereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Это тут',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: const RootTabView(),
    );
  }
}
