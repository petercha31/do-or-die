import '../env_file.dart';

/// Base URL for the Django server, trailing slash optional.
/// Set `API_BASE_URL` in `.env` (required for sync), e.g. `http://192.168.0.10:8000` on a real device.
Future<Uri?> apiBaseUrl() async {
  final fromEnv = await loadEnvValue('API_BASE_URL');
  if (fromEnv == null || fromEnv.trim().isEmpty) {
    return null;
  }
  final trimmed = fromEnv.trim();
  return Uri.parse(trimmed.endsWith('/') ? trimmed : '$trimmed/');
}
