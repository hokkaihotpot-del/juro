import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingInitial());

  static const _onboardingKey = 'onboarding_complete';

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> saveNutritionLimits({
    required int phosphorusMg,
    required int potassiumMg,
    required double sodiumG,
  }) async {
    emit(const OnboardingLoading());
    try {
      await ApiClient.instance.dio.patch(
        Endpoints.nutritionLimits,
        data: {
          'phosphorus_limit_mg': phosphorusMg,
          'potassium_limit_mg': potassiumMg,
          'sodium_limit_g': sodiumG,
        },
      );
      emit(const OnboardingNutritionSaved());
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  Future<void> saveAllergies(List<String> names) async {
    emit(const OnboardingLoading());
    try {
      for (final name in names) {
        await ApiClient.instance.dio.post(
          Endpoints.allergy,
          data: {'ingredient_name': name, 'is_preset': true},
        );
      }
      emit(const OnboardingAllergyDone());
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    emit(const OnboardingComplete());
  }
}
