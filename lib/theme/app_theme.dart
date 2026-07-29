import 'package:flutter/material.dart';

class AppColors {
  static const primary      = Color(0xFF4C5EFF);
  static const primaryDark  = Color(0xFF2F3BC4);
  static const accent       = Color(0xFFFFB648);
  static const background   = Color(0xFFF7F8FC);
  static const card         = Color(0xFFFFFFFF);
  static const textPrimary  = Color(0xFF1E1E2D);
  static const textSecondary = Color(0xFF7A7E91);
  static const success      = Color(0xFF35C56A);
  static const danger       = Color(0xFFFF5C5C);

  static const List<Color> categoryColors = [
    Color(0xFF4C5EFF), Color(0xFFFFB648), Color(0xFF35C56A),
    Color(0xFFFF5C5C), Color(0xFF9B59B6), Color(0xFF1ABC9C),
    Color(0xFFE67E22), Color(0xFF34495E),
  ];
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: AppColors.textPrimary),
    // Fixed: CardTheme instead of CardThemeData
    cardTheme: CardTheme(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyMedium:    TextStyle(fontSize: 14, color: AppColors.textSecondary),
    ),
  );
}
