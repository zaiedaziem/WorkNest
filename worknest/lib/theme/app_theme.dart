import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // ── Light / dark mode ─────────────────────────────────────────────────────
  // The neutral colours below (surfaces, borders, text) switch with [isDark];
  // brand and status colours are the same in both modes.
  static bool isDark = false;

  /// System (default) / light / dark — chosen in the profile sheet, saved on the device.
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  static const _themeModeKey = 'theme_mode';

  static Future<void> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      themeMode.value = ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_themeModeKey),
        orElse: () => ThemeMode.system,
      );
    } catch (_) {/* keep the default */}
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (_) {/* not saved — still applied for this session */}
  }

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color secondary = Color(0xFF7C3AED);
  static Color get background => isDark ? const Color(0xFF0F1117) : const Color(0xFFF7F7FB);
  static Color get surface => isDark ? const Color(0xFF181B23) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt => isDark ? const Color(0xFF1E222C) : const Color(0xFFF3F4F8);
  static Color get border => isDark ? const Color(0xFF2C313D) : const Color(0xFFE5E7EB);
  static Color get textDark => isDark ? const Color(0xFFE7E9F0) : const Color(0xFF1A1A2E);
  static Color get textMuted => isDark ? const Color(0xFFA0A7B8) : const Color(0xFF6B7280);
  static Color get textFaint => isDark ? const Color(0xFF737B8E) : const Color(0xFF9CA3AF);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static TextTheme get _textTheme => GoogleFonts.interTextTheme().copyWith(
        headlineSmall: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: textDark,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w700, color: textDark,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 15, color: textDark, height: 1.5),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textDark, height: 1.5),
        bodySmall: GoogleFonts.inter(fontSize: 12.5, color: textMuted, height: 1.4),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
      );

  /// Light theme (kept for existing callers)
  static ThemeData get theme => themeFor(false);

  /// Builds the light or dark theme from the matching colours.
  static ThemeData themeFor(bool dark) {
    final previous = isDark;
    isDark = dark;
    try {
      return _build();
    } finally {
      isDark = previous;
    }
  }

  static ThemeData _build() => ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: isDark ? Brightness.dark : Brightness.light,
          error: danger,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        textTheme: _textTheme,
        splashFactory: InkSparkle.splashFactory,

        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textDark,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: textDark),
        ),

        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: border, width: 1),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: primary.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textDark,
            side: BorderSide(color: border, width: 1.3),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          hintStyle: GoogleFonts.inter(color: textFaint, fontSize: 14),
          labelStyle: GoogleFonts.inter(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger, width: 1.3),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: surfaceAlt,
          selectedColor: primary,
          labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: textDark),
          secondaryLabelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          side: BorderSide.none,
        ),

        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: textDark),
          contentTextStyle: GoogleFonts.inter(fontSize: 14, color: textMuted, height: 1.5),
        ),

        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),

        snackBarTheme: SnackBarThemeData(
          // Always a dark bar with white text, in both modes
          backgroundColor: isDark ? const Color(0xFF2B3040) : const Color(0xFF1A1A2E),
          contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),

        tabBarTheme: TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: textMuted,
          indicatorColor: primary,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),

        dividerTheme: DividerThemeData(
          color: border,
          thickness: 1,
          space: 1,
        ),

        iconTheme: IconThemeData(color: textMuted),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primary,
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      );
}
