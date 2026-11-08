import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/pin_rules.dart';

enum Tone { info, ok, warn }

extension ToneStyle on Tone {
  Color color(BuildContext context) {
    final base = switch (this) {
      Tone.info => AppTheme.brandNavy,
      Tone.ok => const Color(0xFF1C7A4A),
      Tone.warn => const Color(0xFFB5540A),
    };
    if (Theme.of(context).brightness == Brightness.dark) {
      return Color.lerp(base, Colors.white, 0.45)!;
    }
    return base;
  }

  Color fill(BuildContext context) => color(context).withValues(alpha: 0.14);
}

class StatusTag extends StatelessWidget {
  const StatusTag(this.text, {super.key, required this.tone});

  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: tone.fill(context),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: tone.color(context),
          height: 1.2,
        ),
      ),
    );
  }
}

Tone toneFor(FixPrecision precision) => switch (precision) {
  FixPrecision.driver || FixPrecision.house => Tone.ok,
  FixPrecision.street || FixPrecision.nearest => Tone.info,
  FixPrecision.settlement => Tone.warn,
};
