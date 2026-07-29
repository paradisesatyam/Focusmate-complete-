import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});
  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final _svc = AlarmService();
  Timer? _webTimer;
  List<Alarm> _alarms = [];

  @override
  void initState() {
    super.initState();
    // On web, check every 30 seconds if any active alarm matches current time
    if (kIsWeb) {
      _webTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkWebAlarms());
    }
  }

  @override
  void dispose() { _webTimer?.cancel(); super.dispose(); }

  void _checkWebAlarms() {
    final now = DateTime.now();
    for (final alarm in _alarms) {
      if (!alarm.isActive) continue;
      if (alarm.hour == now.hour && alarm.minute == now.minute) {
        _showWebAlarmDialog(alarm);
      }
    }
  }

  void _showWebAlarmDialog(Alarm alarm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⏰', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(alarm.timeLabel, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(alarm.label, style: const TextStyle(fontSize: 18, color: AppColors.textPrimary)),
        ]),
        actions: [
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
            )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Alarms', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => _AddAlarmSheet(svc: _svc),
        ),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Add Alarm', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<Alarm>>(
        stream: _svc.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          _alarms = snap.data ?? [];
          if (_alarms.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('⏰', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 14),
              const Text('No alarms set', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Tap + Add Alarm to create one', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _alarms.length,
            itemBuilder: (_, i) => _AlarmTile(alarm: _alarms[i], svc: _svc),
          );
        },
      ),
    );
  }
}

// ─── Alarm Tile ───────────────────────────────────────────────────────
class _AlarmTile extends StatelessWidget {
  final Alarm alarm;
  final AlarmService svc;
  const _AlarmTile({required this.alarm, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete alarm?'),
          content: Text('Delete "${alarm.label}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white), onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
          ],
        ),
      ),
      onDismissed: (_) => svc.delete(alarm.id),
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: alarm.isActive ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              alarm.timeLabel,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: alarm.isActive ? AppColors.textPrimary : AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(alarm.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: alarm.isActive ? AppColors.textPrimary : AppColors.textSecondary)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.repeat_rounded, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(alarm.repeatLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ])),
          Switch(value: alarm.isActive, onChanged: (_) => svc.toggle(alarm), activeColor: AppColors.primary),
        ]),
      ),
    );
  }
}

// ─── Add Alarm Sheet ──────────────────────────────────────────────────
class _AddAlarmSheet extends StatefulWidget {
  final AlarmService svc;
  const _AddAlarmSheet({required this.svc});
  @override
  State<_AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<_AddAlarmSheet> {
  final _labelCtrl = TextEditingController();
  int _hour = 7, _minute = 0;
  final Set<int> _days = {};
  bool _saving = false;

  @override
  void dispose() { _labelCtrl.dispose(); super.dispose(); }

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
    if (_labelCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a label for your alarm.')));
      return;
    }
    setState(() => _saving = true);
    await widget.svc.add(Alarm(
      id: '', label: _labelCtrl.text.trim(),
      hour: _hour, minute: _minute,
      isActive: true, repeatDays: _days.toList()..sort(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          const Text('Add Alarm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 24),

          // Time picker
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: Text(_timeLabel, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),

          // Label
          const Text('Label', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _labelCtrl, textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: 'e.g. Wake up, Morning workout', hintStyle: const TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.background, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5))),
          ),
          const SizedBox(height: 20),

          // Repeat days
          const Text('Repeat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) {
            final day = i + 1;
            final sel = _days.contains(day);
            return GestureDetector(
              onTap: () => setState(() => sel ? _days.remove(day) : _days.add(day)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade200, width: sel ? 2 : 1),
                ),
                alignment: Alignment.center,
                child: Text(dayNames[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppColors.textSecondary)),
              ),
            );
          })),
          const SizedBox(height: 6),
          Text(_days.isEmpty ? 'One-time alarm' : 'Repeats on selected days', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 28),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Set Alarm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            )),
        ]),
      ),
    );
  }
}
