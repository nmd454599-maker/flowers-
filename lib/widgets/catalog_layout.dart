import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../screens/customer/product_details_screen.dart';
import 'product_photo.dart';

enum CatalogLayout {
  balanced('01 · عمودان بصور واضحة'),
  compact('02 · عمودان ببطاقات مختصرة'),
  dense('03 · ثلاثة أعمدة'),
  horizontal('04 · قائمة بصور جانبية'),
  rows('05 · قائمة مدمجة'),
  shelves('06 · رفوف حسب التصنيف');

  const CatalogLayout(this.label);
  final String label;
}

class CatalogProductView extends StatelessWidget {
  const CatalogProductView(
      {super.key,
      required this.items,
      required this.state,
      required this.layout});
  final List<Product> items;
  final AppState state;
  final CatalogLayout layout;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    Widget card(Product product) =>
        _CatalogCard(product: product, state: state, layout: layout);
    if (layout == CatalogLayout.horizontal || layout == CatalogLayout.rows) {
      return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => card(items[i]));
    }
    if (layout == CatalogLayout.shelves) {
      final categories = items.map((p) => p.category).toSet().toList();
      return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final group =
                items.where((p) => p.category == categories[i]).toList();
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(categories[i],
                          style: Theme.of(context).textTheme.titleLarge)),
                  SizedBox(
                      height: 285 * scale,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: group.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, j) => SizedBox(
                              width: 165 * scale, child: card(group[j])))),
                ]);
          });
    }
    return LayoutBuilder(builder: (context, constraints) {
      final dense = layout == CatalogLayout.dense;
      final minWidth = dense ? 105.0 : 150.0;
      final columns = ((constraints.maxWidth - 24) / (minWidth * scale))
          .floor()
          .clamp(1, dense ? 6 : 4);
      return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: (layout == CatalogLayout.balanced
                      ? 325
                      : dense
                          ? 260
                          : 275) *
                  scale,
              mainAxisSpacing: 12,
              crossAxisSpacing: dense ? 8 : 12),
          itemBuilder: (_, i) => card(items[i]));
    });
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard(
      {required this.product, required this.state, required this.layout});
  final Product product;
  final AppState state;
  final CatalogLayout layout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final small = layout == CatalogLayout.dense || layout == CatalogLayout.rows;
    final horizontal =
        layout == CatalogLayout.horizontal || layout == CatalogLayout.rows;
    final favorite = state.favorites.contains(product.id);
    final actions =
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      IconButton(
          tooltip: favorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
          onPressed: () => state.toggleFavorite(product),
          icon: Icon(favorite ? Icons.favorite : Icons.favorite_border,
              size: 20)),
      IconButton.filled(
          tooltip: 'إضافة إلى السلة: ${product.name}',
          onPressed: () => state.addToCart(product),
          icon: const Icon(Icons.add, size: 20)),
    ]);
    final details = Padding(
        padding: EdgeInsets.all(small ? 4 : 10),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: small ? 12 : 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${product.price} د.ع',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: small ? 12 : 14)),
              Row(children: [
                Icon(Icons.star_rounded, size: 14, color: colors.secondary),
                const SizedBox(width: 3),
                Expanded(
                    child: Text(
                        '${product.rating}${small ? '' : ' • توصيل اليوم'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: colors.onSurfaceVariant)))
              ]),
              if (layout != CatalogLayout.rows) actions,
            ]));
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(layout == CatalogLayout.balanced ? 22 : 12),
          side: BorderSide(color: colors.outlineVariant)),
      child: InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ProductDetailsScreen(product: product, state: state))),
          child: horizontal
              ? Row(children: [
                  SizedBox(
                      width: layout == CatalogLayout.rows ? 64 : 112,
                      height: layout == CatalogLayout.rows ? 100 : 152,
                      child: ProductPhoto(product: product)),
                  Expanded(child: details),
                  if (layout == CatalogLayout.rows)
                    SizedBox(
                        width: 48,
                        child: Column(children: [
                          IconButton(
                              tooltip: favorite
                                  ? 'إزالة من المفضلة'
                                  : 'إضافة إلى المفضلة',
                              onPressed: () => state.toggleFavorite(product),
                              icon: Icon(
                                  favorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 20)),
                          IconButton(
                              tooltip: 'إضافة إلى السلة: ${product.name}',
                              onPressed: () => state.addToCart(product),
                              icon: const Icon(Icons.add, size: 20)),
                        ])),
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      Expanded(child: ProductPhoto(product: product)),
                      details,
                    ])),
    );
  }
}
