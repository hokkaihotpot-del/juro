import 'traffic_light.dart';

class DishProposal {
  final String dishName;
  final DishCategory dishCategory;
  final TrafficLight signalColor;

  const DishProposal({
    required this.dishName,
    required this.dishCategory,
    required this.signalColor,
  });

  factory DishProposal.fromJson(Map<String, dynamic> json) => DishProposal(
        dishName: json['dish_name'] as String,
        dishCategory: dishCategoryFromJson(json['dish_category'] as String),
        signalColor: trafficLightFromJson(json['signal_color'] as String),
      );
}

class MealProposal {
  final MealType mealType;
  final List<DishProposal> dishes;
  final TrafficLight phosphorusSignal;
  final TrafficLight potassiumSignal;
  final TrafficLight sodiumSignal;
  final TrafficLight waterSignal;
  final double waterMl;

  const MealProposal({
    required this.mealType,
    required this.dishes,
    required this.phosphorusSignal,
    required this.potassiumSignal,
    required this.sodiumSignal,
    required this.waterSignal,
    this.waterMl = 0.0,
  });

  factory MealProposal.fromJson(Map<String, dynamic> json) => MealProposal(
        mealType: mealTypeFromJson(json['meal_type'] as String),
        dishes: (json['dishes'] as List)
            .map((d) => DishProposal.fromJson(d as Map<String, dynamic>))
            .toList(),
        phosphorusSignal:
            trafficLightFromJson(json['phosphorus_signal'] as String),
        potassiumSignal:
            trafficLightFromJson(json['potassium_signal'] as String),
        sodiumSignal: trafficLightFromJson(json['sodium_signal'] as String),
        waterSignal: trafficLightFromJson(json['water_signal'] as String),
        waterMl: (json['water_ml'] as num?)?.toDouble() ?? 0.0,
      );

  bool get allGreen =>
      phosphorusSignal == TrafficLight.green &&
      potassiumSignal == TrafficLight.green &&
      sodiumSignal == TrafficLight.green &&
      waterSignal == TrafficLight.green;
}

class DailyMenuProposal {
  final MealProposal? breakfast;
  final MealProposal? lunch;
  final MealProposal? dinner;
  final TrafficLight dailyPhosphorusSignal;
  final TrafficLight dailyPotassiumSignal;
  final TrafficLight dailySodiumSignal;
  final TrafficLight dailyWaterSignal;
  final bool isFallback;

  const DailyMenuProposal({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.dailyPhosphorusSignal,
    required this.dailyPotassiumSignal,
    required this.dailySodiumSignal,
    required this.dailyWaterSignal,
    this.isFallback = false,
  });

  factory DailyMenuProposal.fromJson(Map<String, dynamic> json) =>
      DailyMenuProposal(
        breakfast: json['breakfast'] != null
            ? MealProposal.fromJson(
                json['breakfast'] as Map<String, dynamic>)
            : null,
        lunch: json['lunch'] != null
            ? MealProposal.fromJson(json['lunch'] as Map<String, dynamic>)
            : null,
        dinner: json['dinner'] != null
            ? MealProposal.fromJson(json['dinner'] as Map<String, dynamic>)
            : null,
        dailyPhosphorusSignal:
            trafficLightFromJson(json['daily_phosphorus_signal'] as String),
        dailyPotassiumSignal:
            trafficLightFromJson(json['daily_potassium_signal'] as String),
        dailySodiumSignal:
            trafficLightFromJson(json['daily_sodium_signal'] as String),
        dailyWaterSignal:
            trafficLightFromJson(json['daily_water_signal'] as String),
        isFallback: json['is_fallback'] as bool? ?? false,
      );

  bool get allDailyGreen =>
      dailyPhosphorusSignal == TrafficLight.green &&
      dailyPotassiumSignal == TrafficLight.green &&
      dailySodiumSignal == TrafficLight.green &&
      dailyWaterSignal == TrafficLight.green;
}
