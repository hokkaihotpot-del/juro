part of 'nutrition_cubit.dart';

abstract class NutritionState extends Equatable {
  const NutritionState();
  @override
  List<Object?> get props => [];
}

class NutritionInitial extends NutritionState {
  const NutritionInitial();
}

class NutritionLoading extends NutritionState {
  const NutritionLoading();
}

class NutritionLoadingAdvice extends NutritionState {
  const NutritionLoadingAdvice();
}

class NutritionLoaded extends NutritionState {
  final NutritionAnalyzeResponse result;
  const NutritionLoaded(this.result);
  @override
  List<Object?> get props => [result];
}

class NutritionAdviceLoaded extends NutritionState {
  final IngredientAdvice advice;
  const NutritionAdviceLoaded(this.advice);
  @override
  List<Object?> get props => [advice];
}

class NutritionError extends NutritionState {
  final String message;
  const NutritionError(this.message);
  @override
  List<Object?> get props => [message];
}
