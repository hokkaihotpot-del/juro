import 'package:flutter/material.dart';

import '../../../../core/models/daily_menu.dart';
import '../../../../core/models/traffic_light.dart';
import '../../../../core/theme/app_theme.dart';
import 'daily_signal_bar.dart';

/// 1食分のカード（朝/昼/夕）
class MealCard extends StatefulWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.title,
    required this.icon,
  });

  final MealProposal meal;
  final String title;
  final IconData icon;

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final allGreen = meal.allGreen;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // ポジティブ強化バナー（全緑の時）
          if (allGreen)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: JuroColors.greenLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Text(
                '🟢 この食事は安心です',
                style: TextStyle(
                    color: JuroColors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ListTile(
            leading: Icon(widget.icon,
                color: Theme.of(context).colorScheme.primary),
            title: Text(widget.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17)),
            subtitle: Row(
              children: [
                DishSignalBadge(meal.phosphorusSignal, size: 16),
                const SizedBox(width: 4),
                DishSignalBadge(meal.potassiumSignal, size: 16),
                const SizedBox(width: 4),
                DishSignalBadge(meal.sodiumSignal, size: 16),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: meal.dishes
                    .map((dish) => _DishRow(dish: dish))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DishRow extends StatelessWidget {
  const _DishRow({required this.dish});
  final DishProposal dish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          DishSignalBadge(dish.signalColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dish.dishName,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          _CategoryBadge(dish.dishCategory),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge(this.category);
  final DishCategory category;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (category) {
      DishCategory.staple => ('主食', Colors.brown[200]!),
      DishCategory.main => ('主菜', Colors.blue[100]!),
      DishCategory.side => ('副菜', Colors.green[100]!),
      DishCategory.soup => ('汁物', Colors.orange[100]!),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
