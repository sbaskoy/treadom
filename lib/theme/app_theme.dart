import 'package:flutter/material.dart';

/// Uygulamanın Material 3 (Material You) temalarını üreten yardımcı sınıf.
///
/// Tek bir "seed" (tohum) renkten hem açık hem koyu tema türetilir; böylece
/// renk paleti tutarlı kalır. Oyunsu ama temiz bir his için zümrüt yeşili
/// tohum rengi seçilmiştir (fetih/doğa/yürüyüş temasıyla uyumlu).
class AppTheme {
  AppTheme._(); // Örneklenemez; sadece statik üyeler.

  /// Marka tohum rengi (zümrüt yeşili).
  static const Color seedColor = Color(0xFF10B981);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // Ferah ve sade bir AppBar.
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),

      // Yuvarlatılmış köşeli kartlar.
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Dolgulu butonlar için tutarlı, yuvarlak ve ferah bir stil.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Form alanları: yumuşak dolgu, yuvarlak köşe, kenarlıksız.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
