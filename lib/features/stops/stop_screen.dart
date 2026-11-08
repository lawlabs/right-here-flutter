import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/theme.dart';
import '../../core/pin_rules.dart';
import '../../design_system/status_tag.dart';
import '../../models/stop.dart';
import '../../store/preferences.dart';
import '../../store/stops_provider.dart';
import 'address_map.dart';

class StopScreen extends ConsumerStatefulWidget {
  const StopScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<StopScreen> createState() => _StopScreenState();
}

class _StopScreenState extends ConsumerState<StopScreen> {
  Position? _fix;
  String? _gpsProblem;
  StreamSubscription<Position>? _subscription;

  @override
  void initState() {
    super.initState();
    unawaited(_listen());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _listen() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _setProblem('Геолокация на телефоне выключена.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _setProblem('Нет доступа к геолокации.');
      return;
    }
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        ).listen((position) {
          if (!mounted) return;
          setState(() {
            _fix = position;
            _gpsProblem = null;
          });
        }, onError: (_) => _setProblem('Приём координат прервался.'));
  }

  void _setProblem(String text) {
    if (!mounted) return;
    setState(() => _gpsProblem = text);
  }

  @override
  Widget build(BuildContext context) {
    final stop = _find();
    if (stop == null) {
      return const Scaffold(
        body: Center(child: Text('Адрес уже не в списке.')),
      );
    }
    final accuracy = _fix?.accuracy;
    final refusal = PinRules.refusal(
      precision: stop.precision,
      source: stop.source,
      accuracyMeters: accuracy,
    );
    final waiting = stop.precision.waitsForDriver;
    final hasPoint = stop.lat != null && stop.lon != null;
    return Scaffold(
      appBar: AppBar(title: Text(stop.title)),
      body: Column(
        children: [
          if (hasPoint)
            SizedBox(
              height: 300,
              width: double.infinity,
              child: AddressMap(
                latitude: stop.lat!,
                longitude: stop.lon!,
                precision: stop.precision,
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Metrics.pagePadding),
              children: [
                Text(
                  stop.subtitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                StatusTag(stop.precision.label, tone: toneFor(stop.precision)),
                const SizedBox(height: Metrics.sectionGap),
                Text(stop.precision.hint),
                if (stop.lat != null && stop.lon != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Сейчас в базе: ${stop.lat!.toStringAsFixed(6)}, ${stop.lon!.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: Metrics.sectionGap),
                _GpsLine(fix: _fix, problem: _gpsProblem),
                const SizedBox(height: Metrics.sectionGap),
                if (waiting)
                  FilledButton(
                    onPressed: refusal == null && _fix != null
                        ? () => _pin(stop)
                        : null,
                    child: const Text('Это тут'),
                  ),
                if (waiting && refusal == PinRefusal.weakGps)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Кнопка включится, когда точность станет лучше 50 метров.',
                    ),
                  ),
                if (refusal == PinRefusal.alreadyExact)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Точка дома из реестра. Её эта кнопка не заменяет.',
                    ),
                  ),
                if (stop.canUndo) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(stopsProvider.notifier).undo(stop.id);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Вернуть приближённую точку'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stop? _find() {
    final lists = ref.watch(stopsProvider);
    for (final stop in [...lists.pending, ...lists.pinned]) {
      if (stop.id == widget.id) return stop;
    }
    return ref.read(addressStoreProvider).byId(widget.id);
  }

  void _pin(Stop stop) {
    final fix = _fix;
    if (fix == null) return;
    final refusal = ref
        .read(stopsProvider.notifier)
        .pin(
          id: stop.id,
          lat: fix.latitude,
          lon: fix.longitude,
          accuracyMeters: fix.accuracy,
        );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (refusal == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Дом отмечен.')));
      Navigator.of(context).pop();
    }
  }
}

class _GpsLine extends StatelessWidget {
  const _GpsLine({required this.fix, required this.problem});

  final Position? fix;
  final String? problem;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    if (problem != null) return Text(problem!, style: style);
    if (fix == null) return Text('Жду координаты…', style: style);
    final meters = fix!.accuracy.round();
    return Text('Точность GPS: $meters м', style: style);
  }
}
