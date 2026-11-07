import 'package:flutter/material.dart';

// Every color here comes from the web app's global.css, so mobile and web
// look like the same product in both light and dark mode.
class AppColors {
  // Light mode
  static const primary600 = Color(0xFF5F4AFF);
  static const primary700 = Color(0xFF4F3BD8);
  static const primary100 = Color(0xFFE8E4FF);
  static const accent = Color(0xFFF4F2FF);
  static const iconBoxLight = Color(0xFFF7F8FC);
  static const mutedLight = Color(0xFF667085);

  // Dark mode ("One Dark" palette in the web CSS)
  static const darkBg = Color(0xFF21252B);
  static const darkSurface = Color(0xFF282C34);
  static const darkHover = Color(0xFF2C313A);
  static const darkSelected = Color(0xFF323842);
  static const darkBorder = Color(0xFF3B4048);
  static const darkAccent = Color(0xFF61AFEF);
  static const darkButton = Color(0xFF528BBA);
  static const mutedDark = Color(0xFFCBD5E1);
}

class AppTheme {
  static ThemeData light() => _build(
    scheme: const ColorScheme.light(
      primary: AppColors.primary700,
      onPrimary: Colors.white,
      secondary: AppColors.primary600,
      surface: Colors.white,
      onSurface: Colors.black,
      outline: AppColors.primary100,
    ),
    background: Colors.white,
  );

  static ThemeData dark() => _build(
    scheme: const ColorScheme.dark(
      primary: AppColors.darkButton,
      onPrimary: Colors.white,
      secondary: AppColors.darkAccent,
      surface: AppColors.darkSurface,
      onSurface: Colors.white,
      outline: AppColors.darkBorder,
    ),
    background: AppColors.darkBg,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: scheme.outline,
    );
  }
}

// Shortcuts so widgets ask for "the border color" instead of checking
// dark/light themselves each time.
extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get borderColor => Theme.of(this).colorScheme.outline;
  Color get hoverColor => isDark ? AppColors.darkHover : AppColors.accent;
  Color get selectedColor => isDark ? AppColors.darkSelected : AppColors.accent;
  Color get iconBoxColor => isDark ? AppColors.darkBg : AppColors.iconBoxLight;
  Color get mutedText => isDark ? AppColors.mutedDark : AppColors.mutedLight;
  Color get brandColor => isDark ? AppColors.darkAccent : AppColors.primary600;

  // Status colors (replace the _green/_red/_amber helpers in dashboard.dart).
  Color get successColor =>
      isDark ? const Color(0xFF6EE7B7) : const Color(0xFF1E9E3E);
  Color get dangerColor =>
      isDark ? const Color(0xFFFCA5A5) : const Color(0xFFE5484D);
  Color get warningColor =>
      isDark ? const Color(0xFFF5C26B) : const Color(0xFFD98A0B);
}
