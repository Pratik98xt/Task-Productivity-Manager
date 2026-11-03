import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';
import 'task_form_screen.dart';

/// Main screen featuring a progress dashboard header, filter tabs,
/// instant search bar, task statistics, and smooth swipe actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _dbHelper.getAllTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load tasks: $e';
          _isLoading = false;
        });
      }
    }
  }

  int get _activeCount => _tasks.where((t) => !t.isDone).length;
  int get _completedCount => _tasks.where((t) => t.isDone).length;
  int get _overdueCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      if (t.isDone || t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return due.isBefore(today);
    }).length;
  }

  double get _completionRatio =>
      _tasks.isEmpty ? 0.0 : (_completedCount / _tasks.length);

  List<Task> get _filteredTasks {
    List<Task> list = _tasks;

    // Filter by Tab (0: All, 1: Active, 2: Completed)
    if (_tabController.index == 1) {
      list = list.where((t) => !t.isDone).toList();
    } else if (_tabController.index == 2) {
      list = list.where((t) => t.isDone).toList();
    }

    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return list;
  }

  Future<void> _toggleTaskDone(Task task, bool isDone) async {
    final updated = task.copyWith(isDone: isDone);
    try {
      await _dbHelper.updateTask(updated);
      await _loadTasks();
    } catch (e) {
      _showErrorSnackBar('Failed to update task: $e');
    }
  }

  Future<void> _navigateToCreateTask() async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (context) => const TaskFormScreen()),
    );

    if (result != null) {
      try {
        await _dbHelper.insertTask(result);
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${result.title}" created'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar('Failed to save task: $e');
      }
    }
  }

  Future<void> _navigateToEditTask(Task task) async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (context) => TaskFormScreen(task: task)),
    );

    if (result != null) {
      try {
        await _dbHelper.updateTask(result);
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${result.title}" updated'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar('Failed to update task: $e');
      }
    }
  }

  Future<void> _deleteTaskWithUndo(Task task) async {
    final taskId = task.id;
    if (taskId == null) return;

    try {
      await _dbHelper.deleteTask(taskId);
      await _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${task.title}"'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Theme.of(context).colorScheme.primaryContainer,
              onPressed: () async {
                try {
                  await _dbHelper.insertTask(task);
                  await _loadTasks();
                } catch (e) {
                  _showErrorSnackBar('Failed to restore task: $e');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete task: $e');
    }
  }

  Future<void> _confirmClearCompleted() async {
    if (_completedCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Completed Tasks?'),
        content: Text(
          'Are you sure you want to delete all $_completedCount completed task(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final count = await _dbHelper.deleteCompleted();
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cleared $count completed task(s)'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar('Failed to clear completed tasks: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final bool isSearching = _searchQuery.isNotEmpty;
    final int tabIndex = _tabController.index;

    IconData icon;
    String title;
    String subtitle;

    if (isSearching) {
      icon = Icons.search_off_rounded;
      title = 'No tasks found';
      subtitle = 'No tasks match "$_searchQuery". Try another keyword.';
    } else if (tabIndex == 1) {
      icon = Icons.check_circle_outline_rounded;
      title = 'No active tasks';
      subtitle = 'Everything is completed! Relax or add new goals.';
    } else if (tabIndex == 2) {
      icon = Icons.hourglass_empty_rounded;
      title = 'No completed tasks';
      subtitle = 'Mark completed tasks with the checkbox to view them here.';
    } else {
      icon = Icons.checklist_rtl_rounded;
      title = 'No tasks yet';
      subtitle = 'Tap the "New Task" button below to plan your day.';
    }

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                    theme.colorScheme.secondary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearching && tabIndex == 0) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add your first task'),
                onPressed: _navigateToCreateTask,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, MMMM d').format(now);
    final percent = (_completionRatio * 100).toInt();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF334155)]
              : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF4F46E5)).withValues(
              alpha: 0.25,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateString,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              if (_overdueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_overdueCount Overdue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Main Header Text
          const Text(
            'Keep Moving Forward',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _completionRatio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF34D399), // Emerald accent
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Counter Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_activeCount active, $_completedCount completed',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$percent% done',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'To-Do List',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        actions: [
          // Clear completed button with confirmation
          if (_completedCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear completed',
              onPressed: _confirmClearCompleted,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: isDark ? Colors.white : theme.colorScheme.primary,
              unselectedLabelColor: isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'All (${_tasks.length})'),
                Tab(text: 'Active ($_activeCount)'),
                Tab(text: 'Completed ($_completedCount)'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Dashboard Card with Progress
          _buildDashboardCard(theme, isDark),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search tasks by title...',
              leading: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
              ],
              elevation: const WidgetStatePropertyAll(0),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              backgroundColor: WidgetStatePropertyAll(
                isDark ? const Color(0xFF1E293B) : Colors.white,
              ),
            ),
          ),

          // Filter feedback label
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} result${filtered.length == 1 ? '' : 's'} matching "$_searchQuery"',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 4),

          // Main Task List Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: theme.colorScheme.error,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: _loadTasks,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : filtered.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 4, bottom: 84),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final task = filtered[index];
                        return TaskTile(
                          task: task,
                          onToggleDone: (done) => _toggleTaskDone(task, done),
                          onTap: () => _navigateToEditTask(task),
                          onDismissed: () => _deleteTaskWithUndo(task),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateTask,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
