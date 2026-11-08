import '../core/pin_rules.dart';

/// Один адрес вывоза. Несколько лицевых счетов на одном доме в этой версии
/// не плодим: учебная база хранит один счёт рядом с адресом для ориентира.
class Stop {
  const Stop({
    required this.id,
    required this.place,
    required this.street,
    required this.house,
    required this.precision,
    required this.source,
    this.account,
    this.lat,
    this.lon,
    this.accuracyMeters,
    this.pinnedAt,
    this.canUndo = false,
  });

  final String id;
  final String place;
  final String street;
  final String house;
  final String? account;
  final FixPrecision precision;
  final double? lat;
  final double? lon;
  final double? accuracyMeters;
  final String source;
  final String? pinnedAt;
  final bool canUndo;

  String get title => '$street, $house';

  String get subtitle {
    final accountLabel = account == null ? null : 'ЛС $account';
    return [place, accountLabel].whereType<String>().join(' · ');
  }
}

class StopLists {
  const StopLists({required this.pending, required this.pinned});

  final List<Stop> pending;
  final List<Stop> pinned;
}
