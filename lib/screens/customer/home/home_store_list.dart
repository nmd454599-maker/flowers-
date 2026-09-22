import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/models.dart';
import '../../../widgets/product_photo.dart';

class HomeStoreList extends StatelessWidget {
  final List<Store> stores;
  final List<Product> products;
  final ValueChanged<Store> onStoreTap;
  const HomeStoreList(
      {super.key,
      required this.stores,
      required this.products,
      required this.onStoreTap});
  @override
  Widget build(BuildContext context) => SizedBox(
      height: stores.isEmpty
          ? 55 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0)
          : 266 +
              (MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0) - 1) *
                  110,
      child: stores.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('لا توجد متاجر متاحة حالياً',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: stores.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final store = stores[i];
                final items = products
                    .where((p) => p.storeId == store.id)
                    .take(3)
                    .toList();
                return SizedBox(
                    width: 280,
                    child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                            onTap: () => onStoreTap(store),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                      height: 178,
                                      child: items.isEmpty
                                          ? const Center(
                                              child: Icon(
                                                  CupertinoIcons
                                                      .building_2_fill,
                                                  size: 40))
                                          : Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                  Expanded(
                                                      flex: 2,
                                                      child: ProductPhoto(
                                                          product:
                                                              items.first)),
                                                  if (items.length > 1) ...[
                                                    const SizedBox(width: 2),
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .stretch,
                                                            children: [
                                                          Expanded(
                                                              child: ProductPhoto(
                                                                  product:
                                                                      items[
                                                                          1])),
                                                          if (items.length >
                                                              2) ...[
                                                            const SizedBox(
                                                                height: 2),
                                                            Expanded(
                                                                child: ProductPhoto(
                                                                    product:
                                                                        items[
                                                                            2]))
                                                          ]
                                                        ]))
                                                  ]
                                                ])),
                                  Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Expanded(
                                                  child: Text(store.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight
                                                              .w700))),
                                              const Icon(Icons.star_rounded,
                                                  color: Color(0xFFEEA15B),
                                                  size: 15),
                                              Text(' ${store.rating}',
                                                  style: const TextStyle(
                                                      fontSize: 11))
                                            ]),
                                            const SizedBox(height: 4),
                                            Row(children: [
                                              Icon(CupertinoIcons.car_detailed,
                                                  size: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant),
                                              const SizedBox(width: 5),
                                              Text(
                                                  '${store.deliveryMinutes} دقيقة • ${store.city}',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant))
                                            ])
                                          ])),
                                ]))));
              }));
}
