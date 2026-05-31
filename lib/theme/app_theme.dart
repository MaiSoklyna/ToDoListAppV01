import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Khmer-modern gold visual identity.
///
/// Color: a warm, restrained gold derived from temple-architecture tones.
/// Typography:
///   - Khmer locale → Battambang for body, Nokora for headings
///   - Latin locale → Inter for everything (with weight changes for hierarchy)
/// Khmer text gets extra line-height because consonant clusters with sub/
/// superscripts need vertical breathing room — too tight and the marks
/// collide with adjacent lines.
/// UI/UX & Theming — color palette, fonts, light/dark theme.
// Maintained by Soklong.

class AppTheme {
  // === Color tokens =========================================================
  // Light mode keeps the warm Khmer-gold identity. Dark mode shifts to a
  // navy/blue palette so it harmonizes with the dark-mode background asset
  // (a deep-navy lotus pattern) — gold is retained as a secondary accent.
  static const Color _goldSeed = Color(0xFFB8923C);
  static const Color _goldOnDark = Color(0xFFE6C76A);

  // Dark-mode blue palette tuned to the bgdarkmode.png navy.
  static const Color _navySeed = Color(0xFF1E3A8A); // royal navy
  static const Color _skyOnDark = Color(0xFF8AB4F8); // soft sky-blue accent
  static const Color _navyInk = Color(0xFF0B1730);   // near-black navy
  static const Color _navySurface = Color(0xFF14223D);
  static const Color _navySurfaceHigh = Color(0xFF1B2C4D);

  // === Public theme builders ===============================================
  static ThemeData lightTheme(Locale locale) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _goldSeed,
      brightness: Brightness.light,
    ).copyWith(
      primary: _goldSeed,
      onPrimary: Colors.white,
      secondary: const Color(0xFF8B6F2A),
      tertiary: const Color(0xFF5C4423),
      surfaceTint: _goldSeed,
    );
    return _buildBaseTheme(scheme, locale, Brightness.light);
  }

  static ThemeData darkTheme(Locale locale) {
    // Build the base palette from a navy seed so all auto-generated tonal
    // surfaces (containers, variants) are blue-tinted instead of brown.
    final scheme = ColorScheme.fromSeed(
      seedColor: _navySeed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _skyOnDark,
      onPrimary: _navyInk,
      primaryContainer: const Color(0xFF1E3A8A),
      onPrimaryContainer: const Color(0xFFD6E3FF),
      // Gold survives as the secondary so it still feels Khmer.
      secondary: _goldOnDark,
      onSecondary: _navyInk,
      secondaryContainer: const Color(0xFF3A2E10),
      onSecondaryContainer: const Color(0xFFFFE6A8),
      tertiary: const Color(0xFF7FD3C9),
      onTertiary: _navyInk,
      // Surfaces sit slightly above the navy bg image so cards/sheets read.
      surface: _navySurface,
      onSurface: const Color(0xFFE6ECF7),
      surfaceContainerLowest: const Color(0xFF0E1A33),
      surfaceContainerLow: const Color(0xFF14223D),
      surfaceContainer: _navySurface,
      surfaceContainerHigh: _navySurfaceHigh,
      surfaceContainerHighest: const Color(0xFF22345A),
      onSurfaceVariant: const Color(0xFFB7C4DE),
      outline: const Color(0xFF6B7DA0),
      outlineVariant: const Color(0xFF334767),
      surfaceTint: _skyOnDark,
    );
    return _buildBaseTheme(scheme, locale, Brightness.dark);
  }

  // === Base theme (shared between light and dark) ==========================
  static ThemeData _buildBaseTheme(
    ColorScheme scheme,
    Locale locale,
    Brightness brightness,
  ) {
    final base = ThemeData.from(colorScheme: scheme, useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme, locale);
    final primaryTextTheme = _buildTextTheme(base.primaryTextTheme, locale);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      // Cards: rounded, slightly elevated. Surface tint pulls a hint of gold
      // through Material 3's elevation overlay.
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      // Inputs: filled, generous padding. Khmer text especially benefits from
      // the extra vertical room.
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 4,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // === Typography ===========================================================
  /// Builds a Material `TextTheme` whose body/heading roles use Battambang +
  /// Nokora when the locale is Khmer, and Inter otherwise. Khmer styles get a
  /// slightly larger line height so consonant clusters don't collide.
  ///
  /// Critically, Khmer fonts are also added to `fontFamilyFallback` even when
  /// the locale is English — Inter has no Khmer glyph coverage, so without
  /// fallback any Khmer text the user types in a TextField renders as blank
  /// boxes. The fallback chain lets Flutter draw Khmer codepoints with
  /// Battambang while keeping Inter for Latin.
  static TextTheme _buildTextTheme(TextTheme base, Locale locale) {
    final isKhmer = locale.languageCode == 'km';
    final bodyHeight = isKhmer ? 1.7 : 1.45;
    final headingHeight = isKhmer ? 1.4 : 1.2;

    // Pre-load Khmer fonts so their family names resolve when used as
    // fallbacks under a non-Khmer primary font (e.g. typing Khmer in EN UI).
    final khmerBody = GoogleFonts.battambang().fontFamily;
    final khmerHeading = GoogleFonts.nokora().fontFamily;
    final khmerFallback = <String>[
      ?khmerBody,
      ?khmerHeading,
      // System Khmer fonts on Android / iOS as a last resort.
      'Noto Sans Khmer',
      'Khmer OS',
    ];

    // Body font (used for bodyLarge/Medium/Small + label* + default text).
    // Battambang has good Khmer coverage and a calm, modern feel; Inter is
    // the Latin counterpart for English.
    final TextTheme body = isKhmer
        ? GoogleFonts.battambangTextTheme(base)
        : GoogleFonts.interTextTheme(base);

    // Heading font (display* / headline* / title*).
    TextStyle heading(TextStyle? source, {FontWeight? weight}) {
      final weighted =
          source?.copyWith(fontWeight: weight ?? FontWeight.w700, height: headingHeight);
      final styled = isKhmer
          ? GoogleFonts.nokora(textStyle: weighted)
          : GoogleFonts.inter(textStyle: weighted);
      return styled.copyWith(fontFamilyFallback: khmerFallback);
    }

    TextStyle bodyOf(TextStyle? source, {FontWeight? weight}) {
      return (source ?? const TextStyle()).copyWith(
        height: bodyHeight,
        fontWeight: weight,
        // Khmer doesn't benefit from letter-spacing the way Latin does; keep
        // it neutral so glyph shapes aren't pulled apart.
        letterSpacing: isKhmer ? 0 : 0.1,
        fontFamilyFallback: khmerFallback,
      );
    }

    return body.copyWith(
      displayLarge: heading(body.displayLarge),
      displayMedium: heading(body.displayMedium),
      displaySmall: heading(body.displaySmall),
      headlineLarge: heading(body.headlineLarge),
      headlineMedium: heading(body.headlineMedium),
      headlineSmall: heading(body.headlineSmall),
      titleLarge: heading(body.titleLarge),
      titleMedium: heading(body.titleMedium, weight: FontWeight.w600),
      titleSmall: heading(body.titleSmall, weight: FontWeight.w600),
      bodyLarge: bodyOf(body.bodyLarge),
      bodyMedium: bodyOf(body.bodyMedium),
      bodySmall: bodyOf(body.bodySmall),
      labelLarge: bodyOf(body.labelLarge, weight: FontWeight.w600),
      labelMedium: bodyOf(body.labelMedium, weight: FontWeight.w600),
      labelSmall: bodyOf(body.labelSmall, weight: FontWeight.w500),
    );
  }
}
