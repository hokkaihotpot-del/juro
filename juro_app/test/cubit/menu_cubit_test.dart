import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:juro_app/features/home/cubit/menu_cubit.dart';
import 'package:juro_app/features/home/repository/menu_repository.dart';
import 'package:juro_app/core/models/daily_menu.dart';
import 'package:juro_app/core/models/traffic_light.dart';

class MockMenuRepository extends Mock implements MenuRepository {}

DailyMenuProposal _fakeProposal() => DailyMenuProposal(
      breakfast: MealProposal(
        mealType: MealType.breakfast,
        dishes: [],
        phosphorusSignal: TrafficLight.green,
        potassiumSignal: TrafficLight.green,
        sodiumSignal: TrafficLight.green,
      ),
      lunch: MealProposal(
        mealType: MealType.lunch,
        dishes: [],
        phosphorusSignal: TrafficLight.yellow,
        potassiumSignal: TrafficLight.green,
        sodiumSignal: TrafficLight.green,
      ),
      dinner: MealProposal(
        mealType: MealType.dinner,
        dishes: [],
        phosphorusSignal: TrafficLight.green,
        potassiumSignal: TrafficLight.green,
        sodiumSignal: TrafficLight.green,
      ),
      dailyPhosphorusSignal: TrafficLight.green,
      dailyPotassiumSignal: TrafficLight.green,
      dailySodiumSignal: TrafficLight.green,
    );

void main() {
  group('MenuCubit', () {
    late MockMenuRepository repo;

    setUp(() {
      repo = MockMenuRepository();
    });

    blocTest<MenuCubit, MenuState>(
      '正常系: proposeMenu で MenuLoaded を emit する',
      build: () {
        when(() => repo.proposeMenu())
            .thenAnswer((_) async => _fakeProposal());
        return MenuCubit(repo);
      },
      act: (cubit) => cubit.proposeMenu(),
      expect: () => [
        const MenuLoading(),
        isA<MenuLoaded>(),
      ],
    );

    blocTest<MenuCubit, MenuState>(
      '異常系: API エラーで MenuError を emit する',
      build: () {
        when(() => repo.proposeMenu())
            .thenThrow(Exception('Connection refused'));
        return MenuCubit(repo);
      },
      act: (cubit) => cubit.proposeMenu(),
      expect: () => [
        const MenuLoading(),
        isA<MenuError>(),
      ],
    );

    test('MenuError のメッセージに日本語が含まれる', () async {
      when(() => repo.proposeMenu())
          .thenThrow(Exception('Connection refused'));
      final cubit = MenuCubit(repo);
      await cubit.proposeMenu();
      final state = cubit.state;
      expect(state, isA<MenuError>());
      expect((state as MenuError).message,
          contains('サーバーに接続できません'));
    });
  });
}
