import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../core/pin_rules.dart';
import '../models/stop.dart';

/// Локальная база адресов. Файл только этого приложения, правки по одной
/// строке — отдельный изолят, как в LawMatic, здесь не нужен.
class AddressStore {
  AddressStore(this._db);

  final Database _db;

  static Future<AddressStore> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final db = sqlite3.open(p.join(dir.path, 'right_here.sqlite'));
    final store = AddressStore(db);
    store._migrate();
    store._seedIfEmpty();
    return store;
  }

  /// Память для тестов: без учебного посёлка.
  factory AddressStore.memory() {
    final store = AddressStore(sqlite3.openInMemory());
    store._migrate();
    return store;
  }

  void _migrate() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS address (
        id TEXT PRIMARY KEY,
        place TEXT NOT NULL,
        street TEXT NOT NULL,
        house TEXT NOT NULL,
        account TEXT,
        precision TEXT NOT NULL,
        lat REAL,
        lon REAL,
        accuracy_m REAL,
        source TEXT NOT NULL,
        pinned_at TEXT,
        previous_precision TEXT,
        previous_lat REAL,
        previous_lon REAL,
        previous_source TEXT
      )
    ''');
  }

  void _seedIfEmpty() {
    final count =
        _db.select('SELECT COUNT(*) AS n FROM address').first['n'] as int;
    if (count > 0) return;
    // Учебный посёлок. Улицы, дома и счета выдуманы.
    // У переулка точка линии улицы, у остальных домов центр посёлка.
    const settlementLat = 55.100000;
    const settlementLon = 37.200000;
    const rows =
        <(String, String, String, String, FixPrecision, double, double)>[
          (
            '1001',
            'ул. Полевая',
            '4',
            'settlement',
            FixPrecision.settlement,
            settlementLat,
            settlementLon,
          ),
          (
            '1002',
            'пер. Тихий',
            '7',
            'street',
            FixPrecision.street,
            55.102400,
            37.198700,
          ),
          (
            '1003',
            'ул. Речная',
            '12',
            'settlement',
            FixPrecision.settlement,
            settlementLat,
            settlementLon,
          ),
          (
            '1004',
            'ул. Садовая',
            '3',
            'settlement',
            FixPrecision.settlement,
            settlementLat,
            settlementLon,
          ),
          (
            '1005',
            'пер. Лесной',
            '9',
            'settlement',
            FixPrecision.settlement,
            settlementLat,
            settlementLon,
          ),
          (
            '1006',
            'ул. Заречная',
            '15',
            'settlement',
            FixPrecision.settlement,
            settlementLat,
            settlementLon,
          ),
          (
            '1007',
            'ул. Школьная',
            '1',
            'settlement',
            FixPrecision.settlement,
            settlementLat,
            settlementLon,
          ),
          (
            '1008',
            'ул. Луговая',
            '8',
            'settlement',
            FixPrecision.settlement,
            settlementLat,
            settlementLon,
          ),
        ];
    final stmt = _db.prepare('''
      INSERT INTO address (
        id, place, street, house, account, precision, lat, lon, source
      ) VALUES (?, 'п. Примерный', ?, ?, ?, ?, ?, ?, ?)
    ''');
    for (final row in rows) {
      stmt.execute([
        'demo-${row.$1}',
        row.$2,
        row.$3,
        row.$1,
        row.$5.name,
        row.$6,
        row.$7,
        row.$4,
      ]);
    }
    stmt.close();
  }

  List<Stop> pending() => _where(
    "precision IN ('nearest', 'street', 'settlement') ORDER BY street, house",
  );

  List<Stop> pinned() => _where("precision = 'driver' ORDER BY pinned_at DESC");

  Stop? byId(String id) {
    final rows = _db.select('SELECT * FROM address WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return _stop(rows.first);
  }

  PinRefusal? pin({
    required String id,
    required double lat,
    required double lon,
    required double accuracyMeters,
  }) {
    final current = byId(id);
    if (current == null) return PinRefusal.alreadyExact;
    final refusal = PinRules.refusal(
      precision: current.precision,
      source: current.source,
      accuracyMeters: accuracyMeters,
    );
    if (refusal != null) return refusal;
    _db.execute(
      '''
      UPDATE address SET
        previous_precision = precision,
        previous_lat = lat,
        previous_lon = lon,
        previous_source = source,
        precision = ?,
        lat = ?,
        lon = ?,
        accuracy_m = ?,
        source = 'driver',
        pinned_at = ?
      WHERE id = ?
      ''',
      [
        FixPrecision.driver.name,
        lat,
        lon,
        accuracyMeters,
        DateTime.now().toUtc().toIso8601String(),
        id,
      ],
    );
    return null;
  }

  void undo(String id) {
    _db.execute(
      '''
      UPDATE address SET
        precision = previous_precision,
        lat = previous_lat,
        lon = previous_lon,
        source = previous_source,
        accuracy_m = NULL,
        pinned_at = NULL,
        previous_precision = NULL,
        previous_lat = NULL,
        previous_lon = NULL,
        previous_source = NULL
      WHERE id = ? AND previous_precision IS NOT NULL
      ''',
      [id],
    );
  }

  String exportPinnedCsv() {
    final buffer = StringBuffer('Адрес;Широта;Долгота;Точность м;Когда\n');
    for (final stop in pinned()) {
      buffer.writeln(
        [
          '${stop.place}, ${stop.title}',
          stop.lat?.toStringAsFixed(6) ?? '',
          stop.lon?.toStringAsFixed(6) ?? '',
          stop.accuracyMeters?.toStringAsFixed(0) ?? '',
          stop.pinnedAt ?? '',
        ].join(';'),
      );
    }
    return buffer.toString();
  }

  List<Stop> _where(String tail) {
    return _db.select('SELECT * FROM address WHERE $tail').map(_stop).toList();
  }

  Stop _stop(Row row) {
    return Stop(
      id: row['id'] as String,
      place: row['place'] as String,
      street: row['street'] as String,
      house: row['house'] as String,
      account: row['account'] as String?,
      precision: FixPrecision.parse(row['precision'] as String),
      lat: (row['lat'] as num?)?.toDouble(),
      lon: (row['lon'] as num?)?.toDouble(),
      accuracyMeters: (row['accuracy_m'] as num?)?.toDouble(),
      source: row['source'] as String,
      pinnedAt: row['pinned_at'] as String?,
      canUndo: row['previous_precision'] != null,
    );
  }

  void close() => _db.close();

  /// Строка для теста. В приложении адреса приходят из выгрузки, не отсюда.
  void debugInsert({
    required String id,
    required FixPrecision precision,
    required String source,
    double lat = 48,
    double lon = 40.9,
  }) {
    _db.execute(
      '''
      INSERT INTO address (
        id, place, street, house, precision, lat, lon, source
      ) VALUES (?, 'п. Примерный', 'ул. Тестовая', '1', ?, ?, ?, ?)
      ''',
      [id, precision.name, lat, lon, source],
    );
  }
}
