part of 'menu_cubit.dart';

abstract class MenuState extends Equatable {
  const MenuState();
  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {
  const MenuInitial();
}

class MenuLoading extends MenuState {
  const MenuLoading();
}

class MenuLoaded extends MenuState {
  final DailyMenuProposal proposal;
  const MenuLoaded(this.proposal);
  @override
  List<Object?> get props => [proposal];
}

class MenuError extends MenuState {
  final String message;
  const MenuError(this.message);
  @override
  List<Object?> get props => [message];
}
