import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'api_key.dart';

class KakaoAccount {
  const KakaoAccount({required this.id, this.nickname, this.email});

  final int id;
  final String? nickname;
  final String? email;
}

Future<void> prepareKakaoSdk() async {
  final apiKey = await loadKakaoNativeAppKey();
  if (apiKey == null) {
    return;
  }
  KakaoSdk.init(nativeAppKey: apiKey);
}

Future<KakaoAccount?> signedInKakaoAccount() async {
  final apiKey = await loadKakaoNativeAppKey();
  if (apiKey == null) {
    return null;
  }
  KakaoSdk.init(nativeAppKey: apiKey);
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

Future<KakaoAccount?> signInWithKakao() async {
  final apiKey = await loadKakaoNativeAppKey();
  if (apiKey == null) {
    throw StateError('KAKAO_NATIVE_APP_KEY가 없습니다');
  }
  KakaoSdk.init(nativeAppKey: apiKey);
  final signedIn = await _requestSignIn();
  if (!signedIn) {
    return null;
  }
  return _readAccount();
}

Future<bool> _requestSignIn() async {
  if (await isKakaoTalkInstalled()) {
    try {
      await UserApi.instance.loginWithKakaoTalk();
      return true;
    } on PlatformException catch (error) {
      if (error.code == 'CANCELED') {
        return false;
      }
    } on KakaoClientException catch (error) {
      if (error.reason == ClientErrorCause.cancelled) {
        return false;
      }
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
