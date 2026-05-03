class Endpoints {
  Endpoints._();

  static const baseUrl = 'https://juro-api.onrender.com';

  // Auth
  static const signup = '/v1/auth/signup';
  static const token = '/v1/auth/token';

  // Menu
  static const menuPropose = '/v1/menu/propose';

  // Nutrition
  static const nutritionAnalyze = '/v1/nutrition/analyze';
  static String ingredientAdvice(String foodId) =>
      '/v1/nutrition/ingredient/$foodId/advice';

  // Allergy
  static const allergy = '/v1/allergy';
  static String allergyDelete(String itemId) => '/v1/allergy/$itemId';

  // Settings
  static const settings = '/v1/settings';
  static const nutritionLimits = '/v1/settings/nutrition-limits';
  static const doctor = '/v1/settings/doctor';

  // Report
  static const reportWeekly = '/v1/report/weekly';
  static const reportWeeklyPdf = '/v1/report/weekly/pdf';
  static const reportSend = '/v1/report/send';
}
