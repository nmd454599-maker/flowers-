import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../screens/customer/product_details_screen.dart';
import 'product_photo.dart';

/// Large photo cards confined to the store profile.
class StoreProfilePhotos extends StatelessWidget {
  final List<Product> products;
  final AppState state;
  final ValueChanged<Product>? onOpen;
  const StoreProfilePhotos(
      {super.key, required this.products, required this.state, this.onOpen});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth * .58).clamp(174.0, 300.0);
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final height = width + 130 * scale.clamp(1.0, 2.5);
        return SizedBox(
            height: height,
            child: ListView.separated(
              key: const PageStorageKey('store-profile-photo-cards'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final product = products[i];
                return SizedBox(
                    width: width,
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant)),
                      child: InkWell(
                          onTap: () {
                            if (onOpen != null) {
                              onOpen!(product);
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => ProductDetailsScreen(
                                          product: product, state: state)));
                            }
                          },
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                    height: width,
                                    child:
                                        Stack(fit: StackFit.expand, children: [
                                      ProductPhoto(product: product),
                                      PositionedDirectional(
                                          top: 10,
                                          end: 10,
                                          child: IconButton(
                                            tooltip: 'حفظ ${product.name}',
                                            style: IconButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor:
                                                    const Color(0xFF777777)),
                                            onPressed: () =>
                                                state.toggleFavorite(product),
                                            icon: Icon(
                                                state.favorites
                                                        .contains(product.id)
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: state.favorites
                                                        .contains(product.id)
                                                    ? const Color(0xFFE9758B)
                                                    : null),
                                          )),
                                    ])),
                                Expanded(
                                    child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 10, 10, 8),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(product.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      height: 1.25,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              const Spacer(),
                                              Row(children: [
                                                const Icon(Icons.star,
                                                    size: 16,
                                                    color: Color(0xFFE8B16D)),
                                                Text(
                                                    ' ${product.rating.toStringAsFixed(1)}',
                                                    style: const TextStyle(
                                                        fontSize: 12))
                                              ]),
                                              const SizedBox(height: 8),
                                              Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 8,
                                                      horizontal: 4),
                                                  decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerLow,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              9)),
                                                  child: Text(
                                                      '${product.price} د.ع',
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight
                                                              .w800))),
                                            ]))),
                              ])),
                    ));
              },
            ));
      });
}
