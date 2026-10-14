import 'package:flutter/material.dart';

import 'widgets/app_button.dart';
import 'youtube_blocker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _Goal {
  _Goal(this.text);

  final String text;
  bool achieved = false;
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
                    const SizedBox(height: 12),
                    const Text(
                      '해야 할 일을 한 문장으로 남기고, 해내면 달성으로 체크하세요.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addGoal(),
                      decoration: const InputDecoration(
                        hintText: '해야 할 일을 입력',
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
                      achieved: goal.achieved,
                      onAchieved: (achieved) {
                        setState(() => goal.achieved = achieved);
                      },
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

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.text,
    required this.achieved,
    required this.onAchieved,
  });

  final String text;
  final bool achieved;
  final ValueChanged<bool> onAchieved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Checkbox(
            value: achieved,
            onChanged: (value) => onAchieved(value ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
              child: Text(
                text,
                style: TextStyle(
                  color: achieved ? Colors.white38 : Colors.white,
                  decoration: achieved ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
