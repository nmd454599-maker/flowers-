import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../state/app_state.dart';
import '../../../widgets/product_photo.dart';
import '../product_details_screen.dart';

class MarketProductList extends StatelessWidget {
  final List<Product> products;
  final AppState state;
  const MarketProductList(
      {super.key, required this.products, required this.state});
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return SizedBox(
      height: 195 + (scale - 1) * 57,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final product = products[i];
          return SizedBox(
              width: 172,
              child: InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(
                            product: product, state: state))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            height: 128,
                            child: Stack(fit: StackFit.expand, children: [
                              ProductPhoto(product: product),
                              PositionedDirectional(
                                  top: 3,
                                  end: 3,
                                  child: SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: IconButton(
                                      tooltip: 'حفظ ${product.name}',
                                      style: IconButton.styleFrom(
                                          backgroundColor: Colors.white
                                              .withValues(alpha: .92),
                                          padding: EdgeInsets.zero),
                                      onPressed: () =>
                                          state.toggleFavorite(product),
                                      icon: Icon(
                                          state.favorites.contains(product.id)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 19,
                                          color: state.favorites
                                                  .contains(product.id)
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : const Color(0xFF777777)),
                                    ),
                                  )),
                            ]),
                          )),
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.star,
                            color: Color(0xFFE8B16D), size: 12),
                        Text(' ${product.rating.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 10, height: 1.2)),
                      ]),
                      const SizedBox(height: 2),
                      Text(product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.2,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('${product.price} د.ع',
                          style: const TextStyle(fontSize: 11, height: 1.2)),
                    ]),
              ));
        },
      ),
    );
  }
}
