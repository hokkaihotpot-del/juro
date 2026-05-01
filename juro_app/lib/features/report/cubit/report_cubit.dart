import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/weekly_report.dart';
import '../repository/report_repository.dart';

part 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._repo) : super(const ReportInitial());

  final ReportRepository _repo;

  Future<void> loadReport({DateTime? weekStart}) async {
    emit(const ReportLoading());
    try {
      final report = await _repo.getWeeklyReport(weekStart: weekStart);
      emit(ReportLoaded(report));
    } catch (e) {
      emit(ReportError(_friendlyError(e)));
    }
  }

  Future<void> sendReport({
    required String doctorId,
    required DateTime weekStart,
  }) async {
    emit(const ReportSending());
    try {
      await _repo.sendReportToDoctor(
          doctorId: doctorId, weekStart: weekStart);
      emit(const ReportSent());
    } catch (e) {
      emit(ReportError(_friendlyError(e)));
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('502')) return 'メール送信に失敗しました。担当医の情報を確認してください';
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused')) {
      return 'サーバーに接続できません';
    }
    return 'レポートの取得に失敗しました';
  }
}
