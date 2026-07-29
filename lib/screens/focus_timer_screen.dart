import 'dart:async';
import 'package:flutter/material.dart';
import '../services/focus_service.dart';
import '../theme/app_theme.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});
  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  final _svc = FocusService();
  final _durations = [15, 25, 30, 45, 60];
  int _selectedMinutes = 25;
  late int _secondsLeft;
  Timer? _timer;
  bool _running = false, _done = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _selectedMinutes * 60;
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _start() {
    setState(() { _running = true; _done = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() { _running = false; _done = true; _secondsLeft = 0; });
        _onComplete();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _pause() { _timer?.cancel(); setState(() => _running = false); }

  void _reset() {
    _timer?.cancel();
    setState(() { _running = false; _done = false; _secondsLeft = _selectedMinutes * 60; });
  }

  Future<void> _onComplete() async {
    await _svc.save(_selectedMinutes);
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('🎉 Session Complete!'),
      content: Text('Great work! You focused for $_selectedMinutes minutes.\nSession saved to your progress.'),
      actions: [TextButton(onPressed: () { Navigator.pop(context); _reset(); }, child: const Text('Start Another'))],
    ));
  }

  String get _timeStr {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => 1 - (_secondsLeft / (_selectedMinutes * 60));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Focus Timer', style: TextStyle(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Duration selector
          if (!_running && !_done) ...[
            const Text('Select Duration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: _durations.map((m) {
              final sel = m == _selectedMinutes;
              return GestureDetector(
                onTap: () => setState(() { _selectedMinutes = m; _secondsLeft = m * 60; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: sel ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade200)),
                  child: Text('${m}m', style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              );
            }).toList()),
            const SizedBox(height: 32),
          ] else const SizedBox(height: 32),

          // Circular timer
          SizedBox(height: 260, width: 260, child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(child: CircularProgressIndicator(
              value: _progress, strokeWidth: 10, backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_done ? AppColors.success : AppColors.primary),
            )),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_timeStr, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFeatures: [FontFeature.tabularFigures()])),
              const SizedBox(height: 4),
              Text(_done ? 'Complete! 🎉' : _running ? 'Stay Focused' : 'Ready', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ]),
          ])),

          const SizedBox(height: 40),

          // Controls
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Reset
            IconButton(onPressed: _reset, icon: const Icon(Icons.refresh_rounded), iconSize: 32, color: AppColors.textSecondary,
              style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(14))),
            const SizedBox(width: 20),
            // Start / Pause
            GestureDetector(
              onTap: _running ? _pause : (_done ? _reset : _start),
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]),
                child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
              ),
            ),
          ]),

          const SizedBox(height: 40),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('Each completed session is saved to your Progress dashboard automatically.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            ]),
          ),
        ]),
      ),
    );
  }
}
