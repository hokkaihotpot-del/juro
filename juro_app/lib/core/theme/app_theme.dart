import 'package:flutter/material.dart';

/// 信号色定数
class JuroColors {
  JuroColors._();

  static const green = Color(0xFF388E3C);
  static const greenLight = Color(0xFFC8E6C9);
  static const yellow = Color(0xFFF57F17);
  static const yellowLight = Color(0xFFFFF9C4);
  static const red = Color(0xFFC62828);
  static const redLight = Color(0xFFFFCDD2);

  static const primary = Color(0xFF1A6B3C);
  static const primaryLight = Color(0xFF4CAF50);
  static const surface = Color(0xFFF5F5F5);
  static const cardBackground = Colors.white;
}

/// 高齢者向け大フォント・シンプルテーマ
class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: JuroColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: JuroColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: JuroColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          bodySmall: TextStyle(fontSize: 14),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: JuroColors.cardBackground,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
}
