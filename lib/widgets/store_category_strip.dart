import 'package:flutter/material.dart';
import '../models/models.dart';

/// Only categories represented in this store's catalog are shown.
class StoreCategoryStrip extends StatelessWidget {
  final List<Product> products;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const StoreCategoryStrip({
    super.key,
    required this.products,
    required this.selectedCategory,
    required this.onSelected,
  });

  int? _imageIndex(String? category) {
    if (category == null) return 0;
    if (RegExp('ورد|ورود|زهر|زهور|بوكيه').hasMatch(category)) return 1;
    if (RegExp('هدي|هدايا').hasMatch(category)) return 2;
    if (RegExp('حلو|كيك|شوكولا').hasMatch(category)) return 3;
    if (RegExp('عطر|عطور|جمال|تجميل').hasMatch(category)) return 4;
    if (RegExp('ساعة|ساعات|إكسس|اكسس').hasMatch(category)) return 5;
    if (RegExp('نبات|شتل').hasMatch(category)) return 6;
    if (RegExp('بالون|بالونات').hasMatch(category)) return 7;
    if (RegExp('ديكور|منزل|مزهري').hasMatch(category)) return 8;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final categories = products.map((p) => p.category).toSet().toList();
    final selected =
        categories.contains(selectedCategory) ? selectedCategory : null;
    final colors = Theme.of(context).colorScheme;
    final textHeight = MediaQuery.textScalerOf(context).scale(12) * 1.4;
    return SizedBox(
      height: 98 + textHeight.ceilToDouble() * 2,
      child: ListView.separated(
        key: const ValueKey('store-category-strip'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = index == 0 ? null : categories[index - 1];
          final label = category ?? 'كل الأصناف';
          final active = selected == category;
          final atlasIndex = _imageIndex(category);
          return Semantics(
            button: true,
            selected: active,
            label: label,
            child: Tooltip(
              message: label,
              child: InkWell(
                onTap: () => onSelected(category),
                child: SizedBox(
                  width: 82,
                  child: Column(children: [
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: atlasIndex == null
                            ? Center(
                                child: Text(
                                    products
                                        .firstWhere(
                                            (p) => p.category == category)
                                        .emoji,
                                    style: const TextStyle(fontSize: 48)))
                            : ClipRect(
                                child: OverflowBox(
                                  alignment: Alignment((atlasIndex % 3) - 1.0,
                                      (atlasIndex ~/ 3) - 1.0),
                                  minWidth: 216,
                                  maxWidth: 216,
                                  minHeight: 216,
                                  maxHeight: 216,
                                  child: Image.asset(
                                    'assets/images/store_category_atlas.png',
                                    width: 216,
                                    height: 216,
                                    fit: BoxFit.fill,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                            color: active ? colors.primary : colors.onSurface)),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
