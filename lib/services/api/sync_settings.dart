import '../env_file.dart';

Future<bool> serverSyncEnabled() async {
  final raw = await loadEnvValue('ENABLE_SERVER_SYNC');
  if (raw == null) {
    return false;
  }
  switch (raw.trim().toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
      return true;
    default:
      return false;
  }
}
