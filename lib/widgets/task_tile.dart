import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final TaskService svc;
  const TaskTile({super.key, required this.task, required this.svc});

  Color get _pc => [AppColors.success, AppColors.accent, AppColors.danger][task.priority];
  bool get _ov => !task.isDone && task.deadline.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await showDialog<bool>(context: context, builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white), onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      )),
      onDismissed: (_) => svc.delete(task.id),
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: task.isDone ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ov ? AppColors.danger.withOpacity(0.35) : Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          GestureDetector(onTap: () => svc.toggle(task), child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24, height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, color: task.isDone ? AppColors.success : Colors.transparent, border: Border.all(color: task.isDone ? AppColors.success : Colors.grey.shade300, width: 2)),
            child: task.isDone ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
          )),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: task.isDone ? AppColors.textSecondary : AppColors.textPrimary, decoration: task.isDone ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 4),
            if (task.description != null) Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(task.description!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 12, color: _ov ? AppColors.danger : AppColors.textSecondary),
              const SizedBox(width: 3),
              Text(DateFormat('d MMM, hh:mm a').format(task.deadline), style: TextStyle(fontSize: 12, color: _ov ? AppColors.danger : AppColors.textSecondary, fontWeight: _ov ? FontWeight.w600 : FontWeight.normal)),
              if (_ov) const Text(' • Overdue', style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600)),
            ]),
          ])),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _pc.withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Text(task.priorityLabel, style: TextStyle(color: _pc, fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}
