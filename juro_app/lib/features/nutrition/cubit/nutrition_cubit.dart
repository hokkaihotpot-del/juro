import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/nutrition_analysis.dart';
import '../../../core/models/traffic_light.dart';
import '../repository/nutrition_repository.dart';

part 'nutrition_state.dart';

class NutritionCubit extends Cubit<NutritionState> {
  NutritionCubit(this._repo) : super(const NutritionInitial());

  final NutritionRepository _repo;

  Future<void> analyze(String dishName, MealType mealType) async {
    emit(const NutritionLoading());
    try {
      final result = await _repo.analyze(dishName, mealType);
      emit(NutritionLoaded(result));
    } catch (e) {
      emit(NutritionError(_friendlyError(e)));
    }
  }

  Future<void> loadAdvice(String foodId) async {
    emit(const NutritionLoadingAdvice());
    try {
      final advice = await _repo.getIngredientAdvice(foodId);
      emit(NutritionAdviceLoaded(advice));
    } catch (e) {
      emit(NutritionError(_friendlyError(e)));
    }
  }

  void reset() => emit(const NutritionInitial());

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('404')) return '料理が見つかりませんでした。別の料理名をお試しください';
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused')) {
      return 'サーバーに接続できません';
    }
    return '栄養素の取得に失敗しました。しばらく後にお試しください';
  }
}
