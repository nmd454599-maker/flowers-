import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/app_components.dart';
import '../../widgets/catalog_layout.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen(
      {super.key, required this.state, CatalogLayout? layout})
      : layout = layout ?? CatalogLayout.dense;
  final AppState state;
  final CatalogLayout layout;
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String selected = 'الكل', query = '', sort = 'المقترحة';
  double maxPrice = 1000000;
  bool topRated = false;
  Future<void> filter() async {
    var price = maxPrice;
    var rating = topRated;
    final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('تصفية المنتجات',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 24),
                          Text(price >= 1000000
                              ? 'السعر: جميع الأسعار'
                              : 'حتى ${price.round()} د.ع'),
                          Slider(
                              value: price,
                              min: 0,
                              max: 1000000,
                              divisions: 100,
                              onChanged: (value) =>
                                  update(() => price = value)),
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('تقييم 4 نجوم فأكثر'),
                              value: rating,
                              onChanged: (value) =>
                                  update(() => rating = value)),
                          const SizedBox(height: 16),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('عرض النتائج')),
                          TextButton(
                              onPressed: () => update(() {
                                    price = 1000000;
                                    rating = false;
                                  }),
                              child: const Text('إعادة ضبط')),
                        ])))));
    if (result == true && mounted) {
      setState(() {
        maxPrice = price;
        topRated = rating;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final categories = [
          'الكل',
          ...widget.state.products.map((p) => p.category).toSet()
        ];
        final products = widget.state.products
            .where((p) =>
                (selected == 'الكل' || p.category == selected) &&
                (p.name.contains(query) || p.description.contains(query)) &&
                (maxPrice >= 1000000 || p.price <= maxPrice) &&
                (!topRated || p.rating >= 4))
            .toList();
        if (sort == 'الأقل سعراً') {
          products.sort((a, b) => a.price.compareTo(b.price));
        }
        if (sort == 'الأعلى سعراً') {
          products.sort((a, b) => b.price.compareTo(a.price));
        }
        if (sort == 'الأعلى تقييماً') {
          products.sort((a, b) => b.rating.compareTo(a.rating));
        }
        return Scaffold(
            appBar: AppBar(title: const Text('التصنيفات')),
            body: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                          hintText: 'ابحث عن ورد، باقة أو هدية',
                          prefixIcon: Icon(Icons.search_rounded)))),
              SizedBox(
                  height: 64,
                  child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Center(
                          child: ChoiceChip(
                              selected: selected == categories[i],
                              label: Text(categories[i]),
                              onSelected: (_) =>
                                  setState(() => selected = categories[i]))))),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(
                        child: Text('${products.length} منتج',
                            style: Theme.of(context).textTheme.titleSmall)),
                    TextButton.icon(
                        onPressed: filter,
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('تصفية')),
                    PopupMenuButton<String>(
                        tooltip: 'ترتيب المنتجات',
                        initialValue: sort,
                        onSelected: (value) => setState(() => sort = value),
                        itemBuilder: (_) => [
                              'المقترحة',
                              'الأقل سعراً',
                              'الأعلى سعراً',
                              'الأعلى تقييماً'
                            ]
                                .map((s) =>
                                    PopupMenuItem(value: s, child: Text(s)))
                                .toList(),
                        child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(children: [
                              Icon(Icons.sort_rounded),
                              SizedBox(width: 8),
                              Text('ترتيب')
                            ]))),
                  ])),
              Expanded(
                  child: products.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'لا توجد نتائج',
                          message: 'جرّب كلمة أخرى أو عدّل خيارات التصفية')
                      : CatalogProductView(
                          items: products,
                          state: widget.state,
                          layout: widget.layout)),
            ]));
      });
}
