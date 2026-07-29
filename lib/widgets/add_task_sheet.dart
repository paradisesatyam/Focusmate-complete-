import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _svc = TaskService();
  DateTime _deadline = DateTime.now().add(const Duration(hours: 1));
  int _priority = 1;
  bool _saving = false;
  String? _error;

  @override
  void dispose() { _title.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _pickDeadline() async {
    final d = await showDatePicker(context: context, initialDate: _deadline, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_deadline));
    if (t == null || !mounted) return;
    setState(() => _deadline = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) { setState(() => _error = 'Please enter a task title.'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      await _svc.add(Task(id: '', title: _title.text.trim(), description: _desc.text.trim().isEmpty ? null : _desc.text.trim(), deadline: _deadline, isDone: false, priority: _priority, createdAt: DateTime.now()));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Failed to save. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.success, AppColors.accent, AppColors.danger];
    final labels = ['Low', 'Medium', 'High'];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          const Text('Add New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 24),

          _lbl('Task Title'), const SizedBox(height: 8),
          TextField(controller: _title, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: _deco('e.g. Complete assignment')),
          const SizedBox(height: 16),

          _lbl('Description (optional)'), const SizedBox(height: 8),
          TextField(controller: _desc, maxLines: 2, decoration: _deco('Add details...')),
          const SizedBox(height: 20),

          _lbl('Deadline'), const SizedBox(height: 8),
          GestureDetector(onTap: _pickDeadline, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Text(DateFormat('EEE, d MMM yyyy  •  hh:mm a').format(_deadline), style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
            ]),
          )),
          const SizedBox(height: 20),

          _lbl('Priority'), const SizedBox(height: 10),
          Row(children: List.generate(3, (i) {
            final sel = _priority == i;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _priority = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: sel ? colors[i].withOpacity(0.14) : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? colors[i] : Colors.grey.shade200, width: sel ? 1.5 : 1),
                ),
                alignment: Alignment.center,
                child: Text(labels[i], style: TextStyle(color: sel ? colors[i] : AppColors.textSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
              ),
            ));
          })),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withOpacity(0.3))),
              child: Row(children: [const Icon(Icons.error_outline, color: AppColors.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)))])),
          ],

          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Save Task', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            )),
        ])),
      ),
    );
  }

  Widget _lbl(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary));
  InputDecoration _deco(String h) => InputDecoration(hintText: h, hintStyle: const TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.background, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)));
}
