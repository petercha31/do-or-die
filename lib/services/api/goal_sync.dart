import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../goals/goal_store.dart';
import 'api_base_url.dart';
import 'sync_log.dart';
import 'sync_settings.dart';

class GoalSyncService {
  GoalSyncService._();

  /// Set to false in widget tests so `.env` does not clear the in-memory DB.
  static bool allowSync = true;

  static Future<void> syncIfSignedIn() async {
    if (!allowSync || !await serverSyncEnabled()) {
      return;
    }
    final base = await apiBaseUrl();
    if (base == null) {
      return;
    }
    if (!await AuthApi.instance.hasToken()) {
      return;
    }
    final token = await TokenManagerProvider.instance.manager.getToken();
    final access = token?.accessToken;
    if (access == null || access.isEmpty) {
      return;
    }
    try {
      await _fetchAndReplace(base: base, accessToken: access);
    } catch (error, stackTrace) {
      logSyncError('syncIfSignedIn POST goals/list', error, stackTrace);
      rethrow;
    }
  }

  /// 수동으로 서버 목표를 가져올 때. `ENABLE_SERVER_SYNC`는 보지 않는다.
  static Future<void> fetchGoalsNow() async {
    final base = await apiBaseUrl();
    if (base == null) {
      throw StateError('.env에 API_BASE_URL을 설정하세요');
    }
    if (!await AuthApi.instance.hasToken()) {
      throw StateError('프로필에서 카카오로 로그인하세요');
    }
    final token = await TokenManagerProvider.instance.manager.getToken();
    final access = token?.accessToken;
    if (access == null || access.isEmpty) {
      throw StateError('액세스 토큰이 없습니다');
    }
    try {
      await _fetchAndReplace(base: base, accessToken: access);
    } catch (error, stackTrace) {
      logSyncError('fetchGoalsNow POST goals/list', error, stackTrace);
      rethrow;
    }
  }

  static Future<void> _fetchAndReplace({
    required Uri base,
    required String accessToken,
  }) async {
    final uri = base.resolve('goals/list/');
    if (kDebugMode) {
      logSyncDebug('POST $uri');
    }
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      final payload = jsonEncode({'accessToken': accessToken});
      final bodyBytes = Uint8List.fromList(utf8.encode(payload));
      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('${response.statusCode}: $body', uri: uri);
      }
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final list = decoded['goals'];
      if (list is! List<dynamic>) {
        throw FormatException('goals', body);
      }
      final rows = <GoalServerRow>[];
      for (final item in list) {
        if (item is! Map) {
          continue;
        }
        rows.add(GoalServerRow.fromJson(Map<String, dynamic>.from(item)));
      }
      await GoalStore.instance.replaceWithServerGoals(rows);
    } finally {
      client.close();
    }
  }
}
