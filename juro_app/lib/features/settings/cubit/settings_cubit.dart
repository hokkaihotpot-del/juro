import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/allergy_item.dart';
import '../../../core/models/settings.dart';
import '../repository/settings_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repo) : super(const SettingsInitial());

  final SettingsRepository _repo;

  Future<void> loadSettings() async {
    emit(const SettingsLoading());
    try {
      final settings = await _repo.getSettings();
      final allergies = await _repo.getAllergies();
      final doctors = await _repo.getDoctors();
      emit(SettingsLoaded(
        settings: settings,
        allergies: allergies.items,
        doctors: doctors,
      ));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> togglePreprocessing(bool enabled) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated =
        await _repo.updateSettings(preprocessingEnabled: enabled);
    emit(SettingsLoaded(
      settings: updated,
      allergies: current.allergies,
      doctors: current.doctors,
    ));
  }

  Future<void> changeRegion(String region) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = await _repo.updateSettings(region: region);
    emit(SettingsLoaded(
      settings: updated,
      allergies: current.allergies,
      doctors: current.doctors,
    ));
  }

  Future<void> updateNutritionLimits(NutritionLimit limits) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    await _repo.updateNutritionLimits(limits);
    await loadSettings();
  }

  Future<void> deleteAllergy(String id) async {
    await _repo.deleteAllergy(id);
    await loadSettings();
  }

  Future<void> addAllergy(String name, {bool isPreset = false}) async {
    await _repo.addAllergy(name, isPreset: isPreset);
    await loadSettings();
  }

  Future<void> addDoctor(
      String name, String? email, String? systemId) async {
    await _repo.addDoctor(name, email, systemId);
    await loadSettings();
  }
}
