import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_header.dart';
import '../widgets/section_card.dart';
import 'ai_chat_screen.dart';
import 'calendar_screen.dart';
import 'diary_screen.dart';
import 'expense_screen.dart';
import 'focus_timer_screen.dart';
import 'progress_screen.dart';
import 'todo_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = FirebaseAuth.instance.currentUser?.displayName ?? 'There';

    final sections = [
      {'title': 'Focus Timer',      'subtitle': 'Countdown timer with session tracking', 'icon': Icons.timer_outlined,           'color': AppColors.primary,     'screen': const FocusTimerScreen()},
      {'title': 'To-Do Planner',   'subtitle': 'Tasks with deadline notifications',      'icon': Icons.checklist_rtl,            'color': AppColors.success,     'screen': const TodoScreen()},
      {'title': 'Calendar',        'subtitle': 'Plan and view your schedule',             'icon': Icons.calendar_month_outlined,  'color': AppColors.accent,      'screen': const CalendarScreen()},
      {'title': 'Diary',           'subtitle': 'Journal with mood tracking',              'icon': Icons.book_outlined,            'color': AppColors.danger,      'screen': const DiaryScreen()},
      {'title': 'AI Chat',         'subtitle': 'Powered by Google Gemini',               'icon': Icons.smart_toy_outlined,       'color': AppColors.primaryDark, 'screen': const AiChatScreen()},
      {'title': 'Progress',        'subtitle': 'Focus and task completion charts',        'icon': Icons.bar_chart_rounded,        'color': AppColors.success,     'screen': const ProgressScreen()},
      {'title': 'Expense Analytics','subtitle': 'Track spending with pie & bar charts',  'icon': Icons.account_balance_wallet_outlined, 'color': Color(0xFF9B59B6), 'screen': const ExpenseScreen()},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Colors.white, foregroundColor: AppColors.textSecondary, elevation: 2, tooltip: 'Log out',
        onPressed: () => _logout(context),
        child: const Icon(Icons.logout_rounded, size: 20),
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProfileHeader(userName: name),
          const SizedBox(height: 24),
          Text('Your Sections', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: sections.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.95),
            itemBuilder: (_, i) => SectionCard(
              title: sections[i]['title'] as String,
              subtitle: sections[i]['subtitle'] as String,
              icon: sections[i]['icon'] as IconData,
              color: sections[i]['color'] as Color,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => sections[i]['screen'] as Widget)),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      )),
    );
  }

  void _logout(BuildContext ctx) => showDialog(context: ctx, builder: (c) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Log out?'), content: const Text('You will be returned to the login screen.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white), onPressed: () { Navigator.pop(c); AuthService().signOut(); }, child: const Text('Log Out')),
    ],
  ));
}
