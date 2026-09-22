import 'package:flutter/material.dart';
import 'app_theme.dart';

enum ColorDirection {
  turquoise('01', 'فيروزي ونعناع', AppTheme.primary, AppTheme.accent),
  rose('02', 'وردي وموف', Color(0xFF9B405F), Color(0xFF755272)),
  lavender('03', 'لافندر وبنفسجي', Color(0xFF71519E), Color(0xFF94604E)),
  sage('04', 'أخضر الميرمية', Color(0xFF496B49), Color(0xFF89644A)),
  peach('05', 'خوخي وطيني', Color(0xFFAC502E), Color(0xFF63754E)),
  navy('06', 'كحلي وأزرق', Color(0xFF34588B), Color(0xFF74713F)),
  burgundy('07', 'عنابي ووردي', Color(0xFF8B2947), Color(0xFF88653C)),
  cocoa('08', 'كاكاو وكريمي', Color(0xFF775441), Color(0xFF7A6440)),
  plum('09', 'برقوقي وليلكي', Color(0xFF783C80), Color(0xFF4D7375)),
  gold('10', 'عسلي وزيتوني', Color(0xFF896600), Color(0xFF5F6E43));

  const ColorDirection(this.number, this.label, this.seed, this.accent);
  final String number;
  final String label;
  final Color seed;
  final Color accent;

  ThemeData theme(Brightness brightness) {
    final accentScheme =
        ColorScheme.fromSeed(seedColor: accent, brightness: brightness);
    final scheme = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        primary: brightness == Brightness.light ? seed : null,
        secondary: accentScheme.primary,
        onSecondary: accentScheme.onPrimary,
        secondaryContainer: accentScheme.primaryContainer,
        onSecondaryContainer: accentScheme.onPrimaryContainer);
    return AppTheme.palette(scheme).copyWith(extensions: [
      CampaignPalette(start: Color.lerp(seed, Colors.black, .4)!, middle: seed),
    ]);
  }
}

class CampaignPalette extends ThemeExtension<CampaignPalette> {
  const CampaignPalette({required this.start, required this.middle});
  final Color start;
  final Color middle;
  @override
  CampaignPalette copyWith({Color? start, Color? middle}) => CampaignPalette(
      start: start ?? this.start, middle: middle ?? this.middle);
  @override
  CampaignPalette lerp(covariant CampaignPalette? other, double t) =>
      other == null
          ? this
          : CampaignPalette(
              start: Color.lerp(start, other.start, t)!,
              middle: Color.lerp(middle, other.middle, t)!);
}
