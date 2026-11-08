import 'package:flutter_test/flutter_test.dart';
import 'package:right_here/core/pin_rules.dart';
import 'package:right_here/data/address_store.dart';

void main() {
  test('слабый GPS и кадастровая точка не записываются', () {
    expect(
      PinRules.refusal(
        precision: FixPrecision.settlement,
        source: 'settlement',
        accuracyMeters: 80,
      ),
      PinRefusal.weakGps,
    );
    expect(
      PinRules.refusal(
        precision: FixPrecision.house,
        source: 'cadastral',
        accuracyMeters: 8,
      ),
      PinRefusal.alreadyExact,
    );
    expect(
      PinRules.refusal(
        precision: FixPrecision.street,
        source: 'street',
        accuracyMeters: 12,
      ),
      isNull,
    );
  });

  test('отметка сохраняется и отменяется', () {
    final store = AddressStore.memory();
    addTearDown(store.close);
    store.debugInsert(
      id: 'a',
      precision: FixPrecision.settlement,
      source: 'settlement',
    );

    expect(
      store.pin(id: 'a', lat: 48.0, lon: 40.9, accuracyMeters: 80),
      PinRefusal.weakGps,
    );
    expect(store.pending(), hasLength(1));

    expect(
      store.pin(id: 'a', lat: 48.001, lon: 40.913, accuracyMeters: 12),
      isNull,
    );
    final pinned = store.pinned().single;
    expect(pinned.lat, 48.001);
    expect(pinned.precision, FixPrecision.driver);
    expect(pinned.canUndo, isTrue);

    store.undo('a');
    final back = store.pending().single;
    expect(back.precision, FixPrecision.settlement);
    expect(back.lat, 48);
    expect(back.canUndo, isFalse);
  });

  test('дом из кадастра кнопка не затирает', () {
    final store = AddressStore.memory();
    addTearDown(store.close);
    store.debugInsert(id: 'h', precision: FixPrecision.house, source: 'cadastral');
    expect(
      store.pin(id: 'h', lat: 1, lon: 2, accuracyMeters: 5),
      PinRefusal.alreadyExact,
    );
    expect(store.byId('h')!.precision, FixPrecision.house);
  });
}
