import 'package:flutter/material.dart';
import '../../../widgets/glass_panel.dart';
import '../../../core/icon_scale.dart';

class HomeSearchHeader extends SliverPersistentHeaderDelegate {
  final VoidCallback onTap;
  HomeSearchHeader({required this.onTap});
  @override
  double get minExtent => 88;
  @override
  double get maxExtent => 88;
  @override
  bool shouldRebuild(covariant HomeSearchHeader oldDelegate) =>
      oldDelegate.onTap != onTap;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.expand(
        child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: GlassPanel(
          radius: 24,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Icon(Icons.search_rounded,
                      size: IconScale.of(context).category == 29
                          ? 28
                          : IconScale.of(context).navigation,
                      color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('ابحث عن هدية أو متجر',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: colors.onSurfaceVariant, fontSize: 16))),
                  const SizedBox(width: 8),
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(15)),
                      child: Icon(Icons.tune_rounded,
                          size: IconScale.of(context).navigation,
                          color: colors.onPrimaryContainer)),
                ]),
              ),
            ),
          )),
    ));
  }
}
