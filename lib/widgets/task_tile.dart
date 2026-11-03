import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

/// A beautifully styled task row item supporting completion toggles,
/// edit navigation, and swipe-to-delete with animated aesthetics.
class TaskTile extends StatelessWidget {
  final Task task;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onTap,
    required this.onDismissed,
  });

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return const Color(0xFFEF4444); // Vibrant Rose / Red
      case Priority.medium:
        return const Color(0xFFF59E0B); // Amber / Warm Orange
      case Priority.low:
        return const Color(0xFF10B981); // Emerald / Teal
    }
  }

  bool get _isDueToday {
    if (task.dueDate == null) return false;
    final now = DateTime.now();
    return task.dueDate!.year == now.year &&
        task.dueDate!.month == now.month &&
        task.dueDate!.day == now.day;
  }

  bool get _isOverdue {
    if (task.dueDate == null || task.isDone) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    return due.isBefore(today);
  }

  String _formatDueDate(DateTime date) {
    if (_isDueToday) return 'Today';
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = task.isDone;
    final priorityColor = _getPriorityColor(task.priority);

    final cardBg = isDone
        ? (isDark ? const Color(0xFF172033) : const Color(0xFFF1F5F9))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    final borderColor = isDone
        ? Colors.transparent
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Dismissible(
        key: ValueKey('task_${task.id}'),
        direction: DismissDirection.endToStart,
        background: const SizedBox.shrink(),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF87171), Color(0xFFEF4444)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_outline, color: Colors.white, size: 22),
            ],
          ),
        ),
        onDismissed: (_) => onDismissed(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isDone
                ? []
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority Indicator Pill Bar on the left
                    Container(
                      width: 4,
                      height: 48,
                      margin: const EdgeInsets.only(top: 2, right: 6),
                      decoration: BoxDecoration(
                        color: isDone
                            ? priorityColor.withValues(alpha: 0.3)
                            : priorityColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    // Custom Checkbox
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Transform.scale(
                        scale: 1.05,
                        child: Checkbox(
                          value: isDone,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          activeColor: isDark
                              ? const Color(0xFF6366F1)
                              : theme.colorScheme.primary,
                          onChanged: (val) {
                            if (val != null) onToggleDone(val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Content Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: isDone
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                              decorationThickness: 2,
                              color: isDone
                                  ? (isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400)
                                  : (isDark
                                        ? const Color(0xFFF1F5F9)
                                        : const Color(0xFF0F172A)),
                            ),
                          ),

                          // Optional Description
                          if (task.description != null &&
                              task.description!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.description!.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: isDone
                                    ? (isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400)
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : const Color(0xFF64748B)),
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Badges Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Priority Tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(
                                    alpha: isDark ? 0.2 : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: priorityColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      task.priority.displayName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: priorityColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Due Date Tag
                              if (task.dueDate != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isOverdue
                                        ? const Color(0xFFFEE2E2)
                                        : _isDueToday
                                        ? const Color(0xFFEDE9FE)
                                        : (isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isOverdue
                                            ? Icons.error_outline_rounded
                                            : _isDueToday
                                            ? Icons.star_rounded
                                            : Icons.calendar_today_rounded,
                                        size: 12,
                                        color: _isOverdue
                                            ? const Color(0xFFDC2626)
                                            : _isDueToday
                                            ? const Color(0xFF7C3AED)
                                            : (isDark
                                                  ? Colors.grey.shade300
                                                  : const Color(0xFF475569)),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isOverdue
                                            ? 'Overdue (${_formatDueDate(task.dueDate!)})'
                                            : _formatDueDate(task.dueDate!),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _isOverdue
                                              ? const Color(0xFFDC2626)
                                              : _isDueToday
                                              ? const Color(0xFF7C3AED)
                                              : (isDark
                                                    ? Colors.grey.shade300
                                                    : const Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quick Edit Button
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade400,
                      tooltip: 'Edit task',
                      onPressed: onTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
