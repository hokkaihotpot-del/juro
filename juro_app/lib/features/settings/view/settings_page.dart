import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/settings.dart';
import '../cubit/settings_cubit.dart';
import '../repository/settings_repository.dart';
import 'allergy_management_page.dart';
import 'doctor_management_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SettingsCubit(SettingsRepository())..loadSettings(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SettingsError) {
            return Center(child: Text(state.message));
          }
          if (state is! SettingsLoaded) {
            return const SizedBox.shrink();
          }

          final s = state.settings;
          return ListView(
            children: [
              // 野菜カリウム下処理補正
              _SectionHeader('栄養計算'),
              SwitchListTile(
                title: const Text('野菜カリウム下処理補正',
                    style: TextStyle(fontSize: 16)),
                subtitle: const Text(
                    '茹でこぼし・水浸漬後の値で判定します（推奨）',
                    style: TextStyle(fontSize: 13)),
                value: s.preprocessingCorrectionEnabled,
                onChanged: (v) => context
                    .read<SettingsCubit>()
                    .togglePreprocessing(v),
              ),
              const Divider(height: 1),
              // 栄養摂取上限値
              ListTile(
                title: const Text('1日の栄養摂取上限値',
                    style: TextStyle(fontSize: 16)),
                subtitle: s.nutritionLimits != null
                    ? Text(
                        'リン ${s.nutritionLimits!.phosphorusLimitMg}mg / K ${s.nutritionLimits!.potassiumLimitMg}mg / 塩分 ${s.nutritionLimits!.sodiumLimitG}g',
                        style: const TextStyle(fontSize: 13))
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showNutritionLimitsDialog(
                    context, s.nutritionLimits),
              ),
              const Divider(height: 1),
              // 地域設定
              _SectionHeader('地域設定'),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'jp', label: Text('日本')),
                    ButtonSegment(value: 'us', label: Text('米国')),
                    ButtonSegment(value: 'uk', label: Text('英国')),
                  ],
                  selected: {s.region},
                  onSelectionChanged: (sel) => context
                      .read<SettingsCubit>()
                      .changeRegion(sel.first),
                ),
              ),
              const Divider(height: 1),
              // アレルギー管理
              _SectionHeader('アレルギー'),
              ListTile(
                title: const Text('アレルギー管理',
                    style: TextStyle(fontSize: 16)),
                subtitle: Text(
                    '登録済み: ${state.allergies.length}品目',
                    style: const TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<SettingsCubit>(),
                      child: const AllergyManagementPage(),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              // 担当医管理
              _SectionHeader('担当医'),
              ListTile(
                title: const Text('担当医情報',
                    style: TextStyle(fontSize: 16)),
                subtitle: Text(
                    '登録済み: ${state.doctors.length}件',
                    style: const TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<SettingsCubit>(),
                      child: const DoctorManagementPage(),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showNutritionLimitsDialog(
      BuildContext context, NutritionLimit? limits) {
    final current = limits ?? NutritionLimit.defaults;
    final pCtrl =
        TextEditingController(text: '${current.phosphorusLimitMg}');
    final kCtrl =
        TextEditingController(text: '${current.potassiumLimitMg}');
    final naCtrl =
        TextEditingController(text: '${current.sodiumLimitG}');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('栄養摂取上限値'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LimitDialogField(ctrl: pCtrl, label: 'リン (mg/日)'),
              const SizedBox(height: 12),
              _LimitDialogField(ctrl: kCtrl, label: 'カリウム (mg/日)'),
              const SizedBox(height: 12),
              _LimitDialogField(
                  ctrl: naCtrl,
                  label: '塩分 (g/日)',
                  isDecimal: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<SettingsCubit>().updateNutritionLimits(
                      NutritionLimit(
                        phosphorusLimitMg: int.parse(pCtrl.text),
                        potassiumLimitMg: int.parse(kCtrl.text),
                        sodiumLimitG: double.parse(naCtrl.text),
                      ),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('摂取上限値を更新しました')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LimitDialogField extends StatelessWidget {
  const _LimitDialogField(
      {required this.ctrl,
      required this.label,
      this.isDecimal = false});
  final TextEditingController ctrl;
  final String label;
  final bool isDecimal;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType:
          TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.isEmpty) return '入力してください';
        final n = num.tryParse(v);
        if (n == null || n <= 0) return '正の数を入力してください';
        return null;
      },
    );
  }
}
