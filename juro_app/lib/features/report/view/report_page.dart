import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/weekly_report.dart';
import '../cubit/report_cubit.dart';
import '../repository/report_repository.dart';
import 'send_consent_dialog.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportCubit(ReportRepository())..loadReport(),
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('栄養レポート'),
        actions: [
          BlocBuilder<ReportCubit, ReportState>(
            builder: (context, state) {
              if (state is ReportLoaded) {
                return IconButton(
                  icon: const Icon(Icons.send),
                  tooltip: '担当医へ送信',
                  onPressed: () =>
                      _showConsentDialog(context, state.report),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ReportCubit, ReportState>(
        listener: (context, state) {
          if (state is ReportSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('担当医へのレポート送信が完了しました'),
                backgroundColor: Color(0xFF388E3C),
              ),
            );
          }
          if (state is ReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReportError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ReportCubit>().loadReport(),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            );
          }
          if (state is ReportLoaded) {
            return _ReportTable(report: state.report);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showConsentDialog(
      BuildContext context, WeeklyReport report) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SendConsentDialog(weekStart: report.startDate),
    );
    if (result == true && context.mounted) {
      // 担当医選択（仮：最初の担当医へ送信）
      context.read<ReportCubit>().sendReport(
            doctorId: 'default',
            weekStart: report.startDate,
          );
    }
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({required this.report});
  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_fmt(report.startDate)} 〜 ${_fmt(report.endDate)}',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 週次データテーブル（横スクロール対応）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              dataTextStyle: const TextStyle(fontSize: 13),
              columns: const [
                DataColumn(label: Text('日付')),
                DataColumn(label: Text('リン(mg)')),
                DataColumn(label: Text('K(mg)')),
                DataColumn(label: Text('塩分(g)')),
                DataColumn(label: Text('献立')),
              ],
              rows: [
                ...report.rows.map((row) => DataRow(cells: [
                      DataCell(Text(row.weekday)),
                      DataCell(Text(row.phosphorusMg.toStringAsFixed(0))),
                      DataCell(Text(row.potassiumMg.toStringAsFixed(0))),
                      DataCell(Text(row.sodiumG.toStringAsFixed(1))),
                      DataCell(Text(
                        row.menuSummary,
                        overflow: TextOverflow.ellipsis,
                      )),
                    ])),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 週次サマリーカード
          _SummaryCard(report: report),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}年${d.month}月${d.day}日';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});
  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('週次サマリー',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _Row('週平均 リン',
                '${report.weeklyAvgPhosphorus.toStringAsFixed(0)} mg'),
            _Row('週平均 カリウム',
                '${report.weeklyAvgPotassium.toStringAsFixed(0)} mg'),
            _Row('週平均 塩分',
                '${report.weeklyAvgSodium.toStringAsFixed(1)} g'),
            const Divider(),
            _Row('1日上限 リン',
                '${report.dailyPhosphorusLimit} mg'),
            _Row('1日上限 カリウム',
                '${report.dailyPotassiumLimit} mg'),
            _Row('1日上限 塩分',
                '${report.dailySodiumLimit.toStringAsFixed(1)} g'),
            const Divider(),
            _RateRow('リン 達成率',
                report.phosphorusAchievementRate),
            _RateRow('カリウム 達成率',
                report.potassiumAchievementRate),
            _RateRow('塩分 達成率', report.sodiumAchievementRate),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow(this.label, this.rate);
  final String label;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).toStringAsFixed(1);
    final color =
        rate < 0.7 ? Colors.green : rate < 1.0 ? Colors.orange : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text('$pct%',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color)),
        ],
      ),
    );
  }
}
