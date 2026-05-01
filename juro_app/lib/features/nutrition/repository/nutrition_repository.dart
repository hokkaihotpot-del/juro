import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/nutrition_analysis.dart';
import '../../../core/models/traffic_light.dart';

class NutritionRepository {
  final _client = ApiClient.instance;

  Future<NutritionAnalyzeResponse> analyze(
      String dishName, MealType mealType) async {
    final response = await _client.dio.post(
      Endpoints.nutritionAnalyze,
      data: {
        'dish_name': dishName,
        'meal_type': mealTypeToJson(mealType),
      },
    );
    return NutritionAnalyzeResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<IngredientAdvice> getIngredientAdvice(String foodId) async {
    final response =
        await _client.dio.get(Endpoints.ingredientAdvice(foodId));
    return IngredientAdvice.fromJson(
        response.data as Map<String, dynamic>);
  }
}
