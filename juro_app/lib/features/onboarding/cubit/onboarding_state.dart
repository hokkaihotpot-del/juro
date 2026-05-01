part of 'onboarding_cubit.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();
  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

class OnboardingNutritionSaved extends OnboardingState {
  const OnboardingNutritionSaved();
}

class OnboardingAllergyDone extends OnboardingState {
  const OnboardingAllergyDone();
}

class OnboardingComplete extends OnboardingState {
  const OnboardingComplete();
}

class OnboardingError extends OnboardingState {
  final String message;
  const OnboardingError(this.message);
  @override
  List<Object?> get props => [message];
}
