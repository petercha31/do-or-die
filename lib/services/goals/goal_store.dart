import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const goalDatabaseFile = 'goals.db';

class StoredGoal {
  const StoredGoal({
    required this.id,
    required this.text,
    required this.verification,
    required this.responseJson,
    required this.createdAt,
    this.startAt,
    this.endAt,
    this.verdict = '',
    this.verdictReason = '',
    this.verifiedAt,
  });

  final int id;
  final String text;
  final String verification;
  final String responseJson;
  final DateTime createdAt;
  final DateTime? startAt;
  final DateTime? endAt;
  final String verdict;
  final String verdictReason;
  final DateTime? verifiedAt;

  StoredGoal withVerdict({
    required String verdict,
    required String verdictReason,
    required DateTime verifiedAt,
  }) {
    return StoredGoal(
      id: id,
      text: text,
      verification: verification,
      responseJson: responseJson,
      createdAt: createdAt,
      startAt: startAt,
      endAt: endAt,
      verdict: verdict,
      verdictReason: verdictReason,
      verifiedAt: verifiedAt,
    );
  }
}

class GoalStore {
  GoalStore._();

  static final instance = GoalStore._();
  static String path = goalDatabaseFile;

  Future<Database>? _opening;

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening == null) {
      return;
    }
    final database = await opening;
    await database.close();
  }

  void dropConnection() {
    final opening = _opening;
    _opening = null;
    opening?.then((database) => database.close());
  }

  Future<StoredGoal> insert({
    required String text,
    required String verification,
    required String responseJson,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final database = await _database();
    final createdAt = DateTime.now();
    final id = await database.insert('goals', {
      'text': text,
      'verification': verification,
      'response_json': responseJson,
      'created_at': createdAt.millisecondsSinceEpoch,
      'start_at': startAt?.millisecondsSinceEpoch,
      'end_at': endAt?.millisecondsSinceEpoch,
    });
    return StoredGoal(
      id: id,
      text: text,
      verification: verification,
      responseJson: responseJson,
      createdAt: createdAt,
      startAt: startAt,
      endAt: endAt,
    );
  }

  Future<void> saveVerdict({
    required int id,
    required String verdict,
    required String verdictReason,
    required DateTime verifiedAt,
  }) async {
    final database = await _database();
    await database.update(
      'goals',
      {
        'verdict': verdict,
        'verdict_reason': verdictReason,
        'verified_at': verifiedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    final database = await _database();
    await database.delete('goals');
  }

  Future<List<StoredGoal>> list() {
    return _list(orderBy: 'created_at DESC, id DESC');
  }

  Future<List<StoredGoal>> listChronological() {
    return _list(orderBy: 'COALESCE(start_at, created_at) ASC, id ASC');
  }

  Future<List<StoredGoal>> _list({required String orderBy}) async {
    final database = await _database();
    final rows = await database.query('goals', orderBy: orderBy);
    return [for (final row in rows) _storedGoal(row)];
  }

  Future<Database> _database() {
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    return openDatabase(
      await _databasePath(),
      version: 4,
      onCreate: _createGoals,
      onUpgrade: _upgradeGoals,
    );
  }

  Future<String> _databasePath() async {
    if (path == inMemoryDatabasePath) {
      return inMemoryDatabasePath;
    }
    final directory = await getDatabasesPath();
    return join(directory, path);
  }
}

Future<void> _createGoals(Database database, int version) {
  return database.execute('''
    CREATE TABLE goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      text TEXT NOT NULL,
      verification TEXT NOT NULL,
      response_json TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      start_at INTEGER,
      end_at INTEGER,
      verdict TEXT NOT NULL DEFAULT '',
      verdict_reason TEXT NOT NULL DEFAULT '',
      verified_at INTEGER
    )
  ''');
}

Future<void> _upgradeGoals(Database database, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await database.execute(
      "ALTER TABLE goals ADD COLUMN response_json TEXT NOT NULL DEFAULT ''",
    );
  }
  if (oldVersion < 3) {
    await database.execute('ALTER TABLE goals ADD COLUMN start_at INTEGER');
    await database.execute('ALTER TABLE goals ADD COLUMN end_at INTEGER');
  }
  if (oldVersion < 4) {
    await database.execute("ALTER TABLE goals ADD COLUMN verdict TEXT NOT NULL DEFAULT ''");
    await database.execute(
      "ALTER TABLE goals ADD COLUMN verdict_reason TEXT NOT NULL DEFAULT ''",
    );
    await database.execute('ALTER TABLE goals ADD COLUMN verified_at INTEGER');
  }
}

List<StoredGoal> goalsOnDate(List<StoredGoal> goals, DateTime date) {
  return [
    for (final goal in goals)
      if (_occursOn(goal, date)) goal,
  ];
}

bool _occursOn(StoredGoal goal, DateTime date) {
  final start = goal.startAt;
  final end = goal.endAt;
  if (start == null || end == null) {
    return _isSameDay(goal.createdAt, date);
  }
  final day = DateTime(date.year, date.month, date.day);
  final first = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  return !day.isBefore(first) && !day.isAfter(last);
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year && left.month == right.month && left.day == right.day;
}

StoredGoal _storedGoal(Map<String, Object?> row) {
  return StoredGoal(
    id: row['id']! as int,
    text: row['text']! as String,
    verification: row['verification']! as String,
    responseJson: row['response_json']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
    startAt: _dateTime(row['start_at']),
    endAt: _dateTime(row['end_at']),
    verdict: row['verdict'] as String? ?? '',
    verdictReason: row['verdict_reason'] as String? ?? '',
    verifiedAt: _dateTime(row['verified_at']),
  );
}

DateTime? _dateTime(Object? value) {
  if (value is! int) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(value);
}
