import 'package:flutter/material.dart';

import 'services/kakao/kakao_login.dart';
import 'widgets/app_button.dart';
import 'widgets/section_label.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  KakaoAccount? _account;
  var _signingIn = false;

  @override
  void initState() {
    super.initState();
    _loadSignedIn();
  }

  Future<void> _loadSignedIn() async {
    final account = await signedInKakaoAccount();
    if (!mounted || account == null) {
      return;
    }
    setState(() => _account = account);
  }

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    try {
      final account = await signInWithKakao();
      if (!mounted || account == null) {
        return;
      }
      setState(() => _account = account);
    } catch (error) {
      _showMessage('로그인하지 못했습니다: $error');
    } finally {
      if (mounted) {
        setState(() => _signingIn = false);
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_account == null) ...[
                const SectionLabel('계정'),
                const SizedBox(height: 8),
                const Text('카카오 계정으로 로그인합니다'),
              ] else
                _AccountInfo(account: _account!),
              const Spacer(),
              AppButton(
                label: _buttonLabel(
                  signedIn: _account != null,
                  signingIn: _signingIn,
                ),
                onPressed: _account != null || _signingIn ? null : _signIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountInfo extends StatelessWidget {
  const _AccountInfo({required this.account});

  final KakaoAccount account;

  @override
  Widget build(BuildContext context) {
    final nickname = account.nickname;
    final email = account.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('회원번호'),
        const SizedBox(height: 8),
        Text('${account.id}'),
        if (nickname != null) ...[
          const SizedBox(height: 24),
          const SectionLabel('닉네임'),
          const SizedBox(height: 8),
          Text(nickname),
        ],
        if (email != null) ...[
          const SizedBox(height: 24),
          const SectionLabel('이메일'),
          const SizedBox(height: 8),
          Text(email),
        ],
      ],
    );
  }
}

String _buttonLabel({required bool signedIn, required bool signingIn}) {
  if (signedIn) {
    return '로그인됨';
  }
  if (signingIn) {
    return '로그인 중';
  }
  return '카카오로 로그인';
}
