import 'package:flutter/material.dart';

/// Shared dimensions for the Arabic Material 3 interface.
abstract final class AppDimensions {
  static const double spaceSmall = 8;
  static const double space = 16;
  static const double sectionSpace = 24;
  static const double touchTarget = 48;
  static const double buttonHeight = 52;
  static const double fieldRadius = 12;
  static const double cardRadius = 20;
  static const double dialogRadius = 28;
  static const pagePadding = EdgeInsets.all(space);

  static SliverGridDelegate productGrid(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: (width / (scale > 1.3 ? 260 : 190)).floor().clamp(1, 5),
      mainAxisExtent: 340 * scale.clamp(1.0, 2.0),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
    );
  }
}
