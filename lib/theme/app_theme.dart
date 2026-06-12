import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uygulamanın Material 3 (Material You) temalarını üreten yardımcı sınıf.
///
/// Marka kimliği **koyu lacivert** (ikon/splash), vurgu rengi **teal**
/// ("senin toprağın"), rakip alanlar **mercan**. Palet, tek bir teal tohumdan
/// türetilir; lacivertler koyu modun yüzeylerinde ve marka başlıklarında,
/// mercan ise `error` (rakip) olarak kullanılır.
class AppTheme {
  AppTheme._();

  /// Vurgu / "sen" rengi (teal) — butonlar, kendi alanların, ana aksan.
  static const Color seedColor = Color(0xFF14B8A6);

  /// Marka koyu laciverti (AppBar başlıkları, splash, ikon).
  static const Color brandNavy = Color(0xFF161E42);

  /// Koyu mod yüzey tonları.
  static const Color navyDeep = Color(0xFF0E1430);
  static const Color navySurface = Color(0xFF141B3D);
  static const Color navyElevated = Color(0xFF1E2750);

  /// Rakip alan rengi (mercan) — `ColorScheme.error` olarak kullanılır.
  static const Color enemyColor = Color(0xFFFB6F4C);

  /// Ödül / madalya rengi (altın).
  static const Color rewardColor = Color(0xFFF5B53D);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    var colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ).copyWith(error: enemyColor, onError: Colors.white);

    // Yüzeyleri marka kimliğine uydur: koyu modda lacivert, açık modda teal
    // tonlu (nötr gri yerine markayla uyumlu, "tasarlanmış" his).
    if (isDark) {
      colorScheme = colorScheme.copyWith(
        surface: navySurface,
        onSurface: const Color(0xFFE7EAF3),
        surfaceContainerHighest: navyElevated,
        surfaceContainerHigh: const Color(0xFF1A2247),
        surfaceContainer: brandNavy,
        surfaceContainerLow: navyDeep,
        surfaceContainerLowest: navyDeep,
        outlineVariant: const Color(0xFF36406E),
      );
    } else {
      colorScheme = colorScheme.copyWith(
        surface: const Color(0xFFF2F7F6),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF6FAF9),
        surfaceContainer: const Color(0xFFEDF4F2),
        surfaceContainerHigh: const Color(0xFFE7F0ED),
        surfaceContainerHighest: const Color(0xFFE0EBE8),
        outlineVariant: const Color(0xFFC6D6D1),
      );
    }

    // Modern, geometrik bir font (Sora) tüm metin temasına uygulanır.
    final baseText = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final textTheme = GoogleFonts.soraTextTheme(baseText);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,

      // Modern "büyük başlık": ağır renkli blok yerine sayfa zeminiyle aynı
      // renk, sola yaslı kalın başlık (gölgesiz). Sayfaya gömülü, çağdaş his.
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.sora(
          color: colorScheme.onSurface,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

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
