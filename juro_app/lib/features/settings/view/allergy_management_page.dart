import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/settings_cubit.dart';

class AllergyManagementPage extends StatefulWidget {
  const AllergyManagementPage({super.key});

  @override
  State<AllergyManagementPage> createState() =>
      _AllergyManagementPageState();
}

class _AllergyManagementPageState
    extends State<AllergyManagementPage> {
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アレルギー管理')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is! SettingsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 登録済み一覧
              const Text('登録済みアレルギー食材',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (state.allergies.isEmpty)
                const Text('登録されていません',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 14))
              else
                ...state.allergies.map((item) => ListTile(
                      leading: const Text('🚫',
                          style: TextStyle(fontSize: 20)),
                      title: Text(item.ingredientName,
                          style: const TextStyle(fontSize: 16)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => context
                            .read<SettingsCubit>()
                            .deleteAllergy(item.id),
                      ),
                    )),
              const Divider(height: 32),
              // プリセットから追加
              const Text('プリセットから追加',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _PresetAdder(
                registeredNames: state.allergies
                    .map((a) => a.ingredientName)
                    .toSet(),
                onAdd: (name) => context
                    .read<SettingsCubit>()
                    .addAllergy(name, isPreset: true),
              ),
              const Divider(height: 32),
              // 自由入力で追加
              const Text('その他（自由入力）',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customCtrl,
                      decoration: const InputDecoration(
                          hintText: '食材名を入力'),
                      onSubmitted: (_) => _addCustom(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _addCustom(context),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _addCustom(BuildContext context) {
    final name = _customCtrl.text.trim();
    if (name.isNotEmpty) {
      context.read<SettingsCubit>().addAllergy(name);
      _customCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'アレルギー情報を更新しました。次回の献立提案から反映されます。')),
      );
    }
  }
}

class _PresetAdder extends StatefulWidget {
  const _PresetAdder(
      {required this.registeredNames, required this.onAdd});
  final Set<String> registeredNames;
  final ValueChanged<String> onAdd;

  @override
  State<_PresetAdder> createState() => _PresetAdderState();
}

class _PresetAdderState extends State<_PresetAdder> {
  List<String> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle
        .loadString('assets/data/allergen_presets.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      _all = [
        ...(json['mandatory_8'] as List).map((e) => e as String),
        ...(json['recommended_20'] as List).map((e) => e as String),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: _all
          .where((name) => !widget.registeredNames.contains(name))
          .map((name) => ActionChip(
                label: Text(name,
                    style: const TextStyle(fontSize: 14)),
                avatar:
                    const Icon(Icons.add, size: 16),
                onPressed: () => widget.onAdd(name),
              ))
          .toList(),
    );
  }
}
