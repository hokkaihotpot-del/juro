import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/weekly_report.dart';

class ReportRepository {
  final _client = ApiClient.instance;

  Future<WeeklyReport> getWeeklyReport({DateTime? weekStart}) async {
    final params = weekStart != null
        ? {'week_start': weekStart.toIso8601String().substring(0, 10)}
        : null;
    final response = await _client.dio.get(
      Endpoints.reportWeekly,
      queryParameters: params,
    );
    return WeeklyReport.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> sendReportToDoctor({
    required String doctorId,
    required DateTime weekStart,
  }) async {
    await _client.dio.post(
      Endpoints.reportSend,
      data: {
        'doctor_id': doctorId,
        'week_start': weekStart.toIso8601String().substring(0, 10),
        'user_consented': true,
      },
    );
  }
}
