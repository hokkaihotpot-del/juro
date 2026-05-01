import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/allergy_item.dart';
import '../../../core/models/settings.dart';

class SettingsRepository {
  final _client = ApiClient.instance;

  Future<AppSettings> getSettings() async {
    final response = await _client.dio.get(Endpoints.settings);
    return AppSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppSettings> updateSettings({
    bool? preprocessingEnabled,
    String? region,
  }) async {
    final data = <String, dynamic>{};
    if (preprocessingEnabled != null) {
      data['preprocessing_correction_enabled'] = preprocessingEnabled;
    }
    if (region != null) data['region'] = region;
    final response = await _client.dio.patch(Endpoints.settings, data: data);
    return AppSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NutritionLimit> updateNutritionLimits(
      NutritionLimit limits) async {
    final response = await _client.dio.patch(
      Endpoints.nutritionLimits,
      data: limits.toJson(),
    );
    return NutritionLimit.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<AllergyListResponse> getAllergies() async {
    final response = await _client.dio.get(Endpoints.allergy);
    return AllergyListResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<AllergyItem> addAllergy(String name,
      {bool isPreset = false}) async {
    final response = await _client.dio.post(
      Endpoints.allergy,
      data: {'ingredient_name': name, 'is_preset': isPreset},
    );
    return AllergyItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAllergy(String id) async {
    await _client.dio.delete(Endpoints.allergyDelete(id));
  }

  Future<List<DoctorInfo>> getDoctors() async {
    final response = await _client.dio.get(Endpoints.doctor);
    return (response.data as List)
        .map((d) => DoctorInfo.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorInfo> addDoctor(
      String name, String? email, String? systemId) async {
    final response = await _client.dio.post(
      Endpoints.doctor,
      data: {
        'doctor_name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (systemId != null && systemId.isNotEmpty) 'system_id': systemId,
      },
    );
    return DoctorInfo.fromJson(response.data as Map<String, dynamic>);
  }
}
