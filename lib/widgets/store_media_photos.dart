import 'package:flutter/material.dart';
import '../models/models.dart';
import 'product_photo.dart';

/// Shows every saved product photo, not only each product's cover.
class StoreMediaPhotos extends StatelessWidget {
  final List<Product> products;
  const StoreMediaPhotos({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final photos = <(Product, String?)>[
      for (final product in products)
        if (product.photos.isEmpty)
          (product, null)
        else
          for (final source in product.photos) (product, source),
    ];
    if (photos.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(20),
          child: Text('لا توجد صور منتجات بعد', textAlign: TextAlign.center));
    }
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemBuilder: (context, index) {
        final (product, source) = photos[index];
        return Semantics(
          button: true,
          label: 'عرض صورة ${product.name}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(title: Text(product.name)),
                            body: Center(
                                child: InteractiveViewer(
                                    child: ProductPhoto(
                                        product: product,
                                        source: source,
                                        fit: BoxFit.contain))),
                          ))),
              child: ProductPhoto(product: product, source: source),
            ),
          ),
        );
      },
    );
  }
}
