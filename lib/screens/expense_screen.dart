import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../theme/app_theme.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});
  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> with SingleTickerProviderStateMixin {
  final _svc = ExpenseService();
  late TabController _tabs;
  bool _showPie = true; // toggle pie / bar

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  void _addExpense() => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddExpenseSheet(svc: _svc));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expense Analytics', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(controller: _tabs, indicatorColor: AppColors.primary, labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary, tabs: const [Tab(text: 'Today'), Tab(text: 'This Month')]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense, backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded), label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _svc.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          final all = snap.data ?? [];
          final now = DateTime.now();

          final todayExp = all.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).toList();
          final monthExp = all.where((e) => e.date.year == now.year && e.date.month == now.month).toList();

          return TabBarView(controller: _tabs, children: [
            _ExpenseView(expenses: todayExp, svc: _svc, showPie: _showPie, onToggleChart: () => setState(() => _showPie = !_showPie), label: 'Today'),
            _ExpenseView(expenses: monthExp, svc: _svc, showPie: _showPie, onToggleChart: () => setState(() => _showPie = !_showPie), label: DateFormat('MMMM yyyy').format(now)),
          ]);
        },
      ),
    );
  }
}

// ─── Expense View (shared between Today and Month tabs) ───────────────
class _ExpenseView extends StatelessWidget {
  final List<Expense> expenses;
  final ExpenseService svc;
  final bool showPie;
  final VoidCallback onToggleChart;
  final String label;

  const _ExpenseView({required this.expenses, required this.svc, required this.showPie, required this.onToggleChart, required this.label});

  Map<String, double> get _byCategory {
    final Map<String, double> map = {};
    for (final e in expenses) map[e.category] = (map[e.category] ?? 0) + e.amount;
    return map;
  }

  double get _total => expenses.fold(0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    final byCategory = _byCategory;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Total card ───────────────────────────────────────────
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total ($label)', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text('₹${_total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
            Text('${expenses.length} expense${expenses.length == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 20),

        if (expenses.isEmpty) ...[
          Container(padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Center(child: Column(children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.primary.withOpacity(0.2)),
            const SizedBox(height: 12),
            const Text('No expenses yet', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('Tap + Add Expense to get started', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]))),
        ] else ...[

          // ── Chart toggle ─────────────────────────────────────
          Row(children: [
            const Text('Spending Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Spacer(),
            Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(onTap: () { if (!showPie) onToggleChart(); }, child: _ChartToggleBtn(icon: Icons.pie_chart_outline_rounded, active: showPie)),
                GestureDetector(onTap: () { if (showPie) onToggleChart(); }, child: _ChartToggleBtn(icon: Icons.bar_chart_rounded, active: !showPie)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),

          // ── Chart ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16), height: 240,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
            child: showPie ? _buildPie(byCategory) : _buildBar(byCategory),
          ),
          const SizedBox(height: 16),

          // ── Category legend ──────────────────────────────────
          ...byCategory.entries.toList().asMap().entries.map((entry) {
            final i = kCategories.indexOf(entry.value.key);
            final color = AppColors.categoryColors[i >= 0 ? i % AppColors.categoryColors.length : 0];
            final icon = i >= 0 ? kCategoryIcons[i] : '💰';
            return Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(icon, style: const TextStyle(fontSize: 18))),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.value.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary))),
                Text('₹${entry.value.value.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
              ]),
            );
          }),

