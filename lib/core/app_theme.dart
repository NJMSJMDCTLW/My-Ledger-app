import 'package:flutter/material.dart';

/// A warm, macaron-colored theme.
class AppTheme {
  // Primary color: peach pink
  static const Color _seed = Color(0xFFF2A5A0);

  /// The macaron palette, 12 colors, so each of the 11 default categories gets a unique color:
  /// pink, peach, butter yellow, mint, sky blue, lavender, orchid pink, pistachio,
  /// periwinkle blue, teal, caramel, coral.
  static const List<Color> macaron = [
    Color(0xFFF7A8B8),
    Color(0xFFFFC9A3),
    Color(0xFFFFE29A),
    Color(0xFFB5E3C8),
    Color(0xFFA8D8EA),
    Color(0xFFC9B6E4),
    Color(0xFFF2B8DD),
    Color(0xFFD9E4A1),
    Color(0xFFB3BDF0),
    Color(0xFF9ADBD3),
    Color(0xFFE5C9A8),
    Color(0xFFF6A59A),
  ];

  /// A category always has the same color across the whole app (colors only start repeating past 12 categories).
  static Color categoryColor(int? categoryId) {
    if (categoryId == null) return const Color(0xFFD9CFC7);
    return macaron[categoryId % macaron.length];
  }

  /// All palette colors are light, so text on top of them uses a dark brown to stay readable.
  static const Color onMacaron = Color(0xFF5A4038);

  static const Color expense = Color(0xFFE0707F);
  static const Color income = Color(0xFF5DAE8B);

  /// Color for a balance: green when positive, red when negative, default (null) when exactly 0.
  static Color? balanceColor(int cents) {
    if (cents > 0) return income;
    if (cents < 0) return expense;
    return null;
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    var scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    if (isLight) {
      scheme = scheme.copyWith(
        surface: const Color(0xFFFFF8F2), // cream white
        surfaceContainerLowest: Colors.white,
        surfaceContainerHighest: const Color(0xFFFCE9DF),
      );
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: shape,
        color: isLight ? Colors.white : scheme.surfaceContainerHigh,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(shape: shape),
    );
  }
}
