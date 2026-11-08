import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as mk;
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';
import 'package:yandex_maps_mapkit_lite/yandex_map.dart';

import '../../core/pin_rules.dart';
import '../../mapkit_config.dart';

/// Карта адреса. Метка — точка из базы. Синий знак карты — телефон.
class AddressMap extends StatefulWidget {
  const AddressMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.precision,
  });

  final double latitude;
  final double longitude;
  final FixPrecision precision;

  @override
  State<AddressMap> createState() => _AddressMapState();
}

class _AddressMapState extends State<AddressMap> {
  late final AppLifecycleListener _lifecycle;

  mk.MapWindow? _window;
  mk.PlacemarkMapObject? _pin;
  mk.UserLocationLayer? _userLayer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (mapkitApiKey.isEmpty) return;
    _start();
    _lifecycle = AppLifecycleListener(onResume: _start, onInactive: _stop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _window?.map.nightModeEnabled =
        Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void dispose() {
    if (mapkitApiKey.isNotEmpty) {
      _stop();
      _lifecycle.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (mapkitApiKey.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFE6E8EC),
        child: Center(child: Text('Ключ Яндекс Карт не передан при сборке.')),
      );
    }
    return Stack(
      children: [
        YandexMap(
          onMapCreated: _onMapCreated,
          platformViewType: PlatformViewType.Hybrid,
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Column(
            children: [
              _MapButton(icon: Icons.place_outlined, onPressed: _showAddress),
              const SizedBox(height: 8),
              _MapButton(icon: Icons.my_location, onPressed: _showMe),
            ],
          ),
        ),
      ],
    );
  }

  void _onMapCreated(mk.MapWindow window) {
    _window = window;
    _pin = window.map.mapObjects.addPlacemarkWithPoint(
      mk.Point(latitude: widget.latitude, longitude: widget.longitude),
    );
    _userLayer = mapkit.createUserLocationLayer(window)
      ..setDefaultSource()
      ..setVisible(true);
    window.map.nightModeEnabled =
        Theme.of(context).brightness == Brightness.dark;
    _showAddress();
  }

  void _showAddress() {
    final window = _window;
    if (window == null) return;
    _pin?.geometry = mk.Point(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
    window.map.move(
      mk.CameraPosition(
        mk.Point(latitude: widget.latitude, longitude: widget.longitude),
        zoom: _zoom,
        azimuth: 0,
        tilt: 0,
      ),
      animation: const mk.Animation(
        type: mk.AnimationType.Smooth,
        duration: 0.25,
      ),
    );
  }

  void _showMe() {
    final window = _window;
    final camera = _userLayer?.cameraPosition();
    if (window == null || camera == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Положение ещё не определилось.')),
      );
      return;
    }
    final zoom = camera.zoom < 16 ? 16.0 : camera.zoom;
    window.map.move(
      mk.CameraPosition(camera.target, zoom: zoom, azimuth: 0, tilt: 0),
      animation: const mk.Animation(
        type: mk.AnimationType.Smooth,
        duration: 0.25,
      ),
    );
  }

  double get _zoom => switch (widget.precision) {
    FixPrecision.settlement => 14,
    FixPrecision.street || FixPrecision.nearest => 16,
    FixPrecision.house || FixPrecision.driver => 17,
  };

  void _start() {
    if (_started) return;
    _started = true;
    mapkit.onStart();
  }

  void _stop() {
    if (!_started) return;
    _started = false;
    mapkit.onStop();
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: scheme.primary),
        ),
      ),
    );
  }
}
