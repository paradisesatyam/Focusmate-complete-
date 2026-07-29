import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_tile.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with SingleTickerProviderStateMixin {
  final _svc = TaskService();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    NotificationService().scheduleDailyCheckIn();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('To-Do Planner', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(controller: _tabs, indicatorColor: AppColors.primary, labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'All'), Tab(text: 'Pending'), Tab(text: 'Done')]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const AddTaskSheet()),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded), label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _svc.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: AppColors.danger)));
          final all = snap.data ?? [];
          final pending = all.where((t) => !t.isDone).toList();
          final done = all.where((t) => t.isDone).toList();
          return TabBarView(controller: _tabs, children: [
            _TaskList(tasks: all, all: all, svc: _svc),
            _TaskList(tasks: pending, all: all, svc: _svc),
            _TaskList(tasks: done, all: all, svc: _svc),
          ]);
        },
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks, all;
  final TaskService svc;
  const _TaskList({required this.tasks, required this.all, required this.svc});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.checklist_rtl, size: 64, color: AppColors.primary.withOpacity(0.2)),
        const SizedBox(height: 14),
        const Text('No tasks here yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        const Text('Tap + Add Task to get started', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]));
    }
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Row(children: [
        _Chip('${all.where((t) => !t.isDone).length} pending', AppColors.accent),
        const SizedBox(width: 8),
        _Chip('${all.where((t) => t.isDone).length} done', AppColors.success),
      ])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), itemCount: tasks.length, itemBuilder: (_, i) => TaskTile(task: tasks[i], svc: svc))),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label; final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)));
}
