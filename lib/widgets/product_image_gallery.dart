import 'package:flutter/material.dart';
import '../models/models.dart';
import 'product_photo.dart';

class ProductImageGallery extends StatefulWidget {
  final Product product;
  const ProductImageGallery({super.key, required this.product});

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  final pages = PageController();
  int selected = 0;

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.product.photos;
    final sources = photos.isEmpty ? <String?>[null] : photos;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AspectRatio(
        aspectRatio: 1,
        child: PageView.builder(
          key: const ValueKey('product-photo-pages'),
          controller: pages,
          itemCount: sources.length,
          onPageChanged: (index) => setState(() => selected = index),
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              title: Text(widget.product.name)),
                          body: Center(
                              child: InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 4,
                                  child: ProductPhoto(
                                      product: widget.product,
                                      source: sources[index],
                                      fit: BoxFit.contain,
                                      originalResolution: true))),
                        ))),
            child:
                ProductPhoto(product: widget.product, source: sources[index]),
          ),
        ),
      ),
      if (sources.length > 1)
        SizedBox(
            height: 94,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: sources.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Semantics(
                selected: selected == index,
                label: 'الصورة ${index + 1} من ${sources.length}',
                button: true,
                child: GestureDetector(
                  key: ValueKey('product-thumbnail-$index'),
                  onTap: () => pages.animateToPage(index,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut),
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            width: 2,
                            color: selected == index
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent)),
                    child: Opacity(
                        opacity: selected == index ? 1 : .55,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: ProductPhoto(
                                product: widget.product,
                                source: sources[index]))),
                  ),
                ),
              ),
            )),
    ]);
  }
}
