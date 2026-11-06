import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'api_key.dart';

void _initKakaoSdk(String apiKey) {
  KakaoSdk.init(nativeAppKey: apiKey, loggingEnabled: kDebugMode);
}

class KakaoAccount {
  const KakaoAccount({required this.id, this.nickname, this.email});

  final int id;
  final String? nickname;
  final String? email;
}

Future<void> prepareKakaoSdk() async {
  final apiKey = await loadKakaoNativeAppKey();
  if (apiKey == null) {
    if (kDebugMode) {
      debugPrint('[kakao] .env에 KAKAO_NATIVE_APP_KEY가 없어 로그인을 쓸 수 없습니다');
    }
    return;
  }
  _initKakaoSdk(apiKey);
}

Future<KakaoAccount?> signedInKakaoAccount() async {
  final apiKey = await loadKakaoNativeAppKey();
  if (apiKey == null) {
    return null;
  }
  _initKakaoSdk(apiKey);
  try {
    if (!await AuthApi.instance.hasToken()) {
      return null;
    }
    await UserApi.instance.accessTokenInfo();
    return await _readAccount();
  } catch (_) {
    return null;
  }
}

/// SDK에 저장된 카카오 액세스 토큰. 없으면 null.
Future<String?> kakaoAccessToken() async {
  final apiKey = await loadKakaoNativeAppKey();
  if (apiKey == null) {
    return null;
  }
  _initKakaoSdk(apiKey);
  if (!await AuthApi.instance.hasToken()) {
    return null;
  }
  final token = await TokenManagerProvider.instance.manager.getToken();
  final access = token?.accessToken.trim();
  if (access == null || access.isEmpty) {
    return null;
  }
  return access;
}

Future<KakaoAccount?> signInWithKakao() async {
  final apiKey = await loadKakaoNativeAppKey();
  if (apiKey == null) {
    throw StateError('KAKAO_NATIVE_APP_KEY가 없습니다');
  }
  _initKakaoSdk(apiKey);
  final signedIn = await _requestSignIn();
  if (!signedIn) {
    return null;
  }
  return _readAccount();
}

Future<void> signOutKakao() async {
  final apiKey = await loadKakaoNativeAppKey();
  if (apiKey == null) {
    throw StateError('KAKAO_NATIVE_APP_KEY가 없습니다');
  }
  _initKakaoSdk(apiKey);
  try {
    await UserApi.instance.logout();
  } catch (_) {
    if (await AuthApi.instance.hasToken()) {
      rethrow;
    }
  }
}

const _kakaoTalkLoginTimeout = Duration(seconds: 45);

Future<bool> _requestSignIn() async {
  if (await isKakaoTalkInstalled()) {
    try {
      await UserApi.instance.loginWithKakaoTalk().timeout(
        _kakaoTalkLoginTimeout,
      );
      return true;
    } on TimeoutException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[kakao] loginWithKakaoTalk 시간 초과 — 웹(카카오계정) 로그인으로 넘어갑니다: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    } on PlatformException catch (error) {
      if (error.code == 'CANCELED') {
        return false;
      }
      if (kDebugMode) {
        debugPrint(
          '[kakao] loginWithKakaoTalk PlatformException ${error.code}: ${error.message}',
        );
      }
      rethrow;
    } on KakaoClientException catch (error) {
      if (error.reason == ClientErrorCause.cancelled) {
        return false;
      }
      rethrow;
    }
  }
  try {
    await UserApi.instance.loginWithKakaoAccount();
    return true;
  } on PlatformException catch (error) {
    if (error.code == 'CANCELED') {
      return false;
    }
    rethrow;
  } on KakaoClientException catch (error) {
    if (error.reason == ClientErrorCause.cancelled) {
      return false;
    }
    rethrow;
  }
}

Future<KakaoAccount> _readAccount() async {
  final user = await UserApi.instance.me();
  final account = user.kakaoAccount;
  return KakaoAccount(
    id: user.id,
    nickname: _text(account?.profile?.nickname),
    email: _text(account?.email),
  );
}

String? _text(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}
