import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/task.dart';
import 'package:flutter_application_1/widgets/task_tile.dart';
import 'package:flutter_application_1/screens/task_form_screen.dart';

void main() {
  group('TaskTile Widget Tests', () {
    testWidgets('renders active task details correctly', (
      WidgetTester tester,
    ) async {
      final task = Task(
        id: 1,
        title: 'Active Task',
        description: 'Important details',
        priority: Priority.high,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        isDone: false,
      );

      bool toggled = false;
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              task: task,
              onToggleDone: (val) => toggled = val,
              onTap: () => tapped = true,
              onDismissed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Active Task'), findsOneWidget);
      expect(find.text('Important details'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      // Verify not strikethrough
      final textWidget = tester.widget<Text>(find.text('Active Task'));
      expect(textWidget.style?.decoration, TextDecoration.none);

      // Tap Checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(toggled, isTrue);

      // Tap Tile
      await tester.tap(find.text('Active Task'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders completed task with strikethrough text', (
      WidgetTester tester,
    ) async {
      final task = Task(
        id: 2,
        title: 'Completed Task',
        priority: Priority.low,
        isDone: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskTile(
              task: task,
              onToggleDone: (_) {},
              onTap: () {},
              onDismissed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Completed Task'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Completed Task'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });
  });

  group('TaskFormScreen Widget Tests', () {
    testWidgets('Validates that title is required', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TaskFormScreen()));

      // Title field is present
      expect(find.text('Task Title *'), findsOneWidget);
      expect(find.text('New Task'), findsOneWidget);

      // Tap Save button without entering title
      await tester.tap(find.byTooltip('Save Task'));
      await tester.pumpAndSettle();

      // Should show validation error message
      expect(find.text('Title cannot be empty'), findsOneWidget);
    });

    testWidgets('Pre-populates fields when editing an existing task', (
      WidgetTester tester,
    ) async {
      final existingTask = Task(
        id: 10,
        title: 'Existing Title',
        description: 'Existing Description',
        priority: Priority.high,
      );

      await tester.pumpWidget(
        MaterialApp(home: TaskFormScreen(task: existingTask)),
      );

      expect(find.text('Edit Task'), findsOneWidget);
      expect(find.text('Existing Title'), findsOneWidget);
      expect(find.text('Existing Description'), findsOneWidget);
      expect(find.text('Update Task'), findsOneWidget);
    });
  });
}
