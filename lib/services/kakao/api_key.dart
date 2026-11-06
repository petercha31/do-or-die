import '../env_file.dart';

Future<String?> loadKakaoNativeAppKey() {
  return loadEnvValue('KAKAO_NATIVE_APP_KEY');
}
