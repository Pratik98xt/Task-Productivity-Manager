import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';

/// Database helper singleton to manage SQLite operations for tasks.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Retrieve the SQLite database instance, initializing if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL,
        due_date TEXT,
        is_done INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Insert a new task into the database. Returns the task with its generated ID.
  Future<Task> insertTask(Task task) async {
    final db = await database;
    final id = await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return task.copyWith(id: id);
  }

  /// Fetch all tasks ordered by completion status, priority/due date, and creation time.
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      orderBy: 'is_done ASC, created_at DESC',
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  /// Update an existing task.
  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Delete a task by ID.
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all tasks that are marked as completed.
  Future<int> deleteCompleted() async {
    final db = await database;
    return await db.delete('tasks', where: 'is_done = ?', whereArgs: [1]);
  }

  /// Close the database connection.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
