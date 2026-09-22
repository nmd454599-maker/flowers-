import 'package:flutter/material.dart';

import 'product_photo.dart';
import '../models/models.dart';
import '../screens/customer/product_details_screen.dart';
import '../state/app_state.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final AppState state;
  const ProductCard({super.key, required this.product, required this.state});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final favorite = state.favorites.contains(product.id);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.surfaceContainerLow)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailsScreen(product: product, state: state))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Stack(fit: StackFit.expand, children: [
                ProductPhoto(product: product),
                Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: .94),
                        shape: const CircleBorder(),
                        child: IconButton(
                            iconSize: 19,
                            constraints: const BoxConstraints.tightFor(
                                width: 48, height: 48),
                            tooltip: favorite
                                ? 'إزالة من المفضلة'
                                : 'إضافة إلى المفضلة',
                            onPressed: () => state.toggleFavorite(product),
                            icon: Icon(
                                favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: favorite
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.primary)))),
              ])),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFB547), size: 16),
                          Text(' ${product.rating}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(product.category,
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)))
                        ]),
                        const SizedBox(height: 5),
                        Text(product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: Text('${product.price} د.ع',
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14))),
                          SizedBox(
                              width: 48,
                              height: 48,
                              child: FilledButton(
                                  style: FilledButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(11))),
                                  onPressed: () {
                                    state.addToCart(product);
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(const SnackBar(
                                          content:
                                              Text('تمت الإضافة إلى السلة'),
                                          duration: Duration(seconds: 2)));
                                  },
                                  child:
                                      const Icon(Icons.add_rounded, size: 20)))
                        ]),
                      ])),
            ]),
          ),
        );
      });
}
