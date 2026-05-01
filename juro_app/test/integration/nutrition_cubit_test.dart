import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:juro_app/features/nutrition/cubit/nutrition_cubit.dart';
import 'package:juro_app/features/nutrition/repository/nutrition_repository.dart';
import 'package:juro_app/core/models/nutrition_analysis.dart';
import 'package:juro_app/core/models/traffic_light.dart';

class MockNutritionRepository extends Mock implements NutritionRepository {}

NutritionAnalyzeResponse _fakeAnalysis() => const NutritionAnalyzeResponse(
      dishName: 'ほうれん草のおひたし',
      dishNameNormalized: 'ほうれん草のおひたし',
      mealType: MealType.lunch,
      phosphorusSignal: TrafficLight.green,
      potassiumSignal: TrafficLight.yellow,
      sodiumSignal: TrafficLight.green,
      waterSignal: TrafficLight.green,
      ingredients: [
        IngredientSignal(
          ingredientName: 'ほうれん草',
          weightG: 80,
          signalColor: TrafficLight.yellow,
        ),
      ],
      allergyWarnings: [],
    );

IngredientAdvice _fakeAdvice() => const IngredientAdvice(
      ingredientName: 'ほうれん草',
      exceededNutrients: ['カリウム'],
      alternativeIngredients: ['もやし', 'キャベツ'],
      cookingTips: ['茹でこぼしでカリウムを減らせます'],
      preprocessingNote: '茹でこぼし後の推定値',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(MealType.lunch);
    registerFallbackValue('');
  });

  group('NutritionCubit 統合テスト', () {
    late MockNutritionRepository repo;

    setUp(() {
      repo = MockNutritionRepository();
    });

    // ─── analyze ─────────────────────────────────────────────────

    blocTest<NutritionCubit, NutritionState>(
      'analyze 正常系: NutritionLoading → NutritionLoaded を emit する',
      build: () {
        when(() => repo.analyze(any(), any()))
            .thenAnswer((_) async => _fakeAnalysis());
        return NutritionCubit(repo);
      },
      act: (cubit) => cubit.analyze('ほうれん草のおひたし', MealType.lunch),
      expect: () => [
        const NutritionLoading(),
        isA<NutritionLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as NutritionLoaded;
        expect(state.result.dishName, equals('ほうれん草のおひたし'));
        expect(state.result.ingredients.length, equals(1));
        expect(state.result.hasAllergyWarning, isFalse);
      },
    );

    blocTest<NutritionCubit, NutritionState>(
      'analyze 404（料理が見つからない）: NutritionError を emit し日本語メッセージ含む',
      build: () {
        when(() => repo.analyze(any(), any()))
            .thenThrow(Exception('404 Not Found'));
        return NutritionCubit(repo);
      },
      act: (cubit) => cubit.analyze('存在しない料理', MealType.dinner),
      expect: () => [
        const NutritionLoading(),
        isA<NutritionError>(),
      ],
      verify: (cubit) {
        expect(
          (cubit.state as NutritionError).message,
          contains('見つかりません'),
        );
      },
    );

    blocTest<NutritionCubit, NutritionState>(
      'analyze 401（認証切れ）: NutritionError を emit する',
      build: () {
        when(() => repo.analyze(any(), any()))
            .thenThrow(Exception('401 Unauthorized'));
        return NutritionCubit(repo);
      },
      act: (cubit) => cubit.analyze('豆腐', MealType.breakfast),
      expect: () => [
        const NutritionLoading(),
        isA<NutritionError>(),
      ],
    );

    blocTest<NutritionCubit, NutritionState>(
      'analyze ネットワークエラー: NutritionError にサーバー接続メッセージ',
      build: () {
        when(() => repo.analyze(any(), any()))
            .thenThrow(Exception('SocketException: Connection refused'));
        return NutritionCubit(repo);
      },
      act: (cubit) => cubit.analyze('豆腐', MealType.breakfast),
      expect: () => [
        const NutritionLoading(),
        isA<NutritionError>(),
      ],
      verify: (cubit) {
        expect(
          (cubit.state as NutritionError).message,
          contains('サーバーに接続できません'),
        );
      },
    );

    // ─── loadAdvice ───────────────────────────────────────────────

    blocTest<NutritionCubit, NutritionState>(
      'loadAdvice 正常系: NutritionLoadingAdvice → NutritionAdviceLoaded を emit',
      build: () {
        when(() => repo.getIngredientAdvice(any()))
            .thenAnswer((_) async => _fakeAdvice());
        return NutritionCubit(repo);
      },
      act: (cubit) => cubit.loadAdvice('food-id-001'),
      expect: () => [
        const NutritionLoadingAdvice(),
        isA<NutritionAdviceLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as NutritionAdviceLoaded;
        expect(state.advice.ingredientName, equals('ほうれん草'));
        expect(state.advice.exceededNutrients, contains('カリウム'));
        expect(state.advice.cookingTips, isNotEmpty);
      },
    );

    blocTest<NutritionCubit, NutritionState>(
      'loadAdvice エラー: NutritionError を emit する',
      build: () {
        when(() => repo.getIngredientAdvice(any()))
            .thenThrow(Exception('500 Internal Server Error'));
        return NutritionCubit(repo);
      },
      act: (cubit) => cubit.loadAdvice('bad-id'),
      expect: () => [
        const NutritionLoadingAdvice(),
        isA<NutritionError>(),
      ],
    );

    // ─── reset ────────────────────────────────────────────────────

    test('reset: NutritionInitial に戻る', () async {
      when(() => repo.analyze(any(), any()))
          .thenAnswer((_) async => _fakeAnalysis());
      final cubit = NutritionCubit(repo);
      await cubit.analyze('ほうれん草のおひたし', MealType.lunch);
      expect(cubit.state, isA<NutritionLoaded>());
      cubit.reset();
      expect(cubit.state, isA<NutritionInitial>());
    });
  });
}
