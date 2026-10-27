import 'dart:async';

import 'package:flutter/material.dart';

import 'calendar_screen.dart';
import 'gemini_response_screen.dart';
import 'goal_detail_screen.dart';
import 'goal_time_label.dart';
import 'goal_register_screen.dart';
import 'services/goals/goal_store.dart';
import 'services/notifications/goal_reminders.dart';
import 'widgets/app_button.dart';
import 'widgets/section_label.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _inputFocus = FocusNode();
  final _goals = <StoredGoal>[];
  Future<void> _goalActions = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _queueGoalAction(_loadGoals);
  }

  @override
  void dispose() {
    _inputFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _queueGoalAction(Future<void> Function() action) {
    _goalActions = _goalActions.then((_) => action()).catchError((Object _) {});
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await GoalStore.instance.list();
      if (!mounted) {
        return;
      }
      setState(() {
        _goals
          ..clear()
          ..addAll(goals);
      });
    } catch (_) {
      _showMessage('목표를 불러오지 못했습니다');
    }
  }

  void _openCalendar() {
    final today = DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CalendarScreen(
          initialDate: DateTime(today.year, today.month, today.day),
        ),
      ),
    );
  }

  Future<void> _openResponseScreen() async {
    final registered = await Navigator.of(context).push<RegisteredGoal>(
      MaterialPageRoute<RegisteredGoal>(
        builder: (context) => GeminiResponseScreen(sentence: _controller.text.trim()),
      ),
    );
    if (!mounted || registered == null) {
      return;
    }
    _queueGoalAction(
      () => _saveGoal(
        registered.text,
        registered.verificationTitle,
        registered.responseJson,
        startAt: registered.startAt,
        endAt: registered.endAt,
      ),
    );
  }

  Future<void> _saveGoal(
    String text,
    String verification,
    String responseJson, {
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    late final StoredGoal goal;
    try {
      goal = await GoalStore.instance.insert(
        text: text,
        verification: verification,
        responseJson: responseJson,
        startAt: startAt,
        endAt: endAt,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _goals.insert(0, goal);
        _controller.clear();
      });
      _inputFocus.unfocus();
    } catch (_) {
      _showMessage('목표를 저장하지 못했습니다');
      return;
    }
    try {
      await GoalReminders.instance.scheduleStart(
        id: goal.id,
        text: text,
        startAt: startAt,
      );
    } catch (_) {
      _showMessage('시작 알림을 예약하지 못했습니다');
    }
  }

  Future<void> _openGoal(StoredGoal goal) async {
    await openGoalDetail(context, goal);
    if (!mounted) {
      return;
    }
    _queueGoalAction(_loadGoals);
  }

  Future<void> _clearGoals() async {
    try {
      await GoalStore.instance.deleteAll();
      if (!mounted) {
        return;
      }
      setState(_goals.clear);
    } catch (_) {
      _showMessage('목표를 지우지 못했습니다');
      return;
    }
    try {
      await GoalReminders.instance.cancelAll();
    } catch (_) {
      _showMessage('시작 알림을 취소하지 못했습니다');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final expanded = _inputFocus.hasFocus;
    final today = DateTime.now().day;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(day: today, onCalendarTap: _openCalendar),
              const SizedBox(height: 32),
              Row(
                children: [
                  const SectionLabel('목록'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _queueGoalAction(_clearGoals),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text('전체 지우기'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: _GoalList(goals: _goals, onTap: _openGoal)),
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.bottomCenter,
                child: TextField(
                  controller: _controller,
                  focusNode: _inputFocus,
                  minLines: expanded ? 5 : 1,
                  maxLines: expanded ? 8 : 1,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '해야 할 일을 입력',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: '응답 화면',
                onPressed: _openResponseScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.day, required this.onCalendarTap});

  final int day;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _DateBox(day: day, onTap: onCalendarTap),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To Do',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                  children: [
                    const TextSpan(text: 'or '),
                    TextSpan(text: 'DIE', style: TextStyle(color: scheme.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const _ProfileMark(),
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.day, required this.onTap});

  final int day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: '캘린더',
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 72,
            child: Column(
              children: [
                Container(height: 16, color: scheme.primary),
                Expanded(
                  child: Center(
                    child: Text(
                      '$day',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMark extends StatelessWidget {
  const _ProfileMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: const Icon(Icons.person_outline, size: 36),
    );
  }
}

class _GoalList extends StatefulWidget {
  const _GoalList({required this.goals, required this.onTap});

  final List<StoredGoal> goals;
  final ValueChanged<StoredGoal> onTap;

  @override
  State<_GoalList> createState() => _GoalListState();
}

class _GoalListState extends State<_GoalList> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _GoalList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    final ticking = widget.goals.any((goal) => goal.startAt != null);
    if (!ticking) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final goals = widget.goals;
    if (goals.isEmpty) {
      return const Align(
        alignment: Alignment.topLeft,
        child: Text(
          '아직 목표가 없습니다',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.separated(
      itemCount: goals.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final goal = goals[index];
        return _GoalLine(
          text: goal.text,
          remaining: goal.startAt == null ? null : remainingMinutesSeconds(goal.startAt!, _now),
          onTap: () => widget.onTap(goal),
        );
      },
    );
  }
}

class _GoalLine extends StatelessWidget {
  const _GoalLine({required this.text, required this.remaining, required this.onTap});

  final String text;
  final String? remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (remaining != null) ...[
              const SizedBox(width: 12),
              Text(
                remaining!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
