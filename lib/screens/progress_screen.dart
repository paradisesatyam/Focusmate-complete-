import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/focus_session.dart';
import '../models/task_model.dart';
import '../services/focus_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusSvc = FocusService();
    final taskSvc = TaskService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Progress', style: TextStyle(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Focus Sessions ─────────────────────────────────────
          StreamBuilder<List<FocusSession>>(
            stream: focusSvc.stream(),
            builder: (context, snap) {
              final sessions = snap.data ?? [];
              final now = DateTime.now();
              final totalMins = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
              final todayMins = sessions.where((s) => _isToday(s.date)).fold<int>(0, (sum, s) => sum + s.durationMinutes);

              // Last 7 days bar data
              final last7 = List.generate(7, (i) {
                final day = now.subtract(Duration(days: 6 - i));
                final mins = sessions.where((s) => _isSameDay(s.date, day)).fold<int>(0, (sum, s) => sum + s.durationMinutes);
                return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: mins.toDouble(), color: AppColors.primary, width: 18, borderRadius: BorderRadius.circular(6))]);
              });

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Focus Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(children: [
                  _StatCard('Today', '$todayMins min', AppColors.primary, Icons.today_outlined),
                  const SizedBox(width: 12),
                  _StatCard('Total', '$totalMins min', AppColors.success, Icons.timer_outlined),
                ]),
                const SizedBox(height: 20),
                _ChartCard(title: 'Focus Minutes — Last 7 Days', child: BarChart(BarChartData(
                  barGroups: last7,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                      final d = now.subtract(Duration(days: 6 - v.toInt()));
                      return Padding(padding: const EdgeInsets.only(top: 6), child: Text(DateFormat('E').format(d), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)));
                    })),
                  ),
                ))),
              ]);
            },
          ),

          const SizedBox(height: 28),

          // ── Task Completion ────────────────────────────────────
          StreamBuilder<List<Task>>(
            stream: taskSvc.stream(),
            builder: (context, snap) {
              final tasks = snap.data ?? [];
              final done = tasks.where((t) => t.isDone).length;
              final pending = tasks.where((t) => !t.isDone).length;
              final total = tasks.length;

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Task Completion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(children: [
                  _StatCard('Done', '$done tasks', AppColors.success, Icons.check_circle_outline),
                  const SizedBox(width: 12),
                  _StatCard('Pending', '$pending tasks', AppColors.accent, Icons.pending_outlined),
                ]),
                const SizedBox(height: 20),
                if (total > 0) _ChartCard(title: 'Tasks Overview', child: PieChart(PieChartData(
                  sectionsSpace: 3, centerSpaceRadius: 50,
                  sections: [
                    if (done > 0) PieChartSectionData(value: done.toDouble(), color: AppColors.success, title: 'Done\n$done', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12), radius: 70),
                    if (pending > 0) PieChartSectionData(value: pending.toDouble(), color: AppColors.accent, title: 'Pending\n$pending', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12), radius: 70),
                  ],
                )))
                else Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('No tasks yet', style: TextStyle(color: AppColors.textSecondary)))),
              ]);
            },
          ),
        ]),
      ),
    );
  }

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _StatCard extends StatelessWidget {
  final String label, value; final Color color; final IconData icon;
  const _StatCard(this.label, this.value, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color))])])));
}

class _ChartCard extends StatelessWidget {
  final String title; final Widget child;
  const _ChartCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)), const SizedBox(height: 16), SizedBox(height: 180, child: child)]));
}
