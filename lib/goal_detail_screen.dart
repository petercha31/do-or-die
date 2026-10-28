import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'goal_time_label.dart';
import 'services/gemini/api_key.dart';
import 'services/gemini/gemini_service.dart';
import 'services/gemini/prompts.dart';
import 'services/gemini/verification_options.dart';
import 'services/goals/goal_store.dart';
import 'widgets/app_button.dart';
import 'widgets/section_label.dart';
import 'youtube_blocker.dart';

Future<void> openGoalDetail(BuildContext context, StoredGoal goal) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (context) => GoalDetailScreen(goal: goal)),
  );
}

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key, required this.goal});

  final StoredGoal goal;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late StoredGoal _goal = widget.goal;
  var _verifying = false;

  Future<void> _verify() async {
    final submittedAt = DateTime.now();
    final windowMessage = verificationWindowMessage(_goal, submittedAt);
    if (windowMessage != null) {
      _showMessage(windowMessage);
      return;
    }

    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (!mounted || photo == null) {
      return;
    }

    setState(() => _verifying = true);
    try {
      final image = await photo.readAsBytes();
      final verdict = await _requestVerdict(
        _goal,
        image,
        photo.mimeType ?? 'image/jpeg',
        submittedAt,
      );
      final verifiedAt = DateTime.now();
      await GoalStore.instance.saveVerdict(
        id: _goal.id,
        verdict: verdict.result,
        verdictReason: verdict.reason,
        verifiedAt: verifiedAt,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _goal = _goal.withVerdict(
          verdict: verdict.result,
          verdictReason: verdict.reason,
          verifiedAt: verifiedAt,
        );
      });
      if (verdict.result == 'pass') {
        await _stopControl();
      }
    } catch (error) {
      _showMessage('인증하지 못했습니다: $error');
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  Future<void> _stopControl() async {
    try {
      final result = await const YoutubeBlocker().stop();
      if (result == 'stopped') {
        _showMessage('인증을 통과해서 통제를 풀었습니다');
      }
    } catch (_) {
      _showMessage('인증은 통과했지만 통제를 풀지 못했습니다');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    final startAt = goal.startAt;
    final endAt = goal.endAt;
    final passed = goal.verdict == 'pass';

    return Scaffold(
      appBar: AppBar(title: const Text('상세')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionLabel('목표'),
            const SizedBox(height: 8),
            Text(goal.text),
            if (startAt != null && endAt != null) ...[
              const SizedBox(height: 24),
              const SectionLabel('시작시각'),
              const SizedBox(height: 8),
              Text(goalTimeLabel(context, startAt)),
              const SizedBox(height: 24),
              const SectionLabel('종료시각'),
              const SizedBox(height: 8),
              Text(goalTimeLabel(context, endAt)),
            ],
            if (goal.verification.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionLabel('인증 방법'),
              const SizedBox(height: 8),
              Text(goal.verification),
            ],
            if (goal.responseJson.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionLabel('JSON 응답'),
              const SizedBox(height: 8),
              _JsonResponse(responseJson: goal.responseJson),
            ],
            if (goal.verdict.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionLabel('판정'),
              const SizedBox(height: 8),
              _Verdict(goal: goal),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: _buttonLabel(passed: passed, verifying: _verifying),
              onPressed: passed || _verifying ? null : _verify,
            ),
          ],
        ),
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.goal});

  final StoredGoal goal;

  @override
  Widget build(BuildContext context) {
    final verifiedAt = goal.verifiedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _verdictLabel(goal.verdict),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (goal.verdictReason.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(goal.verdictReason),
        ],
        if (verifiedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            goalTimeLabel(context, verifiedAt),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _JsonResponse extends StatelessWidget {
  const _JsonResponse({required this.responseJson});

  final String responseJson;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          prettyJson(responseJson),
          softWrap: true,
          style: const TextStyle(fontFamily: 'monospace', height: 1.45),
        ),
      ),
    );
  }
}

/// 시작시각 앞뒤로 인증할 수 있는 시간. 폭을 바꿀 때는 이 값만 조정한다.
const verificationWindow = Duration(minutes: 5);

String? verificationWindowMessage(StoredGoal goal, DateTime now) {
  final startAt = goal.startAt;
  if (startAt == null) {
    return null;
  }
  final opensAt = startAt.subtract(verificationWindow);
  final closesAt = startAt.add(verificationWindow);
  if (now.isBefore(opensAt)) {
    return '아직 인증 시간이 아닙니다';
  }
  if (now.isAfter(closesAt)) {
    return '인증 가능 시간이 지났습니다';
  }
  return null;
}

enum VerificationIndicator {
  before,
  during,
  passed,
  failed;

  String get label {
    switch (this) {
      case VerificationIndicator.before:
        return '인증전';
      case VerificationIndicator.during:
        return '인증중';
      case VerificationIndicator.passed:
        return '인증완료';
      case VerificationIndicator.failed:
        return '인증실패';
    }
  }
}

/// 목록 점 색에 쓸 상태. 통과, 실패, 인증 전, 인증 가능 시간일 때 값이 있다.
VerificationIndicator? verificationIndicator(StoredGoal goal, DateTime now) {
  if (goal.verdict == 'pass') {
    return VerificationIndicator.passed;
  }
  if (goal.verdict == 'fail') {
    return VerificationIndicator.failed;
  }
  if (goal.verdict.isNotEmpty) {
    return null;
  }
  final startAt = goal.startAt;
  if (startAt == null) {
    return VerificationIndicator.before;
  }
  final opensAt = startAt.subtract(verificationWindow);
  final closesAt = startAt.add(verificationWindow);
  if (now.isBefore(opensAt)) {
    return VerificationIndicator.before;
  }
  if (now.isAfter(closesAt)) {
    return null;
  }
  return VerificationIndicator.during;
}

String _buttonLabel({required bool passed, required bool verifying}) {
  if (passed) {
    return '인증 완료';
  }
  if (verifying) {
    return '판정 중';
  }
  return '인증하기';
}

String _verdictLabel(String verdict) {
  switch (verdict) {
    case 'pass':
      return '통과';
    case 'fail':
      return '실패';
    default:
      return '판단 불가, 다시 찍어 주세요';
  }
}

Future<VerificationVerdict> _requestVerdict(
  StoredGoal goal,
  Uint8List image,
  String mimeType,
  DateTime submittedAt,
) async {
  final apiKey = await loadGeminiApiKey();
  if (apiKey == null) {
    throw StateError('GEMINI_API_KEY가 없습니다');
  }
  final response = await GeminiService(
    apiKey: apiKey,
  ).generateWithImage(_verdictPrompt(goal, submittedAt), image, mimeType);
  return parseVerificationVerdict(response ?? '');
}

String _verdictPrompt(StoredGoal goal, DateTime submittedAt) {
  final startAt = goal.startAt;
  final endAt = goal.endAt;
  final method = goal.responseJson.isNotEmpty
      ? goal.responseJson
      : goal.verification;
  return '${GeminiPrompts.verifyEvidence}'
      '목표: ${goal.text}\n'
      '인증 방법: $method\n'
      '시작시각: ${startAt == null ? '' : localIso8601(startAt)}\n'
      '종료시각: ${endAt == null ? '' : localIso8601(endAt)}\n'
      '제출시각: ${localIso8601(submittedAt)}\n';
}
