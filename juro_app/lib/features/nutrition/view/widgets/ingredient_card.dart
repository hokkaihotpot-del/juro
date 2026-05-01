import 'package:flutter/material.dart';

import '../../../../core/models/nutrition_analysis.dart';
import '../../../../core/models/traffic_light.dart';
import '../../../../core/theme/app_theme.dart';

/// アレルギー警告バナー（食材リスト上部に表示）
class AllergyWarningBanner extends StatelessWidget {
  const AllergyWarningBanner({super.key, required this.warnings});
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: JuroColors.redLight,
        border: Border.all(color: JuroColors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: JuroColors.red, size: 20),
              SizedBox(width: 6),
              Text(
                'アレルギー注意',
                style: TextStyle(
                    color: JuroColors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...warnings.map((w) => Text(
                'この料理には「$w」が含まれています',
                style: const TextStyle(
                    color: JuroColors.red, fontSize: 14),
              )),
        ],
      ),
    );
  }
}

/// 食材カード（信号色バッジ付き、赤タップで助言）
class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.onRedTap,
  });

  final IngredientSignal ingredient;
  final VoidCallback onRedTap;

  @override
  Widget build(BuildContext context) {
    final isRed = ingredient.signalColor == TrafficLight.red;
    final hasAllergy = ingredient.hasAllergyWarning;

    return InkWell(
      onTap: isRed ? onRedTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isRed
              ? JuroColors.redLight
              : hasAllergy
                  ? Colors.orange[50]
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRed
                ? JuroColors.red.withValues(alpha: 0.3)
                : hasAllergy
                    ? Colors.orange.shade400.withValues(alpha: 0.4)
                    : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            _signalEmoji(ingredient.signalColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ingredient.ingredientName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (hasAllergy)
                        const Text('⚠️',
                            style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${ingredient.weightG.toStringAsFixed(0)}g',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                      if (ingredient.preprocessingNote != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ingredient.preprocessingNote!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.teal[700]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isRed)
              const Icon(Icons.chevron_right, color: JuroColors.red),
          ],
        ),
      ),
    );
  }

  static Widget _signalEmoji(TrafficLight signal) {
    final emoji = switch (signal) {
      TrafficLight.green => '🟢',
      TrafficLight.yellow => '🟡',
      TrafficLight.red => '🔴',
    };
    return Text(emoji, style: const TextStyle(fontSize: 22));
  }
}