          const SizedBox(height: 20),
          const Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          // ── Transaction list ─────────────────────────────────
          ...expenses.map((e) {
            final ci = kCategories.indexOf(e.category);
            final color = AppColors.categoryColors[ci >= 0 ? ci % AppColors.categoryColors.length : 0];
            final icon = ci >= 0 ? kCategoryIcons[ci] : '💰';
            return Dismissible(
              key: Key(e.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async => await showDialog<bool>(context: context, builder: (c) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Delete expense?'), content: Text('Delete "${e.title}"?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white), onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))])),
              onDismissed: (_) => svc.delete(e.id),
              background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                child: Row(children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(icon, style: const TextStyle(fontSize: 18))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                    Text('${e.category}  •  ${DateFormat('d MMM, hh:mm a').format(e.date)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (e.note != null) Text(e.note!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  Text('₹${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                ]),
              ),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildPie(Map<String, double> data) {
    final entries = data.entries.toList();
    return PieChart(PieChartData(
      sectionsSpace: 3, centerSpaceRadius: 45,
      sections: entries.asMap().entries.map((e) {
        final i = kCategories.indexOf(e.value.key);
        final color = AppColors.categoryColors[i >= 0 ? i % AppColors.categoryColors.length : e.key % AppColors.categoryColors.length];
        final pct = (_total > 0 ? (e.value.value / _total * 100) : 0).toStringAsFixed(0);
        return PieChartSectionData(value: e.value.value, color: color, title: '$pct%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12), radius: 70);
      }).toList(),
    ));
  }

  Widget _buildBar(Map<String, double> data) {
    final entries = data.entries.toList();
    return BarChart(BarChartData(
      barGroups: entries.asMap().entries.map((e) {
        final ci = kCategories.indexOf(e.value.key);
        final color = AppColors.categoryColors[ci >= 0 ? ci % AppColors.categoryColors.length : e.key % AppColors.categoryColors.length];
        return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.value, color: color, width: 20, borderRadius: BorderRadius.circular(6))]);
      }).toList(),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
          final i = v.toInt();
          if (i >= entries.length) return const SizedBox();
          final ci = kCategories.indexOf(entries[i].key);
          return Padding(padding: const EdgeInsets.only(top: 4), child: Text(ci >= 0 ? kCategoryIcons[ci] : '💰', style: const TextStyle(fontSize: 14)));
        })),
      ),
    ));
  }
}

class _ChartToggleBtn extends StatelessWidget {
  final IconData icon; final bool active;
  const _ChartToggleBtn({required this.icon, required this.active});
  @override
  Widget build(BuildContext context) => AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: active ? Colors.white : AppColors.textSecondary));
}

// ─── Add Expense Bottom Sheet ─────────────────────────────────────────
class _AddExpenseSheet extends StatefulWidget {
  final ExpenseService svc;
  const _AddExpenseSheet({required this.svc});
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = kCategories[0];
  bool _saving = false;

  @override
  void dispose() { _title.dispose(); _amount.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title.'))); return; }
    final amt = double.tryParse(_amount.text.trim());
    if (amt == null || amt <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount.'))); return; }
    setState(() => _saving = true);
    await widget.svc.add(Expense(id: '', title: _title.text.trim(), amount: amt, category: _category, date: DateTime.now(), note: _note.text.trim().isEmpty ? null : _note.text.trim()));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          const Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 24),

          _lbl('Title'), const SizedBox(height: 8),
          TextField(controller: _title, textCapitalization: TextCapitalization.sentences, decoration: _deco('e.g. Lunch at canteen')),
          const SizedBox(height: 16),

          _lbl('Amount (₹)'), const SizedBox(height: 8),
          TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _deco('0.00')),
          const SizedBox(height: 16),

          _lbl('Category'), const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: List.generate(kCategories.length, (i) {
            final sel = _category == kCategories[i];
            final color = AppColors.categoryColors[i % AppColors.categoryColors.length];
            return GestureDetector(
              onTap: () => setState(() => _category = kCategories[i]),
              child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: sel ? color.withOpacity(0.15) : AppColors.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? color : Colors.grey.shade200, width: sel ? 1.5 : 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Text(kCategoryIcons[i], style: const TextStyle(fontSize: 14)), const SizedBox(width: 4), Text(kCategories[i], style: TextStyle(color: sel ? color : AppColors.textSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 12))])),
            );
          })),
          const SizedBox(height: 16),

          _lbl('Note (optional)'), const SizedBox(height: 8),
          TextField(controller: _note, decoration: _deco('Add a note...')),
          const SizedBox(height: 28),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Save Expense', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
