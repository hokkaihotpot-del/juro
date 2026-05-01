import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/onboarding_cubit.dart';
import 'allergy_selection_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // 栄養上限値入力
  final _phosphorusCtrl =
      TextEditingController(text: '800');
  final _potassiumCtrl =
      TextEditingController(text: '2000');
  final _sodiumCtrl = TextEditingController(text: '6.0');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageCtrl.dispose();
    _phosphorusCtrl.dispose();
    _potassiumCtrl.dispose();
    _sodiumCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<OnboardingCubit, OnboardingState>(
            listener: (context, state) {
              if (state is OnboardingNutritionSaved) {
                _nextPage();
              }
              if (state is OnboardingComplete) {
                Navigator.of(context)
                    .pushReplacementNamed('/');
              }
              if (state is OnboardingError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  _ProgressBar(current: _currentPage, total: 3),
                  Expanded(
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _WelcomePage(onNext: _nextPage),
                        _NutritionLimitsPage(
                          formKey: _formKey,
                          phosphorusCtrl: _phosphorusCtrl,
                          potassiumCtrl: _potassiumCtrl,
                          sodiumCtrl: _sodiumCtrl,
                          isLoading: state is OnboardingLoading,
                          onNext: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<OnboardingCubit>().saveNutritionLimits(
                                    phosphorusMg: int.parse(
                                        _phosphorusCtrl.text),
                                    potassiumMg:
                                        int.parse(_potassiumCtrl.text),
                                    sodiumG: double.parse(_sodiumCtrl.text),
                                  );
                            }
                          },
                        ),
                        _AllergyPage(
                          isLoading: state is OnboardingLoading,
                          onSkip: () => context
                              .read<OnboardingCubit>()
                              .completeOnboarding(),
                          onHasAllergy: () async {
                            final selected =
                                await Navigator.of(context).push<List<String>>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AllergySelectionPage(),
                              ),
                            );
                            if (selected != null && selected.isNotEmpty &&
                                context.mounted) {
                              await context
                                  .read<OnboardingCubit>()
                                  .saveAllergies(selected);
                              if (context.mounted) {
                                context
                                    .read<OnboardingCubit>()
                                    .completeOnboarding();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LinearProgressIndicator(
        value: (current + 1) / total,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.restaurant_menu,
              size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text('JUROへようこそ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          const Text(
            '透析患者の食事管理をサポートするアプリです。\n'
            '医師の指示に基づいた設定を行いましょう。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onNext,
            child: const Text('はじめる'),
          ),
        ],
      ),
    );
  }
}

class _NutritionLimitsPage extends StatelessWidget {
  const _NutritionLimitsPage({
    required this.formKey,
    required this.phosphorusCtrl,
    required this.potassiumCtrl,
    required this.sodiumCtrl,
    required this.isLoading,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phosphorusCtrl;
  final TextEditingController potassiumCtrl;
  final TextEditingController sodiumCtrl;
  final bool isLoading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('1日の栄養摂取上限値',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              '担当医の指示値を入力してください。\nわからない場合は標準値のままで構いません。',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _LimitField(
              controller: phosphorusCtrl,
              label: 'リン（mg/日）',
              hint: '標準: 800',
            ),
            const SizedBox(height: 16),
            _LimitField(
              controller: potassiumCtrl,
              label: 'カリウム（mg/日）',
              hint: '標準: 2000',
            ),
            const SizedBox(height: 16),
            _LimitField(
              controller: sodiumCtrl,
              label: '塩分（g/日）',
              hint: '標準: 6.0',
              isDecimal: true,
            ),
            const SizedBox(height: 32),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: onNext,
                child: const Text('次へ'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LimitField extends StatelessWidget {
  const _LimitField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isDecimal = false,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isDecimal;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType:
          TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (v) {
        if (v == null || v.isEmpty) return '入力してください';
        final n = num.tryParse(v);
        if (n == null || n <= 0) return '正の数を入力してください';
        return null;
      },
    );
  }
}

class _AllergyPage extends StatelessWidget {
  const _AllergyPage({
    required this.isLoading,
    required this.onSkip,
    required this.onHasAllergy,
  });
  final bool isLoading;
  final VoidCallback onSkip;
  final VoidCallback onHasAllergy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 64, color: Colors.orange),
          const SizedBox(height: 24),
          Text('アレルギーはありますか？',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          const Text(
            'JUROはアレルギー食材を献立に含めません。\n登録しておくと安全に利用できます。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 48),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            ElevatedButton(
              onPressed: onHasAllergy,
              child: const Text('ある'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onSkip,
              child: const Text('ない・スキップ'),
            ),
          ],
        ],
      ),
    );
  }
}
