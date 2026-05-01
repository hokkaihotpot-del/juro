class WeeklyReportRow {
  final DateTime logDate;
  final String weekday;
  final double phosphorusMg;
  final double potassiumMg;
  final double sodiumG;
  final String menuSummary;

  const WeeklyReportRow({
    required this.logDate,
    required this.weekday,
    required this.phosphorusMg,
    required this.potassiumMg,
    required this.sodiumG,
    required this.menuSummary,
  });

  factory WeeklyReportRow.fromJson(Map<String, dynamic> json) =>
      WeeklyReportRow(
        logDate: DateTime.parse(json['log_date'] as String),
        weekday: json['weekday'] as String,
        phosphorusMg: (json['phosphorus_mg'] as num).toDouble(),
        potassiumMg: (json['potassium_mg'] as num).toDouble(),
        sodiumG: (json['sodium_g'] as num).toDouble(),
        menuSummary: json['menu_summary'] as String? ?? '',
      );
}

class WeeklyReport {
  final DateTime startDate;
  final DateTime endDate;
  final List<WeeklyReportRow> rows;
  final double weeklyAvgPhosphorus;
  final double weeklyAvgPotassium;
  final double weeklyAvgSodium;
  final double weeklyTotalPhosphorus;
  final double weeklyTotalPotassium;
  final double weeklyTotalSodium;
  final int dailyPhosphorusLimit;
  final int dailyPotassiumLimit;
  final double dailySodiumLimit;
  final double phosphorusAchievementRate;
  final double potassiumAchievementRate;
  final double sodiumAchievementRate;

  const WeeklyReport({
    required this.startDate,
    required this.endDate,
    required this.rows,
    required this.weeklyAvgPhosphorus,
    required this.weeklyAvgPotassium,
    required this.weeklyAvgSodium,
    required this.weeklyTotalPhosphorus,
    required this.weeklyTotalPotassium,
    required this.weeklyTotalSodium,
    required this.dailyPhosphorusLimit,
    required this.dailyPotassiumLimit,
    required this.dailySodiumLimit,
    required this.phosphorusAchievementRate,
    required this.potassiumAchievementRate,
    required this.sodiumAchievementRate,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) => WeeklyReport(
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        rows: (json['rows'] as List)
            .map((r) => WeeklyReportRow.fromJson(r as Map<String, dynamic>))
            .toList(),
        weeklyAvgPhosphorus:
            (json['weekly_avg_phosphorus'] as num).toDouble(),
        weeklyAvgPotassium:
            (json['weekly_avg_potassium'] as num).toDouble(),
        weeklyAvgSodium: (json['weekly_avg_sodium'] as num).toDouble(),
        weeklyTotalPhosphorus:
            (json['weekly_total_phosphorus'] as num).toDouble(),
        weeklyTotalPotassium:
            (json['weekly_total_potassium'] as num).toDouble(),
        weeklyTotalSodium: (json['weekly_total_sodium'] as num).toDouble(),
        dailyPhosphorusLimit: json['daily_phosphorus_limit'] as int,
        dailyPotassiumLimit: json['daily_potassium_limit'] as int,
        dailySodiumLimit: (json['daily_sodium_limit'] as num).toDouble(),
        phosphorusAchievementRate:
            (json['phosphorus_achievement_rate'] as num).toDouble(),
        potassiumAchievementRate:
            (json['potassium_achievement_rate'] as num).toDouble(),
        sodiumAchievementRate:
            (json['sodium_achievement_rate'] as num).toDouble(),
      );
}
