import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/nutrition_analysis.dart';
import '../../../core/models/traffic_light.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/nutrition_cubit.dart';
import '../repository/nutrition_repository.dart';
import 'widgets/advice_bottom_sheet.dart';
import 'widgets/ingredient_card.dart';

class NutritionResultPage extends StatelessWidget {
  const NutritionResultPage({super.key, required this.result});
  final NutritionAnalyzeResponse result;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NutritionCubit(NutritionRepository()),
      child: _NutritionResultView(result: result),
    );
  }
}

class _NutritionResultView extends StatelessWidget {
  const _NutritionResultView({required this.result});
  final NutritionAnalyzeResponse result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(result.dishNameNormalized),
      ),
      body: BlocListener<NutritionCubit, NutritionState>(
        listener: (context, state) {
          if (state is NutritionAdviceLoaded) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) =>
                  AdviceBottomSheet(advice: state.advice),
            );
          }
          if (state is NutritionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: ListView(
          children: [
            // 料理全体の信号色サマリー
            _DishSignalSummary(result: result),
            // アレルギー警告バナー
            AllergyWarningBanner(warnings: result.allergyWarnings),
            // 食材カード一覧タイトル
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('食材一覧',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            // 全食材に信号色バッジを表示（グレーアウトなし）
            ...result.ingredients.map((ing) => BlocBuilder<NutritionCubit, NutritionState>(
                  builder: (context, _) => IngredientCard(
                    ingredient: ing,
                    onRedTap: () => context
                        .read<NutritionCubit>()
                        .loadAdvice(ing.ingredientName),
                  ),
                )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DishSignalSummary extends StatelessWidget {
  const _DishSignalSummary({required this.result});
  final NutritionAnalyzeResponse result;

  @override
  Widget build(BuildContext context) {
    final allGreen = result.phosphorusSignal == TrafficLight.green &&
        result.potassiumSignal == TrafficLight.green &&
        result.sodiumSignal == TrafficLight.green &&
        result.waterSignal == TrafficLight.green;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (allGreen)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '🟢 この料理は安心です',
                  style: TextStyle(
                      color: JuroColors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SignalColumn(
                    label: 'リン', signal: result.phosphorusSignal),
                _SignalColumn(
                    label: 'カリウム', signal: result.potassiumSignal),
                _SignalColumn(
                    label: '塩分', signal: result.sodiumSignal),
                _SignalColumn(
                    label: '水分', signal: result.waterSignal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalColumn extends StatelessWidget {
  const _SignalColumn({required this.label, required this.signal});
  final String label;
  final TrafficLight signal;

  @override
  Widget build(BuildContext context) {
    final emoji = switch (signal) {
      TrafficLight.green => '🟢',
      TrafficLight.yellow => '🟡',
      TrafficLight.red => '🔴',
    };
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
