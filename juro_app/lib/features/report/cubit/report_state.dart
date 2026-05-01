part of 'report_cubit.dart';

abstract class ReportState extends Equatable {
  const ReportState();
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportLoaded extends ReportState {
  final WeeklyReport report;
  const ReportLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

class ReportSending extends ReportState {
  const ReportSending();
}

class ReportSent extends ReportState {
  const ReportSent();
}

class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
  @override
  List<Object?> get props => [message];
}
