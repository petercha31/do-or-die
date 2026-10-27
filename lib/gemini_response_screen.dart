import 'package:flutter/material.dart';

import 'services/gemini/api_key.dart';
import 'services/gemini/gemini_service.dart';
import 'services/gemini/prompts.dart';
import 'goal_register_screen.dart';
import 'services/gemini/verification_options.dart';
import 'widgets/app_button.dart';
import 'widgets/section_label.dart';

class GeminiResponseScreen extends StatefulWidget {
  const GeminiResponseScreen({super.key, required this.sentence});

  final String sentence;

  @override
  State<GeminiResponseScreen> createState() => _GeminiResponseScreenState();
}

class _GeminiResponseScreenState extends State<GeminiResponseScreen> {
  final _responseController = TextEditingController();
  var _options = const <VerificationOption>[];
  DateTime? _startAt;
  DateTime? _endAt;
  String? _formatError;
  int? _selectedIndex;
  var _calling = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _call() async {
    setState(() => _calling = true);
    try {
      final response = await _requestVerificationOptions(widget.sentence);
      if (!mounted) {
        return;
      }
      _showResponse(response);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError('$error');
    } finally {
      if (mounted) {
        setState(() => _calling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini 응답')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionLabel('입력'),
            const SizedBox(height: 8),
            Text(widget.sentence),
            const SizedBox(height: 24),
            const SectionLabel('모델'),
            const SizedBox(height: 8),
            const Text(GeminiService.modelName),
            const SizedBox(height: 24),
            TextField(
              controller: _responseController,
              minLines: 8,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(hintText: '응답'),
            ),
            if (_formatError != null) ...[
              const SizedBox(height: 12),
              Text(_formatError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_options.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionLabel('인증 방법'),
              for (var index = 0; index < _options.length; index++)
                _VerificationOptionTile(
                  option: _options[index],
                  selected: _selectedIndex == index,
                  onSelected: () => _selectOption(index),
                ),
            ],
            const SizedBox(height: 12),
            AppButton(
              label: '호출하기',
              onPressed: _calling ? null : _call,
            ),
          ],
        ),
      ),
    );
  }

  void _showResponse(String response) {
    ParsedVerificationOptions? parsed;
    String? formatError;
    try {
      parsed = parseVerificationOptions(response);
    } on FormatException catch (error) {
      formatError = error.message;
    }
    setState(() {
      _responseController.text = response;
      _options = parsed?.options ?? const [];
      _startAt = parsed?.startAt;
      _endAt = parsed?.endAt;
      _formatError = formatError;
      _selectedIndex = null;
    });
  }

  void _showError(String message) {
    setState(() {
      _responseController.text = message;
      _options = const [];
      _startAt = null;
      _endAt = null;
      _formatError = null;
      _selectedIndex = null;
    });
  }

  Future<void> _selectOption(int index) async {
    setState(() => _selectedIndex = index);
    final registered = await Navigator.of(context).push<RegisteredGoal>(
      MaterialPageRoute<RegisteredGoal>(
        builder: (context) => GoalRegisterScreen(
          sentence: widget.sentence,
          option: _options[index],
          responseJson: _options[index].json,
          startAt: _startAt!,
          endAt: _endAt!,
        ),
      ),
    );
    if (!mounted || registered == null) {
      return;
    }
    Navigator.of(context).pop(registered);
  }
}

class _VerificationOptionTile extends StatelessWidget {
  const _VerificationOptionTile({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final VerificationOption option;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: 0.2) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? scheme.primary : Colors.transparent),
        ),
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (option.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(option.description),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<String> _requestVerificationOptions(String sentence) async {
  final apiKey = await loadGeminiApiKey();
  if (apiKey == null) {
    throw StateError('GEMINI_API_KEY가 없습니다');
  }
  final response = await GeminiService(apiKey: apiKey).generate(
    '${GeminiPrompts.verificationOptions}${localIso8601(DateTime.now())}\n문장:\n$sentence',
  );
  return response ?? '';
}
