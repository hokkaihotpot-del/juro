import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:juro_app/features/nutrition/view/widgets/ingredient_card.dart';
import 'package:juro_app/core/models/nutrition_analysis.dart';
import 'package:juro_app/core/models/traffic_light.dart';

void main() {
  group('IngredientCard', () {
    testWidgets('緑バッジ: 🟢 が表示され赤テキストなし', (tester) async {
      final ingredient = IngredientSignal(
        ingredientName: 'ほうれん草',
        weightG: 80,
        signalColor: TrafficLight.green,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IngredientCard(
              ingredient: ingredient,
              onRedTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('🟢'), findsOneWidget);
      expect(find.text('🔴'), findsNothing);
    });

    testWidgets('赤バッジ: 🔴 が表示され赤タップアイコンあり', (tester) async {
      final ingredient = IngredientSignal(
        ingredientName: 'じゃがいも',
        weightG: 150,
        signalColor: TrafficLight.red,
      );
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IngredientCard(
              ingredient: ingredient,
              onRedTap: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.text('🔴'), findsOneWidget);

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('アレルギー食材: ⚠️ アイコンが表示される', (tester) async {
      final ingredient = IngredientSignal(
        ingredientName: '卵',
        weightG: 60,
        signalColor: TrafficLight.yellow,
        hasAllergyWarning: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IngredientCard(
              ingredient: ingredient,
              onRedTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('⚠️'), findsOneWidget);
    });

    testWidgets('下処理ノート: preprocessingNote が表示される', (tester) async {
      final ingredient = IngredientSignal(
        ingredientName: 'ほうれん草',
        weightG: 80,
        signalColor: TrafficLight.green,
        preprocessingNote: '茹でこぼし後の推定値',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IngredientCard(
              ingredient: ingredient,
              onRedTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('茹でこぼし後の推定値'), findsOneWidget);
    });
  });
}
