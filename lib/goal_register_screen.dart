import 'package:flutter/material.dart';

import 'goal_time_label.dart';
import 'services/gemini/verification_options.dart';
import 'services/goals/registration_schedule.dart';
import 'widgets/app_button.dart';
import 'widgets/section_label.dart';

class RegisteredGoal {
  const RegisteredGoal({
    required this.text,
    required this.verificationTitle,
    required this.responseJson,
    required this.startAt,
    required this.endAt,
  });

  final String text;
  final String verificationTitle;
  final String responseJson;
  final DateTime startAt;
  final DateTime endAt;
}

class GoalRegisterScreen extends StatelessWidget {
  const GoalRegisterScreen({
    super.key,
    required this.sentence,
    required this.option,
    required this.responseJson,
    required this.startAt,
    required this.endAt,
  });

  final String sentence;
  final VerificationOption option;
  final String responseJson;
  final DateTime startAt;
  final DateTime endAt;

  GoalSchedule _scheduleAt(DateTime registeredAt) {
    return scheduleAtRegistration(
      sentence: sentence,
      startAt: startAt,
      endAt: endAt,
      registeredAt: registeredAt,
    );
  }

  void _register(BuildContext context) {
    final schedule = _scheduleAt(DateTime.now());
    Navigator.of(context).pop(
      RegisteredGoal(
        text: sentence,
        verificationTitle: option.title,
        responseJson: responseJson,
        startAt: schedule.startAt,
        endAt: schedule.endAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _scheduleAt(DateTime.now());

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
            const SectionLabel('시작시각'),
            const SizedBox(height: 8),
            Text(goalTimeLabel(context, schedule.startAt)),
            const SizedBox(height: 24),
            const SectionLabel('종료시각'),
            const SizedBox(height: 8),
            Text(goalTimeLabel(context, schedule.endAt)),
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
