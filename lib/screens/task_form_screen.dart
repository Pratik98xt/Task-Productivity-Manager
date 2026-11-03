import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

/// Screen for creating a new task or editing an existing one with modern aesthetics.
class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late Priority _selectedPriority;
  DateTime? _selectedDueDate;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedPriority = widget.task?.priority ?? Priority.medium;
    _selectedDueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDueDate ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  void _setPresetDate(int daysFromNow) {
    final now = DateTime.now();
    setState(() {
      _selectedDueDate = DateTime(now.year, now.month, now.day + daysFromNow);
    });
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final trimmedTitle = _titleController.text.trim();
    final trimmedDescription = _descriptionController.text.trim();

    final task = Task(
      id: widget.task?.id,
      title: trimmedTitle,
      description: trimmedDescription.isEmpty ? null : trimmedDescription,
      priority: _selectedPriority,
      dueDate: _selectedDueDate,
      isDone: widget.task?.isDone ?? false,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.check, size: 20),
              tooltip: 'Save Task',
              onPressed: _submit,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_task_rounded,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? 'Update Task Info'
                                : 'Create a New Task',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEditing
                                ? 'Adjust title, priorities, or dates'
                                : 'Keep your day organized and on schedule',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title Field
              Text(
                'Task Title *',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'e.g., Review project proposal',
                  prefixIcon: const Icon(Icons.task_alt_rounded),
                  suffixIcon: _titleController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _titleController.clear();
                            });
                          },
                        )
                      : null,
                ),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title cannot be empty';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description Field
              Text(
                'Description (optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Add notes, checklist items, or links...',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 24),

              // Priority Selector
              Text(
                'Priority Level',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildPriorityChip(
                    priority: Priority.low,
                    label: 'Low',
                    color: const Color(0xFF10B981),
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                    priority: Priority.medium,
                    label: 'Medium',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.flag_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                    priority: Priority.high,
                    label: 'High',
                    color: const Color(0xFFEF4444),
                    icon: Icons.flag_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Due Date Selector
              Text(
                'Due Date',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              // Preset Quick-Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.today_rounded, size: 16),
                      label: const Text('Today'),
                      onPressed: () => _setPresetDate(0),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                      label: const Text('Tomorrow'),
                      onPressed: () => _setPresetDate(1),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.calendar_view_week, size: 16),
                      label: const Text('In 1 Week'),
                      onPressed: () => _setPresetDate(7),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Due Date Display Container
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    _selectedDueDate == null
                        ? 'No due date chosen'
                        : DateFormat(
                            'EEEE, MMM d, yyyy',
                          ).format(_selectedDueDate!),
                    style: TextStyle(
                      fontWeight: _selectedDueDate == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: _selectedDueDate == null
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedDueDate != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: 'Clear due date',
                          onPressed: _clearDueDate,
                        ),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                        label: Text(
                          _selectedDueDate == null ? 'Set' : 'Change',
                        ),
                        onPressed: _pickDueDate,
                      ),
                    ],
                  ),
                  onTap: _pickDueDate,
                ),
              ),

              const SizedBox(height: 36),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isEditing ? 'Update Task' : 'Create Task',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip({
    required Priority priority,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedPriority == priority;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPriority = priority;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? color
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
