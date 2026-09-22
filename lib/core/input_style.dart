import 'package:flutter/material.dart';

/// Shared shape for text inputs and dropdowns, including validation states.
class SoftInputBorder extends OutlineInputBorder {
  const SoftInputBorder({
    super.borderSide = const BorderSide(color: Color(0xFFE9ECEF)),
    super.borderRadius = const BorderRadius.all(Radius.circular(15)),
    super.gapPadding = 6,
  });

  @override
  SoftInputBorder copyWith(
          {BorderSide? borderSide,
          BorderRadius? borderRadius,
          double? gapPadding}) =>
      SoftInputBorder(
        borderSide: borderSide ?? this.borderSide,
        borderRadius: borderRadius ?? this.borderRadius,
        gapPadding: gapPadding ?? this.gapPadding,
      );

  @override
  SoftInputBorder scale(double t) => SoftInputBorder(
        borderSide: borderSide.scale(t),
        borderRadius: borderRadius * t,
        gapPadding: gapPadding * t,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is SoftInputBorder
      ? SoftInputBorder(
          borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
          borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
          gapPadding: a.gapPadding + (gapPadding - a.gapPadding) * t)
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is SoftInputBorder ? b.lerpFrom(this, t) : super.lerpTo(b, t);

  @override
  void paint(Canvas canvas, Rect rect,
      {double? gapStart,
      double gapExtent = 0,
      double gapPercentage = 0,
      TextDirection? textDirection}) {
    final shape = borderRadius.toRRect(rect);
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(12))
      ..addRRect(shape));
    canvas.drawRRect(
        shape.shift(const Offset(0, 3)),
        Paint()
          ..color = const Color(0x0D15232D)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.restore();
    super.paint(canvas, rect,
        gapStart: gapStart,
        gapExtent: gapExtent,
        gapPercentage: gapPercentage,
        textDirection: textDirection);
  }
}

InputDecorationTheme appInputStyle(ColorScheme colors, String font) {
  final dark = colors.brightness == Brightness.dark;
  final border = SoftInputBorder(
      borderSide: BorderSide(
          color: dark ? const Color(0xFF3A484E) : const Color(0xFFE9ECEF)));
  return InputDecorationTheme(
    filled: true,
    fillColor: dark ? const Color(0xFF202D33) : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: TextStyle(
        fontFamily: font,
        color: colors.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500),
    floatingLabelStyle: TextStyle(
        fontFamily: font,
        color: colors.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500),
    hintStyle: TextStyle(
        fontFamily: font,
        color: dark ? const Color(0xFF9EAAB0) : const Color(0xFF9BA1A6),
        fontSize: 15),
    prefixIconColor: dark ? const Color(0xFF9EAAB0) : const Color(0xFF9BA1A6),
    suffixIconColor: dark ? const Color(0xFF9EAAB0) : const Color(0xFF9BA1A6),
    border: border,
    enabledBorder: border,
    disabledBorder: border.copyWith(
        borderSide: BorderSide(
            color: dark ? const Color(0xFF303D43) : const Color(0xFFF0F1F3))),
    focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 1.5)),
    errorBorder: border.copyWith(borderSide: BorderSide(color: colors.error)),
    focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: colors.error, width: 1.5)),
  );
}
