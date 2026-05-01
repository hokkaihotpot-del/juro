import 'package:flutter/material.dart';

import '../../../../core/models/traffic_light.dart';

/// 信号色を大きなアイコンで表示するバッジ
class DishSignalBadge extends StatelessWidget {
  const DishSignalBadge(this.signal, {super.key, this.size = 24});

  final TrafficLight signal;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      _emoji(signal),
      style: TextStyle(fontSize: size),
    );
  }

  static String _emoji(TrafficLight t) {
    switch (t) {
      case TrafficLight.green:
        return '🟢';
      case TrafficLight.yellow:
        return '🟡';
      case TrafficLight.red:
        return '🔴';
    }
  }
}

/// 3栄養素の信号色を横並びで表示するバー（数値は非表示）
class DailySignalBar extends StatelessWidget {
  const DailySignalBar({
    super.key,
    required this.phosphorusSignal,
    required this.potassiumSignal,
    required this.sodiumSignal,
    required this.waterSignal,
  });

  final TrafficLight phosphorusSignal;
  final TrafficLight potassiumSignal;
  final TrafficLight sodiumSignal;
  final TrafficLight waterSignal;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SignalItem(
                label: 'リン', signal: phosphorusSignal),
            _Divider(),
            _SignalItem(
                label: 'カリウム', signal: potassiumSignal),
            _Divider(),
            _SignalItem(label: '塩分', signal: sodiumSignal),
            _Divider(),
            _SignalItem(label: '水分', signal: waterSignal),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 1, height: 40, child: VerticalDivider());
}

class _SignalItem extends StatelessWidget {
  const _SignalItem({required this.label, required this.signal});
  final String label;
  final TrafficLight signal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DishSignalBadge(signal, size: 32),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
