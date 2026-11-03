import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('Task initializes with default values', () {
      final task = Task(title: 'Test Task');
      expect(task.title, 'Test Task');
      expect(task.description, isNull);
      expect(task.priority, Priority.medium);
      expect(task.dueDate, isNull);
      expect(task.isDone, isFalse);
      expect(task.id, isNull);
      expect(task.createdAt, isNotNull);
    });

    test('Task copyWith works correctly', () {
      final task = Task(title: 'Original Title', priority: Priority.low);
      final updated = task.copyWith(
        title: 'New Title',
        priority: Priority.high,
        isDone: true,
      );

      expect(updated.title, 'New Title');
      expect(updated.priority, Priority.high);
      expect(updated.isDone, isTrue);
      expect(updated.createdAt, task.createdAt);
    });

    test('Task serialization toMap and fromMap roundtrip', () {
      final dueDate = DateTime(2026, 12, 31, 10, 0);
      final createdAt = DateTime(2026, 1, 1, 8, 30);
      final task = Task(
        id: 42,
        title: 'Complete project',
        description: 'Detailed instructions',
        priority: Priority.high,
        dueDate: dueDate,
        isDone: true,
        createdAt: createdAt,
      );

      final map = task.toMap();
      expect(map['id'], 42);
      expect(map['title'], 'Complete project');
      expect(map['description'], 'Detailed instructions');
      expect(map['priority'], 'High');
      expect(map['due_date'], dueDate.toIso8601String());
      expect(map['is_done'], 1);
      expect(map['created_at'], createdAt.toIso8601String());

      final restored = Task.fromMap(map);
      expect(restored.id, 42);
      expect(restored.title, 'Complete project');
      expect(restored.description, 'Detailed instructions');
      expect(restored.priority, Priority.high);
      expect(restored.dueDate, dueDate);
      expect(restored.isDone, isTrue);
      expect(restored.createdAt, createdAt);
    });

    test('Priority parsing handles values correctly', () {
      expect(Priority.fromString('Low'), Priority.low);
      expect(Priority.fromString('medium'), Priority.medium);
      expect(Priority.fromString('HIGH'), Priority.high);
      expect(Priority.fromString(null), Priority.low);
      expect(Priority.fromString('unknown'), Priority.low);
    });
  });
}
