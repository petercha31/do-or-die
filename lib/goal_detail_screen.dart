import 'package:flutter/material.dart';

import 'widgets/section_label.dart';

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({
    super.key,
    required this.text,
    required this.verification,
  });

  final String text;
  final String verification;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상세')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionLabel('목표'),
            const SizedBox(height: 8),
            Text(text),
            if (verification.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionLabel('인증 방법'),
              const SizedBox(height: 8),
              Text(verification),
            ],
          ],
        ),
      ),
    );
  }
}
