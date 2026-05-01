enum TrafficLight { green, yellow, red }

TrafficLight trafficLightFromJson(String value) {
  switch (value) {
    case 'green':
      return TrafficLight.green;
    case 'yellow':
      return TrafficLight.yellow;
    case 'red':
      return TrafficLight.red;
    default:
      return TrafficLight.green;
  }
}

enum MealType { breakfast, lunch, dinner }

MealType mealTypeFromJson(String value) {
  switch (value) {
    case 'breakfast':
      return MealType.breakfast;
    case 'lunch':
      return MealType.lunch;
    case 'dinner':
      return MealType.dinner;
    default:
      return MealType.lunch;
  }
}

String mealTypeToJson(MealType value) {
  switch (value) {
    case MealType.breakfast:
      return 'breakfast';
    case MealType.lunch:
      return 'lunch';
    case MealType.dinner:
      return 'dinner';
  }
}

enum DishCategory { staple, main, side, soup }

DishCategory dishCategoryFromJson(String value) {
  switch (value) {
    case 'staple':
      return DishCategory.staple;
    case 'main':
      return DishCategory.main;
    case 'side':
      return DishCategory.side;
    case 'soup':
      return DishCategory.soup;
    default:
      return DishCategory.main;
  }
}
