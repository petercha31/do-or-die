import 'package:flutter/services.dart';

class YoutubeBlocker {
  // constructor
  const YoutubeBlocker();

  static const _channel = MethodChannel('do_or_die/app_block');

  Future<String> start() async {
    final result = await _channel.invokeMethod<String>('startYoutubeBlock');
    return result ?? 'unsupported';
  }

  Future<String> stop() async {
    final result = await _channel.invokeMethod<String>('stopYoutubeBlock');
    return result ?? 'unsupported';
  }
}
