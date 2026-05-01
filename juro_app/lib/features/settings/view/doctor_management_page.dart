import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/settings_cubit.dart';

class DoctorManagementPage extends StatelessWidget {
  const DoctorManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('担当医情報')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is! SettingsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.doctors.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('担当医が登録されていません',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddDialog(context),
                    child: const Text('担当医を追加'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: state.doctors
                .map((doc) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_hospital),
                        title: Text(doc.doctorName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            doc.email ?? doc.systemId ?? '連絡先未登録',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('担当医を追加'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '担当医名'),
                validator: (v) =>
                    v == null || v.isEmpty ? '入力してください' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'メールアドレス（任意）'),
              ),
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
                context.read<SettingsCubit>().addDoctor(
                      nameCtrl.text.trim(),
                      emailCtrl.text.trim().isNotEmpty
                          ? emailCtrl.text.trim()
                          : null,
                      null,
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('担当医を登録しました')),
                );
              }
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }
}
