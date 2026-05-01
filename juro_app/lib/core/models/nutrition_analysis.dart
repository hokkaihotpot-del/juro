import 'traffic_light.dart';

class IngredientSignal {
  final String ingredientName;
  final double weightG;
  final TrafficLight signalColor;
  final bool hasAllergyWarning;
  final String? preprocessingNote;

  const IngredientSignal({
    required this.ingredientName,
    required this.weightG,
    required this.signalColor,
    this.hasAllergyWarning = false,
    this.preprocessingNote,
  });

  factory IngredientSignal.fromJson(Map<String, dynamic> json) =>
      IngredientSignal(
        ingredientName: json['ingredient_name'] as String,
        weightG: (json['weight_g'] as num).toDouble(),
        signalColor: trafficLightFromJson(json['signal_color'] as String),
        hasAllergyWarning: json['has_allergy_warning'] as bool? ?? false,
        preprocessingNote: json['preprocessing_note'] as String?,
      );
}

class NutritionAnalyzeResponse {
  final String dishName;
  final String dishNameNormalized;
  final MealType mealType;
  final TrafficLight phosphorusSignal;
  final TrafficLight potassiumSignal;
  final TrafficLight sodiumSignal;
  final TrafficLight waterSignal;
  final double waterMl;
  final List<IngredientSignal> ingredients;
  final List<String> allergyWarnings;

  const NutritionAnalyzeResponse({
    required this.dishName,
    required this.dishNameNormalized,
    required this.mealType,
    required this.phosphorusSignal,
    required this.potassiumSignal,
    required this.sodiumSignal,
    required this.waterSignal,
    this.waterMl = 0.0,
    required this.ingredients,
    required this.allergyWarnings,
  });

  factory NutritionAnalyzeResponse.fromJson(Map<String, dynamic> json) =>
      NutritionAnalyzeResponse(
        dishName: json['dish_name'] as String,
        dishNameNormalized: json['dish_name_normalized'] as String,
        mealType: mealTypeFromJson(json['meal_type'] as String),
        phosphorusSignal:
            trafficLightFromJson(json['phosphorus_signal'] as String),
        potassiumSignal:
            trafficLightFromJson(json['potassium_signal'] as String),
        sodiumSignal: trafficLightFromJson(json['sodium_signal'] as String),
        waterSignal: trafficLightFromJson(json['water_signal'] as String),
        waterMl: (json['water_ml'] as num?)?.toDouble() ?? 0.0,
        ingredients: (json['ingredients'] as List)
            .map((i) => IngredientSignal.fromJson(i as Map<String, dynamic>))
            .toList(),
        allergyWarnings: (json['allergy_warnings'] as List?)
                ?.map((w) => w as String)
                .toList() ??
            [],
      );

  bool get hasAllergyWarning => allergyWarnings.isNotEmpty;
}

class IngredientAdvice {
  final String ingredientName;
  final List<String> exceededNutrients;
  final List<String> alternativeIngredients;
  final List<String> cookingTips;
  final String? preprocessingNote;

  const IngredientAdvice({
    required this.ingredientName,
    required this.exceededNutrients,
    required this.alternativeIngredients,
    required this.cookingTips,
    this.preprocessingNote,
  });

  factory IngredientAdvice.fromJson(Map<String, dynamic> json) =>
      IngredientAdvice(
        ingredientName: json['ingredient_name'] as String,
        exceededNutrients: (json['exceeded_nutrients'] as List)
            .map((e) => e as String)
            .toList(),
        alternativeIngredients: (json['alternative_ingredients'] as List)
            .map((e) => e as String)
            .toList(),
        cookingTips:
            (json['cooking_tips'] as List).map((e) => e as String).toList(),
        preprocessingNote: json['preprocessing_note'] as String?,
      );
}
