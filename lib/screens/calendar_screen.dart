import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_task_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _svc = TaskService();
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  List<Task> _tasksForDay(List<Task> all, DateTime day) => all.where((t) {
    final d = t.deadline;
    return d.year == day.year && d.month == day.month && d.day == day.day;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const AddTaskSheet()),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white, child: const Icon(Icons.add_rounded),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _svc.stream(),
        builder: (context, snap) {
          final all = snap.data ?? [];
          final selectedTasks = _tasksForDay(all, _selected);

          return Column(children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
              child: TableCalendar<Task>(
                firstDay: DateTime(2024), lastDay: DateTime(2026, 12, 31),
                focusedDay: _focused,
                selectedDayPredicate: (d) => isSameDay(d, _selected),
                eventLoader: (d) => _tasksForDay(all, d),
                onDaySelected: (s, f) => setState(() { _selected = s; _focused = f; }),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), shape: BoxShape.circle),
                  todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  markerDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
              ),
            ),

            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
              Text(DateFormat('d MMMM yyyy').format(_selected), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${selectedTasks.length} task${selectedTasks.length == 1 ? '' : 's'}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12))),
            ])),
            const SizedBox(height: 10),

            Expanded(child: selectedTasks.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.event_available_outlined, size: 52, color: AppColors.primary.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  const Text('No tasks on this day', style: TextStyle(color: AppColors.textSecondary)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: selectedTasks.length,
                  itemBuilder: (_, i) {
                    final t = selectedTasks[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
                      child: Row(children: [
                        GestureDetector(onTap: () => _svc.toggle(t), child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: t.isDone ? AppColors.success : Colors.transparent, border: Border.all(color: t.isDone ? AppColors.success : Colors.grey.shade300, width: 2)), child: t.isDone ? const Icon(Icons.check, color: Colors.white, size: 13) : null)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, decoration: t.isDone ? TextDecoration.lineThrough : null, color: t.isDone ? AppColors.textSecondary : AppColors.textPrimary)),
                          Text(DateFormat('hh:mm a').format(t.deadline), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: [AppColors.success, AppColors.accent, AppColors.danger][t.priority].withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Text(t.priorityLabel, style: TextStyle(color: [AppColors.success, AppColors.accent, AppColors.danger][t.priority], fontSize: 11, fontWeight: FontWeight.w700))),
                      ]),
                    );
                  },
                )),
          ]);
        },
      ),
    );
  }
}
