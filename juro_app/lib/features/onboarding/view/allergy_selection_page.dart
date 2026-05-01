import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AllergySelectionPage extends StatefulWidget {
  const AllergySelectionPage({super.key});

  @override
  State<AllergySelectionPage> createState() => _AllergySelectionPageState();
}

class _AllergySelectionPageState extends State<AllergySelectionPage> {
  final Set<String> _selected = {};
  final _customCtrl = TextEditingController();
  List<String> _mandatory = [];
  List<String> _recommended = [];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final raw = await rootBundle
        .loadString('assets/data/allergen_presets.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      _mandatory =
          (json['mandatory_8'] as List).map((e) => e as String).toList();
      _recommended =
          (json['recommended_20'] as List).map((e) => e as String).toList();
    });
  }

  void _toggle(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });
  }

  void _addCustom() {
    final name = _customCtrl.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _selected.add(name);
        _customCtrl.clear();
      });
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アレルギー食材を選択')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(title: '特定原材料（表示義務8品目）'),
                _AllergyChipGrid(
                  items: _mandatory,
                  selected: _selected,
                  onToggle: _toggle,
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: '準ずるもの（推奨20品目）'),
                _AllergyChipGrid(
                  items: _recommended,
                  selected: _selected,
                  onToggle: _toggle,
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'その他（自由入力）'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customCtrl,
                        decoration: const InputDecoration(
                          hintText: '食材名を入力',
                        ),
                        onSubmitted: (_) => _addCustom(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addCustom,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_selected.any((s) =>
                    !_mandatory.contains(s) && !_recommended.contains(s))) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _selected
                        .where((s) =>
                            !_mandatory.contains(s) &&
                            !_recommended.contains(s))
                        .map((s) => Chip(
                              label: Text(s),
                              onDeleted: () => setState(
                                  () => _selected.remove(s)),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '選択中: ${_selected.length}品目',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () =>
                            Navigator.of(context).pop(_selected.toList()),
                    child: const Text('登録して次へ'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AllergyChipGrid extends StatelessWidget {
  const _AllergyChipGrid({
    required this.items,
    required this.selected,
    required this.onToggle,
  });
  final List<String> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items
          .map((item) => FilterChip(
                label: Text(item, style: const TextStyle(fontSize: 15)),
                selected: selected.contains(item),
                onSelected: (_) => onToggle(item),
                selectedColor:
                    Theme.of(context).colorScheme.primaryContainer,
              ))
          .toList(),
    );
  }
}
