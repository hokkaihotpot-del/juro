import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:juro_app/features/report/cubit/report_cubit.dart';
import 'package:juro_app/features/report/repository/report_repository.dart';
import 'package:juro_app/core/models/weekly_report.dart';

class MockReportRepository extends Mock implements ReportRepository {}

WeeklyReport _fakeReport({bool withData = false}) => WeeklyReport(
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 7),
      rows: List.generate(
        7,
        (i) => WeeklyReportRow(
          logDate: DateTime(2024, 1, i + 1),
          weekday: ['月', '火', '水', '木', '金', '土', '日'][i] + '曜日',
          phosphorusMg: withData ? 200.0 : 0.0,
          potassiumMg: withData ? 500.0 : 0.0,
          sodiumG: withData ? 1.5 : 0.0,
          menuSummary: withData ? '和食' : '記録なし',
        ),
      ),
      weeklyAvgPhosphorus: withData ? 200.0 : 0.0,
      weeklyAvgPotassium: withData ? 500.0 : 0.0,
      weeklyAvgSodium: withData ? 1.5 : 0.0,
      weeklyTotalPhosphorus: withData ? 1400.0 : 0.0,
      weeklyTotalPotassium: withData ? 3500.0 : 0.0,
      weeklyTotalSodium: withData ? 10.5 : 0.0,
      dailyPhosphorusLimit: 800,
      dailyPotassiumLimit: 2000,
      dailySodiumLimit: 6.0,
      phosphorusAchievementRate: withData ? 25.0 : 0.0,
      potassiumAchievementRate: withData ? 25.0 : 0.0,
      sodiumAchievementRate: withData ? 25.0 : 0.0,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
  });

  group('ReportCubit 統合テスト', () {
    late MockReportRepository repo;

    setUp(() {
      repo = MockReportRepository();
    });

    // ─── loadReport ──────────────────────────────────────────────

    blocTest<ReportCubit, ReportState>(
      'loadReport 正常系（データあり）: ReportLoading → ReportLoaded を emit',
      build: () {
        when(() => repo.getWeeklyReport(weekStart: any(named: 'weekStart')))
            .thenAnswer((_) async => _fakeReport(withData: true));
        return ReportCubit(repo);
      },
      act: (cubit) => cubit.loadReport(),
      expect: () => [
        const ReportLoading(),
        isA<ReportLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ReportLoaded;
        expect(state.report.rows.length, equals(7));
        expect(state.report.weeklyTotalPhosphorus, equals(1400.0));
      },
    );

    blocTest<ReportCubit, ReportState>(
      'loadReport 正常系（データなし）: ReportLoaded で全合計が 0',
      build: () {
        when(() => repo.getWeeklyReport(weekStart: any(named: 'weekStart')))
            .thenAnswer((_) async => _fakeReport(withData: false));
        return ReportCubit(repo);
      },
      act: (cubit) => cubit.loadReport(),
      expect: () => [
        const ReportLoading(),
        isA<ReportLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ReportLoaded;
        expect(state.report.weeklyTotalPhosphorus, equals(0.0));
        expect(state.report.weeklyTotalPotassium, equals(0.0));
        expect(state.report.weeklyTotalSodium, equals(0.0));
      },
    );

    blocTest<ReportCubit, ReportState>(
      'loadReport カスタム weekStart: 指定日付でリポジトリが呼ばれる',
      build: () {
        when(() => repo.getWeeklyReport(weekStart: any(named: 'weekStart')))
            .thenAnswer((_) async => _fakeReport());
        return ReportCubit(repo);
      },
      act: (cubit) => cubit.loadReport(weekStart: DateTime(2024, 3, 4)),
      expect: () => [
        const ReportLoading(),
        isA<ReportLoaded>(),
      ],
      verify: (_) {
        verify(() => repo.getWeeklyReport(weekStart: DateTime(2024, 3, 4)))
            .called(1);
      },
    );

    blocTest<ReportCubit, ReportState>(
      'loadReport ネットワークエラー: ReportError を emit しサーバー接続メッセージ',
      build: () {
        when(() => repo.getWeeklyReport(weekStart: any(named: 'weekStart')))
            .thenThrow(Exception('Connection refused'));
        return ReportCubit(repo);
      },
      act: (cubit) => cubit.loadReport(),
      expect: () => [
        const ReportLoading(),
        isA<ReportError>(),
      ],
      verify: (cubit) {
        expect(
          (cubit.state as ReportError).message,
          contains('サーバーに接続できません'),
        );
      },
    );

    blocTest<ReportCubit, ReportState>(
      'loadReport 502 エラー: ReportError を emit する',
      build: () {
        when(() => repo.getWeeklyReport(weekStart: any(named: 'weekStart')))
            .thenThrow(Exception('502 Bad Gateway'));
        return ReportCubit(repo);
      },
      act: (cubit) => cubit.loadReport(),
      expect: () => [
        const ReportLoading(),
        isA<ReportError>(),
      ],
    );

    // ─── sendReport ───────────────────────────────────────────────

    blocTest<ReportCubit, ReportState>(
      'sendReport 正常系: ReportSending → ReportSent を emit する',
      build: () {
        when(
          () => repo.sendReportToDoctor(
            doctorId: any(named: 'doctorId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async {});
        return ReportCubit(repo);
      },
      act: (cubit) => cubit.sendReport(
        doctorId: 'doc-001',
        weekStart: DateTime(2024, 1, 1),
      ),
      expect: () => [
        const ReportSending(),
        const ReportSent(),
      ],
    );

    blocTest<ReportCubit, ReportState>(
      'sendReport 502（メール送信失敗）: ReportError にメッセージ',
      build: () {
        when(
          () => repo.sendReportToDoctor(
            doctorId: any(named: 'doctorId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenThrow(Exception('502 Email delivery failed'));
        return ReportCubit(repo);
      },
      act: (cubit) => cubit.sendReport(
        doctorId: 'doc-001',
        weekStart: DateTime(2024, 1, 1),
      ),
      expect: () => [
        const ReportSending(),
        isA<ReportError>(),
      ],
      verify: (cubit) {
        expect(
          (cubit.state as ReportError).message,
          contains('メール送信'),
        );
      },
    );

    blocTest<ReportCubit, ReportState>(
      'sendReport ネットワークエラー: ReportError にサーバー接続メッセージ',
      build: () {
        when(
          () => repo.sendReportToDoctor(
            doctorId: any(named: 'doctorId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenThrow(Exception('SocketException: Connection refused'));
        return ReportCubit(repo);
      },
      act: (cubit) => cubit.sendReport(
        doctorId: 'doc-001',
        weekStart: DateTime(2024, 1, 1),
      ),
      expect: () => [
        const ReportSending(),
        isA<ReportError>(),
      ],
      verify: (cubit) {
        expect(
          (cubit.state as ReportError).message,
          contains('サーバーに接続できません'),
        );
      },
    );
  });
}
