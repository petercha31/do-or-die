import 'package:flutter/material.dart';

import 'goal_detail_screen.dart';
import 'goal_time_label.dart';
import 'services/goals/goal_store.dart';
import 'widgets/section_label.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate = widget.initialDate;
  var _goals = const <StoredGoal>[];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await GoalStore.instance.listChronological();
      if (!mounted) {
        return;
      }
      setState(() => _goals = goals);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _goals = const []);
    }
  }

  Future<void> _openGoal(StoredGoal goal) async {
    await openGoalDetail(context, goal);
    if (!mounted) {
      return;
    }
    await _loadGoals();
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(MaterialLocalizations.of(context).formatFullDate(_selectedDate)),
            ),
            Expanded(
              flex: 3,
              child: CalendarDatePicker(
                initialDate: widget.initialDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100, 12, 31),
                currentDate: widget.initialDate,
                onDateChanged: _selectDate,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: SectionLabel('등록'),
            ),
            Expanded(
              flex: 2,
              child: _RegisteredGoalList(
                goals: goalsOnDate(_goals, _selectedDate),
                onOpen: _openGoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisteredGoalList extends StatelessWidget {
  const _RegisteredGoalList({required this.goals, required this.onOpen});

  final List<StoredGoal> goals;
  final ValueChanged<StoredGoal> onOpen;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const Center(
        child: Text(
          '이 날짜에 등록된 목표가 없습니다',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      itemCount: goals.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final goal = goals[index];
        return _RegisteredGoalTile(
          goal: goal,
          onTap: () => onOpen(goal),
        );
      },
    );
  }
}

class _RegisteredGoalTile extends StatelessWidget {
  const _RegisteredGoalTile({required this.goal, required this.onTap});

  final StoredGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tileTimeLabel(context, goal),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(goal.text),
            ],
          ),
        ),
      ),
    );
  }
}

String _tileTimeLabel(BuildContext context, StoredGoal goal) {
  final start = goal.startAt;
  final end = goal.endAt;
  if (start == null || end == null) {
    return goalTimeLabel(context, goal.createdAt);
  }
  return goalWindowLabel(context, start, end);
}
