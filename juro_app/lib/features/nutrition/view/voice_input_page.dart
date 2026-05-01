import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/models/traffic_light.dart';
import '../cubit/nutrition_cubit.dart';
import '../repository/nutrition_repository.dart';
import 'nutrition_result_page.dart';

class VoiceInputPage extends StatefulWidget {
  const VoiceInputPage({super.key});

  @override
  State<VoiceInputPage> createState() => _VoiceInputPageState();
}

class _VoiceInputPageState extends State<VoiceInputPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final _textCtrl = TextEditingController();
  bool _isListening = false;
  bool _speechAvailable = false;
  MealType _selectedMealType = MealType.lunch;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) => setState(() => _isListening = false),
    );
    setState(() {});
  }

  void _startListening() async {
    if (!_speechAvailable) return;
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _textCtrl.text = result.recognizedWords;
        });
      },
      localeId: 'ja_JP',
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _speech.stop();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NutritionCubit(NutritionRepository()),
      child: _VoiceInputView(
        textCtrl: _textCtrl,
        isListening: _isListening,
        speechAvailable: _speechAvailable,
        selectedMealType: _selectedMealType,
        onMealTypeChanged: (t) => setState(() => _selectedMealType = t),
        onStartListening: _startListening,
        onStopListening: _stopListening,
      ),
    );
  }
}

class _VoiceInputView extends StatelessWidget {
  const _VoiceInputView({
    required this.textCtrl,
    required this.isListening,
    required this.speechAvailable,
    required this.selectedMealType,
    required this.onMealTypeChanged,
    required this.onStartListening,
    required this.onStopListening,
  });

  final TextEditingController textCtrl;
  final bool isListening;
  final bool speechAvailable;
  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeChanged;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('料理を確認する')),
      body: BlocListener<NutritionCubit, NutritionState>(
        listener: (context, state) {
          if (state is NutritionLoaded) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => NutritionResultPage(result: state.result),
            ));
          }
          if (state is NutritionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<NutritionCubit, NutritionState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '食べたい料理を\n音声で話してください',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: GestureDetector(
                      onTap: isListening
                          ? onStopListening
                          : onStartListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening
                              ? Colors.red[400]
                              : Theme.of(context).colorScheme.primary,
                          boxShadow: isListening
                              ? [
                                  BoxShadow(
                                    color: Colors.red.shade400.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  )
                                ]
                              : [],
                        ),
                        child: Icon(
                          isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isListening ? '話してください...' : 'タップして録音開始',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey[600]),
                  ),
                  if (!speechAvailable)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '音声認識が使えません。テキストで入力してください。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  const SizedBox(height: 32),
                  // テキスト確認・修正フィールド
                  TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(
                      labelText: '料理名（確認・修正できます）',
                      hintText: '例：肉じゃが、味噌汁',
                      prefixIcon: Icon(Icons.edit),
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  // 食事タイプ選択
                  const Text('食事タイプ',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  SegmentedButton<MealType>(
                    segments: const [
                      ButtonSegment(
                          value: MealType.breakfast,
                          label: Text('朝食')),
                      ButtonSegment(
                          value: MealType.lunch, label: Text('昼食')),
                      ButtonSegment(
                          value: MealType.dinner,
                          label: Text('夕食')),
                    ],
                    selected: {selectedMealType},
                    onSelectionChanged: (s) => onMealTypeChanged(s.first),
                  ),
                  const SizedBox(height: 32),
                  if (state is NutritionLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      onPressed: textCtrl.text.isEmpty
                          ? null
                          : () => context.read<NutritionCubit>().analyze(
                                textCtrl.text.trim(),
                                selectedMealType,
                              ),
                      icon: const Icon(Icons.search),
                      label: const Text('栄養素を確認する'),
                    ),
                  // ライブ更新のためリビルド
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: textCtrl,
                    builder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
