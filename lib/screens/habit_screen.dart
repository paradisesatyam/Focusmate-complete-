import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';
import '../theme/app_theme.dart';

class HabitScreen extends StatelessWidget {
  const HabitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = HabitService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Habits', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AddHabitSheet(svc: svc),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<Habit>>(
        stream: svc.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final habits = snap.data ?? [];

          // Today stats
          final done = habits.where((h) => h.isDoneToday).length;
          final total = habits.length;

          if (habits.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🌟', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 14),
              const Text('No habits yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Tap + Add Habit to build your daily routine', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]));
          }

          return Column(children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('Today\'s Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const Spacer(),
                    Text('$done/$total', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: total > 0 ? done / total : 0,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    done == total && total > 0 ? '🎉 All habits done today!' : '$done of $total habits completed',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ]),
              ),
            ),

            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: habits.length,
              itemBuilder: (_, i) => _HabitTile(habit: habits[i], svc: svc),
            )),
          ]);
        },
      ),
    );
  }
}

// ─── Habit Tile ───────────────────────────────────────────────────────
class _HabitTile extends StatelessWidget {
  final Habit habit;
  final HabitService svc;
  const _HabitTile({required this.habit, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete habit?'),
          content: Text('Delete "${habit.title}"? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) => svc.delete(habit.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: habit.isDoneToday ? AppColors.success.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: habit.isDoneToday ? AppColors.success.withOpacity(0.3) : Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Icon circle
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: habit.isDoneToday ? AppColors.success.withOpacity(0.12) : AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(habit.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              habit.title,
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: habit.isDoneToday ? AppColors.textSecondary : AppColors.textPrimary,
                decoration: habit.isDoneToday ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.notifications_outlined, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 3),
              Text(habit.timeLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ])),

          // Active toggle
          Switch(
            value: habit.isActive,
            onChanged: (_) => svc.toggleActive(habit),
            activeColor: AppColors.primary,
          ),

          // Done checkbox
          GestureDetector(
            onTap: habit.isDoneToday ? null : () => svc.markDone(habit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: habit.isDoneToday ? AppColors.success : Colors.transparent,
                border: Border.all(color: habit.isDoneToday ? AppColors.success : Colors.grey.shade300, width: 2),
              ),
              child: habit.isDoneToday ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Add Habit Sheet ──────────────────────────────────────────────────
class _AddHabitSheet extends StatefulWidget {
  final HabitService svc;
  const _AddHabitSheet({required this.svc});
  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _titleCtrl = TextEditingController();
  String _icon = '⭐';
  int _hour = 8, _minute = 0;
  bool _saving = false;

  @override
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _hour, minute: _minute));
    if (t != null) setState(() { _hour = t.hour; _minute = t.minute; });
  }

  String get _timeLabel {
    final suffix = _hour >= 12 ? 'PM' : 'AM';
    final h = _hour > 12 ? _hour - 12 : (_hour == 0 ? 12 : _hour);
    final m = _minute.toString().padLeft(2, '0');
    return '$h:$m $suffix';
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a habit name.')));
      return;
    }
    setState(() => _saving = true);
    await widget.svc.add(Habit(
      id: '', title: _titleCtrl.text.trim(), icon: _icon,
      reminderHour: _hour, reminderMinute: _minute, isActive: true,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          const Text('Add Daily Habit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 24),

          // Icon picker
          const Text('Choose Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          SizedBox(height: 52, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: kHabitIcons.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => _icon = kHabitIcons[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _icon == kHabitIcons[i] ? AppColors.primary.withOpacity(0.12) : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _icon == kHabitIcons[i] ? AppColors.primary : Colors.grey.shade200, width: _icon == kHabitIcons[i] ? 2 : 1),
                ),
                alignment: Alignment.center,
                child: Text(kHabitIcons[i], style: const TextStyle(fontSize: 22)),
              ),
            ),
          )),
          const SizedBox(height: 20),

          // Title
          const Text('Habit Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl, autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: 'e.g. Drink 8 glasses of water', hintStyle: const TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.background, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5))),
          ),
          const SizedBox(height: 20),

          // Reminder time
          const Text('Daily Reminder Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                const Icon(Icons.access_alarm_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(_timeLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Add Habit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            )),
        ]),
      ),
    );
  }
}
