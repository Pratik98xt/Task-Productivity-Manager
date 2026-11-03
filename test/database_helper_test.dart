import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_1/database/database_helper.dart';
import 'package:flutter_application_1/models/task.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tasks');
  });

  tearDown(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tasks');
  });

  group('DatabaseHelper CRUD Tests', () {
    test('Insert and retrieve tasks', () async {
      final helper = DatabaseHelper.instance;

      final task1 = Task(
        title: 'Task 1',
        description: 'First task description',
        priority: Priority.high,
      );
      final insertedTask = await helper.insertTask(task1);

      expect(insertedTask.id, isNotNull);

      final allTasks = await helper.getAllTasks();
      expect(allTasks.length, 1);
      expect(allTasks.first.title, 'Task 1');
      expect(allTasks.first.priority, Priority.high);
      expect(allTasks.first.isDone, isFalse);
    });

    test('Update task', () async {
      final helper = DatabaseHelper.instance;

      final task = await helper.insertTask(Task(title: 'Original'));
      final updatedTask = task.copyWith(
        title: 'Updated Title',
        isDone: true,
        priority: Priority.low,
      );

      final rowsAffected = await helper.updateTask(updatedTask);
      expect(rowsAffected, 1);

      final allTasks = await helper.getAllTasks();
      expect(allTasks.first.title, 'Updated Title');
      expect(allTasks.first.isDone, isTrue);
      expect(allTasks.first.priority, Priority.low);
    });

    test('Delete single task', () async {
      final helper = DatabaseHelper.instance;

      final task1 = await helper.insertTask(Task(title: 'To keep'));
      final task2 = await helper.insertTask(Task(title: 'To delete'));

      await helper.deleteTask(task2.id!);

      final allTasks = await helper.getAllTasks();
      expect(allTasks.length, 1);
      expect(allTasks.first.id, task1.id);
    });

    test('Delete completed tasks', () async {
      final helper = DatabaseHelper.instance;

      await helper.insertTask(Task(title: 'Active 1', isDone: false));
      await helper.insertTask(Task(title: 'Done 1', isDone: true));
      await helper.insertTask(Task(title: 'Done 2', isDone: true));

      final deletedCount = await helper.deleteCompleted();
      expect(deletedCount, 2);

      final remaining = await helper.getAllTasks();
      expect(remaining.length, 1);
      expect(remaining.first.title, 'Active 1');
    });
  });
}
