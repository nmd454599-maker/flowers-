import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/app_components.dart';
import '../../widgets/product_photo.dart';

class StoreProductAlbum extends StatefulWidget {
  const StoreProductAlbum(
      {super.key,
      required this.products,
      required this.onAdd,
      required this.onEdit});
  final List<Product> products;
  final VoidCallback onAdd;
  final ValueChanged<Product> onEdit;
  @override
  State<StoreProductAlbum> createState() => _StoreProductAlbumState();
}

class _StoreProductAlbumState extends State<StoreProductAlbum> {
  String query = '', category = 'الكل';
  bool large = true;

  @override
  Widget build(BuildContext context) {
    final categories = [
      'الكل',
      ...widget.products.map((p) => p.category).toSet()
    ];
    final selected = categories.contains(category) ? category : 'الكل';
    final products = widget.products
        .where((p) =>
            (selected == 'الكل' || p.category == selected) &&
            p.name.toLowerCase().contains(query.trim().toLowerCase()))
        .toList();
    return LayoutBuilder(builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      final columns =
          ((constraints.maxWidth - 32) / (large ? 340 : 160 * scale))
              .floor()
              .clamp(1, 5);
      final cardWidth =
          (constraints.maxWidth - 32 - (columns - 1) * 16) / columns;
      return CustomScrollView(
          key: const PageStorageKey('store-product-album'),
          slivers: [
            SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      TextField(
                          onChanged: (v) => setState(() => query = v),
                          decoration: const InputDecoration(
                              hintText: 'ابحث عن منتج في متجرك',
                              prefixIcon: Icon(Icons.search_rounded))),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                          onPressed: widget.onAdd,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('إضافة منتج مع صورة')),
                      const SizedBox(height: 16),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories
                              .map((c) => ChoiceChip(
                                  label: Text(c),
                                  selected: selected == c,
                                  onSelected: (_) =>
                                      setState(() => category = c)))
                              .toList()),
                      const SizedBox(height: 16),
                      Text('${products.length} منتج',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                                value: true,
                                icon: Icon(Icons.crop_square_rounded),
                                label: Text('صور كبيرة')),
                            ButtonSegment(
                                value: false,
                                icon: Icon(Icons.grid_view_rounded),
                                label: Text('شبكة')),
                          ],
                          selected: {
                            large
                          },
                          onSelectionChanged: (v) =>
                              setState(() => large = v.single)),
                    ]))),
            if (products.isEmpty)
              SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                      icon: Icons.photo_library_outlined,
                      title: widget.products.isEmpty
                          ? 'ألبوم متجرك فارغ'
                          : 'لا توجد نتائج',
                      message: widget.products.isEmpty
                          ? 'أضف أول منتج وصورته ليظهر هنا'
                          : 'جرّب اسماً آخر أو تصنيفاً مختلفاً'))
            else
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid.builder(
                      itemCount: products.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: cardWidth * .8 + 160 * scale),
                      itemBuilder: (context, i) {
                        final p = products[i];
                        return Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Semantics(
                                      button: true,
                                      label: 'تكبير صورة ${p.name}',
                                      child: InkWell(
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      _ProductPhotoViewer(
                                                          product: p))),
                                          child: SizedBox(
                                              height: cardWidth * .8,
                                              child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    ProductPhoto(product: p),
                                                    PositionedDirectional(
                                                        end: 12,
                                                        bottom: 12,
                                                        child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            decoration: BoxDecoration(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .surface,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12)),
                                                            child: const Icon(Icons
                                                                .zoom_in_rounded))),
                                                  ])))),
                                  Expanded(
                                      child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(p.name,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium),
                                                const SizedBox(height: 4),
                                                Text('${p.price} د.ع',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge),
                                                const Spacer(),
                                                OutlinedButton.icon(
                                                    onPressed: () =>
                                                        widget.onEdit(p),
                                                    icon: const Icon(
                                                        Icons.edit_outlined),
                                                    label: const Text('تعديل')),
                                              ]))),
                                ]));
                      })),
          ]);
    });
  }
}

class _ProductPhotoViewer extends StatelessWidget {
  const _ProductPhotoViewer({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(product.name)),
        body: SafeArea(
            child: Column(children: [
          Expanded(
              child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: SizedBox.expand(
                      child: ProductPhoto(
                          product: product, fit: BoxFit.contain)))),
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('استخدم إصبعين لتكبير الصورة وتحريكها')),
        ])),
      );
}
