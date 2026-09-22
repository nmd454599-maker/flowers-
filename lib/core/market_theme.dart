import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'input_style.dart';

/// Shared storefront palette matching the sign-in screen.
class MarketTheme {
  static const accent = AppTheme.primary;

  static ThemeData apply(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF5F5F5) : const Color(0xFF191919);
    final paper = dark ? const Color(0xFF101010) : Colors.white;
    final field = dark ? const Color(0xFF242424) : const Color(0xFFF3F3F3);
    final primary = dark ? const Color(0xFF65D6DF) : const Color(0xFF007A83);
    final scheme = base.colorScheme.copyWith(
      primary: primary,
      onPrimary: dark ? const Color(0xFF00383E) : Colors.white,
      secondary: primary,
      onSecondary: dark ? const Color(0xFF00383E) : Colors.white,
      secondaryContainer: field,
      onSecondaryContainer:
          dark ? const Color(0xFFADF2F4) : const Color(0xFF006C75),
      tertiary: primary,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant:
          dark ? const Color(0xFFB8B8B8) : const Color(0xFF606060),
      surfaceContainerLow: field,
      surfaceContainer: field,
      primaryContainer: field,
      onPrimaryContainer:
          dark ? const Color(0xFFADF2F4) : const Color(0xFF006C75),
      outlineVariant: dark ? const Color(0xFF303030) : const Color(0xFFE6E6E6),
    );
    final text = base.textTheme.apply(
        fontFamily: AppTheme.font.value, bodyColor: ink, displayColor: ink);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      textTheme: text.copyWith(
        titleLarge: text.titleLarge
            ?.copyWith(fontSize: 20, height: 1.4, fontWeight: FontWeight.w600),
        titleMedium: text.titleMedium?.copyWith(fontSize: 16, height: 1.4),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
        bodySmall: text.bodySmall?.copyWith(fontSize: 12, height: 1.4),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        titleSpacing: 16,
        backgroundColor: paper,
        foregroundColor: ink,
        toolbarHeight: 56,
        titleTextStyle: TextStyle(
            fontFamily: AppTheme.font.value,
            color: ink,
            fontSize: 19,
            fontWeight: FontWeight.w600),
        systemOverlayStyle:
            dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      iconTheme: IconThemeData(color: ink, size: 22),
      listTileTheme: ListTileThemeData(
          iconColor: primary, textColor: ink, tileColor: paper),
      filledButtonTheme: FilledButtonThemeData(
          style: base.filledButtonTheme.style?.copyWith(
              backgroundColor: WidgetStatePropertyAll(primary),
              foregroundColor: WidgetStatePropertyAll(scheme.onPrimary))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: base.outlinedButtonTheme.style
              ?.copyWith(foregroundColor: WidgetStatePropertyAll(primary))),
      textButtonTheme: TextButtonThemeData(
          style: base.textButtonTheme.style
              ?.copyWith(foregroundColor: WidgetStatePropertyAll(primary))),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
              foregroundColor: ink, backgroundColor: Colors.transparent)),
      dividerTheme: DividerThemeData(
          color: scheme.outlineVariant, thickness: 1, space: 1),
      inputDecorationTheme: appInputStyle(scheme, AppTheme.font.value).copyWith(
        fillColor: field,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primary, width: 1.5)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            size: 25,
            color: states.contains(WidgetState.selected)
                ? ink
                : scheme.onSurfaceVariant)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontFamily: AppTheme.font.value,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: ink)),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(backgroundColor: paper),
      dialogTheme: base.dialogTheme.copyWith(backgroundColor: paper),
      cardTheme: CardThemeData(
          color: paper,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.outlineVariant, width: .6))),
    );
  }
}
