/// Точность точки адреса. Совпадает с qc_geo Дадаты и с отметкой водителя.
enum FixPrecision {
  /// Точный дом или участок из кадастра. Кнопка «Это тут» его не затирает.
  house,

  /// Ближайший дом, не этот номер.
  nearest,

  /// Центр улицы.
  street,

  /// Центр населённого пункта.
  settlement,

  /// Точка, которую водитель сохранил на месте.
  driver;

  static FixPrecision parse(String raw) =>
      FixPrecision.values.firstWhere((value) => value.name == raw);

  String get label => switch (this) {
    FixPrecision.house => 'Дом',
    FixPrecision.nearest => 'Ближайший дом',
    FixPrecision.street => 'Улица',
    FixPrecision.settlement => 'Населённый пункт',
    FixPrecision.driver => 'Отметил водитель',
  };

  String get hint => switch (this) {
    FixPrecision.house => 'Точка дома уже есть в реестре.',
    FixPrecision.nearest => 'На карте нашёлся соседний дом, не этот номер.',
    FixPrecision.street =>
      'Точка — центр улицы. Номер дома водитель ищет глазами.',
    FixPrecision.settlement =>
      'Точка — центр посёлка. Улица на карте отдельно не проведена.',
    FixPrecision.driver => 'Координата снята на месте.',
  };

  bool get waitsForDriver => switch (this) {
    FixPrecision.nearest ||
    FixPrecision.street ||
    FixPrecision.settlement => true,
    FixPrecision.house || FixPrecision.driver => false,
  };
}

enum PinRefusal { weakGps, alreadyExact }

/// Решение кнопки «Это тут». Чистое правило, без базы и без GPS-службы:
/// его проверяют тесты, экран только показывает отказ.
class PinRules {
  static const double maxAccuracyMeters = 50;

  static PinRefusal? refusal({
    required FixPrecision precision,
    required String source,
    required double? accuracyMeters,
  }) {
    if (source == 'cadastral' || precision == FixPrecision.house) {
      return PinRefusal.alreadyExact;
    }
    if (accuracyMeters == null || accuracyMeters > maxAccuracyMeters) {
      return PinRefusal.weakGps;
    }
    return null;
  }
}
