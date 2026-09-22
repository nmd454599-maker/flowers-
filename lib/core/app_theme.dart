import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_tokens.dart';
import 'input_style.dart';

class AppTheme {
  static const primary = Color(0xFF009EAA);
  static const primaryLight = Color(0xFF26AFA8);
  static const accent = Color(0xFF008A96);
  static const background = Color(0xFFF2F2F7);
  static const surface = Colors.white;
  static const field = Color(0xFFEBF4F7);
  static const line = Color(0xFFDCE9EE);
  static const muted = Color(0xFF617781);
  static const softPink = Color(0xFFDDF4F0);
  static const defaultFont = 'Tajawal';
  static final font = ValueNotifier<String>(defaultFont);
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);
  static Future<void> restoreMode() async {
    final value = await SharedPreferencesAsync().getString('appearance');
    mode.value = ThemeMode.values.where((m) => m.name == value).firstOrNull ??
        ThemeMode.system;
  }

  static Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    try {
      await SharedPreferencesAsync().setString('appearance', value.name);
    } catch (_) {
      // The selected theme still works for this session if storage is unavailable.
    }
  }

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData palette(ColorScheme colors) =>
      _build(colors.brightness, colors: colors);
  static ThemeData _build(Brightness brightness, {ColorScheme? colors}) {
    final dark = brightness == Brightness.dark;
    final scheme = colors ??
        ColorScheme.fromSeed(
            seedColor: primary,
            brightness: brightness,
            primary: dark ? const Color(0xFF70D7E8) : primary,
            secondary: dark ? const Color(0xFF67DCC6) : accent,
            surface: dark ? const Color(0xFF1C1C1E) : surface);
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius));
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    return ThemeData(
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
        cupertinoOverrideTheme: CupertinoThemeData(
            primaryColor: scheme.primary, brightness: brightness),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18))),
        brightness: brightness,
        colorScheme: scheme,
        fontFamily: font.value,
        visualDensity: VisualDensity.standard,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        scaffoldBackgroundColor: colors != null
            ? scheme.surface
            : dark
                ? const Color(0xFF000000)
                : background,
        canvasColor: scheme.surface,
        textTheme: const TextTheme(
            headlineMedium: TextStyle(
                fontSize: 30, fontWeight: FontWeight.w700, height: 1.35),
            headlineSmall: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, height: 1.35),
            titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            titleSmall: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
            bodyLarge: TextStyle(fontSize: 16, height: 1.5),
            bodyMedium: TextStyle(fontSize: 14, height: 1.5),
            bodySmall: TextStyle(fontSize: 12, height: 1.5),
            labelLarge: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
            labelMedium: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)),
        cardTheme: CardThemeData(
            color: scheme.surface,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: shape.copyWith(
                side: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: .45)))),
        appBarTheme: AppBarTheme(
            systemOverlayStyle:
                dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            backgroundColor: Colors.transparent,
            foregroundColor: scheme.onSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 56,
            titleSpacing: 16,
            titleTextStyle: TextStyle(
                fontFamily: font.value,
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface),
            centerTitle: true),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
        iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: scheme.primary,
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)))),
        inputDecorationTheme: appInputStyle(scheme, font.value),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
                minimumSize: const Size(48, AppDimensions.buttonHeight),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: buttonShape,
                textStyle: TextStyle(
                    fontFamily: font.value,
                    fontSize: 14,
                    fontWeight: FontWeight.w600))),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                foregroundColor: scheme.primary,
                minimumSize: const Size(48, AppDimensions.buttonHeight),
                shape: buttonShape)),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(48, AppDimensions.buttonHeight),
                shape: buttonShape)),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 48), shape: buttonShape)),
        listTileTheme: ListTileThemeData(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            iconColor: scheme.primary,
            minVerticalPadding: 12),
        chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: scheme.outlineVariant),
            selectedColor: scheme.secondaryContainer,
            labelStyle: TextStyle(fontFamily: font.value, color: scheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
        navigationBarTheme: NavigationBarThemeData(height: 80, elevation: 0, backgroundColor: scheme.surfaceContainer, indicatorColor: scheme.primaryContainer),
        dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: .5), thickness: 1),
        bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), showDragHandle: true),
        dialogTheme: DialogThemeData(backgroundColor: scheme.surfaceContainerHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
        snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder()
        }));
  }
}

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});
  @override
  Widget build(BuildContext context) => PopupMenuButton<ThemeMode>(
      tooltip: 'مظهر التطبيق',
      icon: Icon(Theme.of(context).brightness == Brightness.dark
          ? Icons.dark_mode_rounded
          : Icons.light_mode_rounded),
      initialValue: AppTheme.mode.value,
      onSelected: AppTheme.setMode,
      itemBuilder: (_) => const [
            PopupMenuItem(value: ThemeMode.system, child: Text('حسب الجهاز')),
            PopupMenuItem(value: ThemeMode.light, child: Text('الوضع الفاتح')),
            PopupMenuItem(value: ThemeMode.dark, child: Text('الوضع الداكن'))
          ]);
}
