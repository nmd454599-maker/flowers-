import 'package:flutter/material.dart';

/// A product silhouette from the transparent category atlas, with no frame.
class CategoryCutout extends StatelessWidget {
  final int index;
  final double size;
  const CategoryCutout({super.key, required this.index, this.size = 53});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment((index % 3) - 1.0, (index ~/ 3) - 1.0),
            minWidth: size * 3,
            maxWidth: size * 3,
            minHeight: size * 3,
            maxHeight: size * 3,
            child: Image.asset('assets/images/store_category_atlas.png',
                width: size * 3,
                height: size * 3,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high),
          ),
        ),
      );
}
