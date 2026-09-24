import 'package:flutter/material.dart';

class AppTheme {
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _slate300 = Color(0xFFCBD5E1);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _amber400 = Color(0xFFFBBF24);
  static const Color _amber500 = Color(0xFFF59E0B);
  static const Color _amber600 = Color(0xFFD97706);
  static const Color _rose500 = Color(0xFFF43F5E);

  static const Color _gray50 = Color(0xFFF9FAFB);
  static const Color _gray100 = Color(0xFFF3F4F6);
  static const Color _gray200 = Color(0xFFE5E7EB);
  static const Color _gray300 = Color(0xFFD1D5DB);
  static const Color _gray500 = Color(0xFF6B7280);
  static const Color _gray700 = Color(0xFF374151);
  static const Color _gray800 = Color(0xFF1F2937);
  static const Color _gray900 = Color(0xFF111827);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _gray50,
      colorScheme: const ColorScheme.light(
        primary: _amber600,
        secondary: _amber600,
        tertiary: _amber600,
        surface: _white,
        surfaceContainerHighest: _gray100,
        surfaceContainerHigh: _gray200,
        surfaceContainer: _gray200,
        surfaceContainerLow: _gray100,
        surfaceContainerLowest: _white,
        surfaceBright: _white,
        surfaceDim: _gray100,
        surfaceTint: _amber600,
        error: _rose500,
        onPrimary: _white,
        onSecondary: _white,
        onTertiary: _white,
        onSurface: _gray900,
        onSurfaceVariant: _gray500,
        onError: _white,
        onErrorContainer: _white,
        outline: _gray300,
        outlineVariant: _gray200,
        shadow: Colors.black26,
        scrim: Colors.black54,
        inverseSurface: _gray800,
        onInverseSurface: _gray100,
        inversePrimary: _amber400,
      ),
      cardTheme: CardThemeData(
        color: _white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _gray200, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _amber600,
          foregroundColor: _white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _amber600,
          foregroundColor: _white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _gray700,
          side: BorderSide(color: _gray300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _gray700,
          backgroundColor: Colors.transparent,
        ),
      ),
      iconTheme: const IconThemeData(color: _gray700, size: 24),
      sliderTheme: SliderThemeData(
        activeTrackColor: _amber600,
        inactiveTrackColor: _gray200,
        thumbColor: _amber600,
        overlayColor: _amber600.withValues(alpha: 0.12),
        valueIndicatorColor: _amber600,
        valueIndicatorTextStyle: const TextStyle(color: _white),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      dividerTheme: DividerThemeData(color: _gray200, thickness: 0.5, space: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _gray900,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _gray700),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _white,
        elevation: 0,
        selectedItemColor: _amber600,
        unselectedItemColor: _gray500,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _white,
        elevation: 0,
        indicatorColor: _amber600.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: _amber600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }
          return const TextStyle(
            color: _gray500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: _gray900,
          fontWeight: FontWeight.w300,
          fontSize: 57,
        ),
        displayMedium: TextStyle(
          color: _gray900,
          fontWeight: FontWeight.w300,
          fontSize: 45,
        ),
        displaySmall: TextStyle(
          color: _gray900,
          fontWeight: FontWeight.w400,
          fontSize: 36,
        ),
        headlineLarge: TextStyle(
          color: _gray900,
          fontWeight: FontWeight.w600,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: _gray900,
          fontWeight: FontWeight.w600,
          fontSize: 28,
        ),
        headlineSmall: TextStyle(
          color: _gray900,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: _gray900,
          fontWeight: FontWeight.w500,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: _gray700,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          color: _gray700,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(
          color: _gray700,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: _gray700,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: _gray500,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: _gray700,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelMedium: TextStyle(
          color: _gray500,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          color: _gray500,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _slate950,
      colorScheme: const ColorScheme.dark(
        primary: _amber400,
        secondary: _amber400,
        tertiary: _amber400,
        surface: _slate900,
        surfaceContainerHighest: _slate800,
        surfaceContainerHigh: _slate700,
        surfaceContainer: _slate700,
        surfaceContainerLow: _slate800,
        surfaceContainerLowest: _slate950,
        surfaceBright: _slate800,
        surfaceDim: _slate900,
        surfaceTint: _amber400,
        error: _rose500,
        onPrimary: _slate950,
        onSecondary: _slate950,
        onTertiary: _slate950,
        onSurface: _slate100,
        onSurfaceVariant: _slate300,
        onError: _white,
        onErrorContainer: _white,
        outline: _slate600,
        outlineVariant: _slate700,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: _slate100,
        onInverseSurface: _slate950,
        inversePrimary: _amber500,
      ),
      cardTheme: CardThemeData(
        color: _slate900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _slate700.withValues(alpha: 0.5), width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _amber400,
          foregroundColor: _slate950,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _amber400,
          foregroundColor: _slate950,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _slate300,
          side: BorderSide(color: _slate600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _slate300,
          backgroundColor: Colors.transparent,
        ),
      ),
      iconTheme: const IconThemeData(color: _slate300, size: 24),
      sliderTheme: SliderThemeData(
        activeTrackColor: _amber400,
        inactiveTrackColor: _slate700,
        thumbColor: _amber400,
        overlayColor: _amber400.withValues(alpha: 0.15),
        valueIndicatorColor: _amber400,
        valueIndicatorTextStyle: const TextStyle(color: _slate950),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      dividerTheme: DividerThemeData(
        color: _slate700.withValues(alpha: 0.5),
        thickness: 0.5,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _slate100,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _slate300),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _slate900,
        elevation: 0,
        selectedItemColor: _amber400,
        unselectedItemColor: _slate300,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _slate900,
        elevation: 0,
        indicatorColor: _amber400.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: _amber400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }
          return const TextStyle(
            color: _slate300,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: _slate100,
          fontWeight: FontWeight.w300,
          fontSize: 57,
        ),
        displayMedium: TextStyle(
          color: _slate100,
          fontWeight: FontWeight.w300,
          fontSize: 45,
        ),
        displaySmall: TextStyle(
          color: _slate100,
          fontWeight: FontWeight.w400,
          fontSize: 36,
        ),
        headlineLarge: TextStyle(
          color: _slate100,
          fontWeight: FontWeight.w600,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: _slate100,
          fontWeight: FontWeight.w600,
          fontSize: 28,
        ),
        headlineSmall: TextStyle(
          color: _slate100,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: _slate100,
          fontWeight: FontWeight.w500,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: _slate300,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          color: _slate300,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(
          color: _slate300,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: _slate300,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: _slate300,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: _slate300,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelMedium: TextStyle(
          color: _slate300,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          color: _slate300,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  static ThemeData withAccentColor(ThemeData base, Color accentColor) {
    final glowColor = _computeGlowColor(accentColor);
    final borderColor = _computeBorderColor(accentColor);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: accentColor,
        secondary: accentColor,
        tertiary: accentColor,
        surfaceTint: accentColor,
        inversePrimary: _darkenColor(accentColor),
      ),
      extensions: <ThemeExtension<dynamic>>[
        DynamicColorExtension(
          accentColor: accentColor,
          glowColor: glowColor,
          borderColor: borderColor,
        ),
      ],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: _slate950,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: _slate950,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: accentColor,
        thumbColor: accentColor,
        overlayColor: accentColor.withValues(alpha: 0.15),
        valueIndicatorColor: accentColor,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: accentColor,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        indicatorColor: accentColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }
          return const TextStyle(
            color: _slate300,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: accentColor),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: _slate900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        iconTheme: IconThemeData(color: accentColor),
      ),
      iconTheme: IconThemeData(color: _slate300, size: 24),
    );
  }

  static ThemeData withAccentColorLight(ThemeData base, Color accentColor) {
    final glowColor = _computeGlowColor(accentColor);
    final borderColor = _computeBorderColor(accentColor);
    final darkAccent = _darkenColor(accentColor);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: accentColor,
        secondary: accentColor,
        tertiary: accentColor,
        surfaceTint: accentColor,
        inversePrimary: _darkenColor(accentColor),
      ),
      extensions: <ThemeExtension<dynamic>>[
        DynamicColorExtension(
          accentColor: accentColor,
          glowColor: glowColor,
          borderColor: borderColor,
        ),
      ],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: _white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: _white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: accentColor,
        thumbColor: accentColor,
        overlayColor: accentColor.withValues(alpha: 0.12),
        valueIndicatorColor: accentColor,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: accentColor,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        indicatorColor: accentColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }
          return const TextStyle(
            color: _gray500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: accentColor),
      ),
      cardTheme: base.cardTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        iconTheme: IconThemeData(color: accentColor),
      ),
    );
  }

  static Color _computeGlowColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return HSLColor.fromAHSL(
      1.0,
      hsl.hue,
      (hsl.saturation * 1.3).clamp(0.0, 1.0),
      (hsl.lightness * 1.2).clamp(0.0, 1.0),
    ).toColor();
  }

  static Color _computeBorderColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return HSLColor.fromAHSL(
      1.0,
      hsl.hue,
      (hsl.saturation * 1.1).clamp(0.0, 1.0),
      (hsl.lightness * 1.4).clamp(0.0, 1.0),
    ).toColor();
  }

  static Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return HSLColor.fromAHSL(
      1.0,
      hsl.hue,
      hsl.saturation,
      (hsl.lightness * 0.7).clamp(0.0, 1.0),
    ).toColor();
  }
}

class DynamicColorExtension extends ThemeExtension<DynamicColorExtension> {
  final Color accentColor;
  final Color glowColor;
  final Color borderColor;

  const DynamicColorExtension({
    required this.accentColor,
    required this.glowColor,
    required this.borderColor,
  });

  @override
  DynamicColorExtension copyWith({
    Color? accentColor,
    Color? glowColor,
    Color? borderColor,
  }) {
    return DynamicColorExtension(
      accentColor: accentColor ?? this.accentColor,
      glowColor: glowColor ?? this.glowColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  @override
  DynamicColorExtension lerp(
    ThemeExtension<DynamicColorExtension>? other,
    double t,
  ) {
    if (other is! DynamicColorExtension) return this;
    return DynamicColorExtension(
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
    );
  }
}
