import 'package:flutter/material.dart';

import 'calendar_screen.dart';
import 'gemini_response_screen.dart';
import 'goal_detail_screen.dart';
import 'goal_register_screen.dart';
import 'widgets/app_button.dart';
import 'youtube_blocker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _Goal {
  _Goal(this.text, {this.verification = ''});

  final String text;
  final String verification;
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _goals = <_Goal>[];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startControl() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await const YoutubeBlocker().start();
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(_controlMessage(result))));
  }

  void _addGoal() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      _goals.insert(0, _Goal(text));
      _controller.clear();
    });
  }

  Future<void> _openResponseScreen() async {
    final registered = await Navigator.of(context).push<RegisteredGoal>(
      MaterialPageRoute<RegisteredGoal>(
        builder: (context) => GeminiResponseScreen(
          sentence: _controller.text.trim(),
        ),
      ),
    );
    if (!mounted || registered == null) {
      return;
    }
    _addRegisteredGoal(registered);
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

  void _openGoalDetail(_Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GoalDetailScreen(
          text: goal.text,
          verification: goal.verification,
        ),
      ),
    );
  }

  void _addRegisteredGoal(RegisteredGoal registered) {
    setState(() {
      _goals.insert(
        0,
        _Goal(registered.text, verification: registered.verificationTitle),
      );
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TO DO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'OR DIE',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _CalendarBox(onTap: _openCalendar),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '해야 할 일을 한 문장으로 남기고, 해내면 달성으로 체크하세요.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      minLines: 6,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: '해야 할 일을 입력',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: '등록',
                      onPressed: _controller.text.trim().isEmpty ? null : _addGoal,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: '통제 시작',
                      onPressed: _startControl,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: '응답 화면',
                      onPressed: _openResponseScreen,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '목표 ${_goals.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_goals.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    '아직 목표가 없습니다',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                sliver: SliverList.separated(
                  itemCount: _goals.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return _GoalTile(
                      text: goal.text,
                      verification: goal.verification,
                      onTap: () => _openGoalDetail(goal),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _controlMessage(String result) {
  switch (result) {
    case 'started':
      return '유튜브 앱 실행을 막았습니다';
    case 'need_accessibility':
      return '접근성 설정에서 유튜브 통제를 켜면 유튜브가 실행되지 않습니다';
    default:
      return '이 기기에서는 유튜브 실행을 막을 수 없습니다';
  }
}

class _CalendarBox extends StatelessWidget {
  const _CalendarBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: '캘린더',
      icon: const Text('📅', style: TextStyle(fontSize: 32)),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.text,
    required this.verification,
    required this.onTap,
  });

  final String text;
  final String verification;
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
              Text(text),
              if (verification.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  verification,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
