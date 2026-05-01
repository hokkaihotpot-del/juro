import 'package:flutter/material.dart';

/// 担当医への送信前に必ずユーザー同意を得るダイアログ（要件3.3.2）
class SendConsentDialog extends StatelessWidget {
  const SendConsentDialog({super.key, required this.weekStart});
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final period =
        '${weekStart.month}月${weekStart.day}日〜${weekEnd.month}月${weekEnd.day}日';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding:
          const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_hospital_outlined,
              size: 48, color: Color(0xFF1A6B3C)),
          const SizedBox(height: 16),
          const Text(
            'あなたが食べた先週1週間分の\n献立を担当医へ\n送ってもいいですか？',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, height: 1.6),
          ),
          const SizedBox(height: 8),
          Text(
            '対象期間：$period',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(110, 48),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('いいえ'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(110, 48),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('はい'),
        ),
      ],
    );
  }
}
