import 'package:flutter/material.dart';

import 'services/gemini/verification_options.dart';
import 'widgets/app_button.dart';
import 'widgets/section_label.dart';

class RegisteredGoal {
  const RegisteredGoal({required this.text, required this.verificationTitle});

  final String text;
  final String verificationTitle;
}

class GoalRegisterScreen extends StatelessWidget {
  const GoalRegisterScreen({
    super.key,
    required this.sentence,
    required this.option,
  });

  final String sentence;
  final VerificationOption option;

  void _register(BuildContext context) {
    Navigator.of(context).pop(
      RegisteredGoal(text: sentence, verificationTitle: option.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('등록')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionLabel('목표'),
            const SizedBox(height: 8),
            Text(sentence),
            const SizedBox(height: 24),
            const SectionLabel('인증 방법'),
            const SizedBox(height: 8),
            Text(option.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (option.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(option.description),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: '등록',
              onPressed: () => _register(context),
            ),
          ],
        ),
      ),
    );
  }
}
