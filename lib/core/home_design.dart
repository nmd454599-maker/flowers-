import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'input_style.dart';

enum HomeDesign {
  a('Design A', 'حديقة الورد', Color(0xFF98465F), 28),
  b('Design B', 'بوتيك الهدايا', Color(0xFF355E4C), 8),
  c('Design C', 'لحظات ملوّنة', Color(0xFF7253A1), 20),
  d('Design D', 'اختيارك اليومي', Color(0xFF89552E), 12);

  const HomeDesign(this.label, this.title, this.seed, this.radius);
  final String label;
  final String title;
  final Color seed;
  final double radius;
  String get font => AppTheme.font.value;

  ThemeData theme(Brightness brightness) {
    final colors =
        ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final base =
        ThemeData(useMaterial3: true, colorScheme: colors, fontFamily: font);
    final text = base.textTheme.apply(fontFamily: font);
    return base.copyWith(
      inputDecorationTheme: appInputStyle(colors, font),
      scaffoldBackgroundColor: colors.surface,
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: this == b
              ? 34
              : this == d
                  ? 26
                  : 30,
          fontWeight: this == b ? FontWeight.w500 : FontWeight.w700,
          height: 1.4,
        ),
        titleLarge: text.titleLarge?.copyWith(
            fontSize: this == d ? 19 : 22, fontWeight: FontWeight.w700),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: this == c ? 1 : 0,
        color: colors.surfaceContainerLow,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: this == d ? 72 : 80,
        backgroundColor: this == b ? colors.surface : colors.surfaceContainer,
        indicatorColor:
            this == c ? colors.tertiaryContainer : colors.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(this == b ? 6 : radius)),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(
            fontFamily: font, fontSize: 11, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
