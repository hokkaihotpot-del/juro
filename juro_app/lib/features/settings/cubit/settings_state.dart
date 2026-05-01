part of 'settings_cubit.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  final List<AllergyItem> allergies;
  final List<DoctorInfo> doctors;

  const SettingsLoaded({
    required this.settings,
    required this.allergies,
    required this.doctors,
  });

  @override
  List<Object?> get props => [settings, allergies, doctors];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}
