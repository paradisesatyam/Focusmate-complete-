import 'package:flutter/material.dart';
import '../data/quotes.dart';
import '../theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  final String userName;
  const ProfileHeader({super.key, required this.userName});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final q = QuoteBank.today;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const CircleAvatar(radius: 26, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: 28)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greeting, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
          ]),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.13), borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('"${q['quote']}"', style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic, height: 1.5)),
              const SizedBox(height: 6),
              Text('— ${q['author']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}
