import 'package:flutter/material.dart';

class IconScale extends ThemeExtension<IconScale> {
  const IconScale(
      this.label, this.category, this.tile, this.radius, this.navigation,
      {this.plain = false});
  final String label;
  final double category, tile, radius, navigation;
  final bool plain;
  static const options = [
    IconScale('01 · الحجم الحالي', 29, 64, 22, 24),
    IconScale('02 · أصغر ومتوازن', 24, 56, 18, 22),
    IconScale('03 · صغير ومختصر', 22, 48, 14, 20),
    IconScale('04 · صغير ودائري', 20, 48, 24, 20),
    IconScale('05 · خفيف بلا خلفية', 22, 48, 14, 20, plain: true),
    IconScale('06 · الأصغر بصريًا', 18, 40, 12, 18),
  ];
  static IconScale of(BuildContext context) =>
      Theme.of(context).extension<IconScale>() ?? options.first;
  @override
  IconScale copyWith() => this;
  @override
  IconScale lerp(covariant IconScale? other, double t) =>
      other == null || t < .5 ? this : other;
}
