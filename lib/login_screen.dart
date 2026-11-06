import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'services/api/goal_sync.dart';
import 'services/api/sync_log.dart';
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
  String? _accessToken;
  var _signingIn = false;
  var _signingOut = false;

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
    final token = await kakaoAccessToken();
    try {
      await GoalSyncService.syncIfSignedIn();
    } catch (error, stackTrace) {
      logSyncError('_loadSignedIn syncIfSignedIn', error, stackTrace);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _account = account;
      _accessToken = token;
    });
  }

  Future<void> _signIn() async {
    if (kDebugMode) {
      debugPrint('[login] 카카오 로그인 버튼 탭');
    }
    setState(() => _signingIn = true);
    try {
      final account = await signInWithKakao();
      if (!mounted) {
        return;
      }
      if (account == null) {
        _showMessage('로그인을 취소했습니다');
        return;
      }
      try {
        await GoalSyncService.syncIfSignedIn();
      } catch (error, stackTrace) {
        logSyncError('_signIn syncIfSignedIn', error, stackTrace);
        _showMessage('서버와 목표를 맞추지 못했습니다: $error');
      }
      final token = await kakaoAccessToken();
      if (!mounted) {
        return;
      }
      setState(() {
        _account = account;
        _accessToken = token;
      });
    } catch (error) {
      _showMessage('로그인하지 못했습니다: $error');
    } finally {
      if (mounted) {
        setState(() => _signingIn = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await signOutKakao();
      if (!mounted) {
        return;
      }
      setState(() {
        _account = null;
        _accessToken = null;
      });
    } catch (error) {
      _showMessage('로그아웃하지 못했습니다: $error');
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  VoidCallback? _buttonAction() {
    if (_signingIn || _signingOut) {
      return null;
    }
    if (_account != null) {
      return _signOut;
    }
    return _signIn;
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
      appBar: AppBar(title: Text(_account == null ? '로그인' : '내정보')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _account == null
                      ? const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionLabel('계정'),
                            SizedBox(height: 8),
                            Text('카카오 계정으로 로그인합니다'),
                          ],
                        )
                      : _AccountInfo(
                          account: _account!,
                          accessToken: _accessToken,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: _buttonLabel(
                  signedIn: _account != null,
                  signingIn: _signingIn,
                  signingOut: _signingOut,
                ),
                onPressed: _buttonAction(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountInfo extends StatelessWidget {
  const _AccountInfo({required this.account, this.accessToken});

  final KakaoAccount account;
  final String? accessToken;

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
        if (accessToken != null) ...[
          const SizedBox(height: 24),
          const SectionLabel('액세스 토큰'),
          const SizedBox(height: 8),
          SelectableText(accessToken!, style: const TextStyle(fontSize: 12)),
        ],
      ],
    );
  }
}

String _buttonLabel({
  required bool signedIn,
  required bool signingIn,
  required bool signingOut,
}) {
  if (signingOut) {
    return '로그아웃 중';
  }
  if (signedIn) {
    return '로그아웃';
  }
  if (signingIn) {
    return '로그인 중';
  }
  return '카카오로 로그인';
}
