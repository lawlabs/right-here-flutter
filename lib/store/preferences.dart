import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/address_store.dart';

/// Как в LawMatic: в тестах провайдер пустой, живой экземпляр подставляет main.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final addressStoreProvider = Provider<AddressStore>(
  (ref) => throw StateError('AddressStore подставляется в main()'),
);
