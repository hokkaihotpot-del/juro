import 'package:flutter/material.dart';

import '../../../../core/models/nutrition_analysis.dart';
import '../../../../core/theme/app_theme.dart';

/// 赤食材タップ時のアドバイスボトムシート
class AdviceBottomSheet extends StatelessWidget {
  const AdviceBottomSheet({super.key, required this.advice});
  final IngredientAdvice advice;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, ctrl) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: Colors.white,
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.info_outline, color: JuroColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    advice.ingredientName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: '気になる栄養素',
              color: JuroColors.redLight,
              children: advice.exceededNutrients
                  .map((n) => Text('🔴 $n が高め',
                      style: const TextStyle(fontSize: 15)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _Section(
              title: '代わりになる食材',
              color: JuroColors.greenLight,
              children: advice.alternativeIngredients
                  .map((a) => Text('🟢 $a',
                      style: const TextStyle(fontSize: 15)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _Section(
              title: '調理の工夫',
              color: Colors.blue[50]!,
              children: advice.cookingTips
                  .map((t) => Text('💡 $t',
                      style: const TextStyle(fontSize: 15)))
                  .toList(),
            ),
            if (advice.preprocessingNote != null) ...[
              const SizedBox(height: 12),
              _Section(
                title: '下処理について',
                color: Colors.teal[50]!,
                children: [
                  Text(advice.preprocessingNote!,
                      style: const TextStyle(fontSize: 15)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title,
      required this.color,
      required this.children});
  final String title;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}
