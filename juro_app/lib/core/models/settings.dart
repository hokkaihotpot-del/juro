class NutritionLimit {
  final int phosphorusLimitMg;
  final int potassiumLimitMg;
  final double sodiumLimitG;

  const NutritionLimit({
    required this.phosphorusLimitMg,
    required this.potassiumLimitMg,
    required this.sodiumLimitG,
  });

  factory NutritionLimit.fromJson(Map<String, dynamic> json) => NutritionLimit(
        phosphorusLimitMg: json['phosphorus_limit_mg'] as int,
        potassiumLimitMg: json['potassium_limit_mg'] as int,
        sodiumLimitG: (json['sodium_limit_g'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'phosphorus_limit_mg': phosphorusLimitMg,
        'potassium_limit_mg': potassiumLimitMg,
        'sodium_limit_g': sodiumLimitG,
      };

  static NutritionLimit get defaults => const NutritionLimit(
        phosphorusLimitMg: 800,
        potassiumLimitMg: 2000,
        sodiumLimitG: 6.0,
      );
}

class AppSettings {
  final String region;
  final bool preprocessingCorrectionEnabled;
  final NutritionLimit? nutritionLimits;

  const AppSettings({
    required this.region,
    required this.preprocessingCorrectionEnabled,
    this.nutritionLimits,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        region: json['region'] as String,
        preprocessingCorrectionEnabled:
            json['preprocessing_correction_enabled'] as bool,
        nutritionLimits: json['nutrition_limits'] != null
            ? NutritionLimit.fromJson(
                json['nutrition_limits'] as Map<String, dynamic>)
            : null,
      );
}

class DoctorInfo {
  final String id;
  final String doctorName;
  final String? email;
  final String? systemId;

  const DoctorInfo({
    required this.id,
    required this.doctorName,
    this.email,
    this.systemId,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) => DoctorInfo(
        id: json['id'] as String,
        doctorName: json['doctor_name'] as String,
        email: json['email'] as String?,
        systemId: json['system_id'] as String?,
      );
}
