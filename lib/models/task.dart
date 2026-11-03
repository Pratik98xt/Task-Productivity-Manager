enum Priority {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  static Priority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return Priority.high;
      case 'medium':
        return Priority.medium;
      case 'low':
      default:
        return Priority.low;
    }
  }
}

/// Task model representing a single to-do item.
class Task {
  final int? id;
  final String title;
  final String? description;
  final Priority priority;
  final DateTime? dueDate;
  final bool isDone;
  final DateTime createdAt;

  Task({
    this.id,
    required this.title,
    this.description,
    this.priority = Priority.medium,
    this.dueDate,
    this.isDone = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy of the task with updated fields.
  Task copyWith({
    int? id,
    String? title,
    String? description,
    Priority? priority,
    DateTime? dueDate,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert Task to a database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.displayName,
      'due_date': dueDate?.toIso8601String(),
      'is_done': isDone ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Construct Task from database map.
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: Priority.fromString(map['priority'] as String?),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'] as String)
          : null,
      isDone: (map['is_done'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
