import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pin_rules.dart';
import '../models/stop.dart';
import 'preferences.dart';

class StopsNotifier extends Notifier<StopLists> {
  @override
  StopLists build() => _load();

  StopLists _load() {
    final store = ref.read(addressStoreProvider);
    return StopLists(pending: store.pending(), pinned: store.pinned());
  }

  PinRefusal? pin({
    required String id,
    required double lat,
    required double lon,
    required double accuracyMeters,
  }) {
    final refusal = ref
        .read(addressStoreProvider)
        .pin(id: id, lat: lat, lon: lon, accuracyMeters: accuracyMeters);
    if (refusal == null) state = _load();
    return refusal;
  }

  void undo(String id) {
    ref.read(addressStoreProvider).undo(id);
    state = _load();
  }
}

final stopsProvider = NotifierProvider<StopsNotifier, StopLists>(
  StopsNotifier.new,
);
