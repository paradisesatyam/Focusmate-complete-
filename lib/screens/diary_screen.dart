import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import '../theme/app_theme.dart';

// ─── Diary List ──────────────────────────────────────────────────────
class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = DiaryService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Diary', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaryEntryScreen())),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined), label: const Text('New Entry', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<DiaryEntry>>(
        stream: svc.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          final entries = snap.data ?? [];
          if (entries.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.book_outlined, size: 64, color: AppColors.primary.withOpacity(0.2)),
            const SizedBox(height: 14),
            const Text('No diary entries yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Tap + New Entry to start writing', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              return Dismissible(
                key: Key(e.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async => await showDialog<bool>(context: context, builder: (c) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Delete entry?'), content: const Text('This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white), onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))])),
                onDismissed: (_) => svc.delete(e.id),
                background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiaryEntryScreen(existing: e))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(e.mood, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(DateFormat('EEE, d MMM yyyy').format(e.date), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                          Text(DateFormat('hh:mm a').format(e.date), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ])),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ]),
                      const SizedBox(height: 10),
                      Text(e.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Diary Entry Editor ───────────────────────────────────────────────
class DiaryEntryScreen extends StatefulWidget {
  final DiaryEntry? existing;
  const DiaryEntryScreen({super.key, this.existing});
  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  late TextEditingController _ctrl;
  final _svc = DiaryService();
  String _mood = '😊';
  bool _saving = false;

  final _moods = ['😊', '😄', '😌', '😔', '😤', '😴', '🤔', '🥳', '😢', '😍'];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existing?.content ?? '');
    _mood = widget.existing?.mood ?? '😊';
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write something before saving.')));
      return;
    }
    setState(() => _saving = true);
    await _svc.save(DiaryEntry(id: widget.existing?.id ?? '', content: _ctrl.text.trim(), mood: _mood, date: DateTime.now()));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Entry' : 'Edit Entry', style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16),
            child: TextButton(onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)))),
        ],
      ),
      body: Column(children: [
        // Mood selector
        Container(
          height: 56, color: AppColors.background,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _moods.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => _mood = _moods[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                width: 40, height: 40,
                decoration: BoxDecoration(color: _mood == _moods[i] ? AppColors.primary.withOpacity(0.15) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _mood == _moods[i] ? AppColors.primary : Colors.grey.shade200, width: _mood == _moods[i] ? 2 : 1)),
                alignment: Alignment.center,
                child: Text(_moods[i], style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ),
        Expanded(child: TextField(
          controller: _ctrl,
          maxLines: null, expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.7),
          decoration: const InputDecoration(
            hintText: 'Write your thoughts here...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            contentPadding: EdgeInsets.all(20),
            border: InputBorder.none,
          ),
        )),
      ]),
    );
  }
}
