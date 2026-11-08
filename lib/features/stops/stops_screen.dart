import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../design_system/status_tag.dart';
import '../../models/stop.dart';
import '../../store/stops_provider.dart';
import 'stop_screen.dart';

class StopsScreen extends ConsumerWidget {
  const StopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(stopsProvider).pending;
    return Scaffold(
      appBar: AppBar(title: const Text('К подтверждению')),
      body: pending.isEmpty
          ? const _Empty(text: 'Нет адресов, которые ждут отметки на месте.')
          : ListView.separated(
              padding: const EdgeInsets.all(Metrics.pagePadding),
              itemCount: pending.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _StopCard(pending[index]),
            ),
    );
  }
}

class PinnedScreen extends ConsumerWidget {
  const PinnedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(stopsProvider).pinned;
    return Scaffold(
      appBar: AppBar(title: const Text('Отмеченные')),
      body: pinned.isEmpty
          ? const _Empty(text: 'Отмеченных домов пока нет.')
          : ListView.separated(
              padding: const EdgeInsets.all(Metrics.pagePadding),
              itemCount: pinned.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _StopCard(pinned[index]),
            ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard(this.stop);

  final Stop stop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(stop.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stop.subtitle),
              const SizedBox(height: 8),
              StatusTag(stop.precision.label, tone: toneFor(stop.precision)),
            ],
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => StopScreen(id: stop.id)),
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Metrics.pagePadding),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
