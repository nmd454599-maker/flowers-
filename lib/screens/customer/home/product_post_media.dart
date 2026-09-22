import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../widgets/product_photo.dart';

/// Keeps image layout stable while paging and provides brief save feedback.
class ProductPostMedia extends StatefulWidget {
  const ProductPostMedia(
      {super.key,
      required this.product,
      required this.onOpen,
      required this.onSave});
  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  @override
  State<ProductPostMedia> createState() => _ProductPostMediaState();
}

class _ProductPostMediaState extends State<ProductPostMedia> {
  int selected = 0;
  bool showHeart = false;
  Timer? feedback;
  @override
  void didUpdateWidget(covariant ProductPostMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        Object.hashAll(oldWidget.product.photos) !=
            Object.hashAll(widget.product.photos)) {
      selected = 0;
      showHeart = false;
      feedback?.cancel();
    }
  }

  void save() {
    widget.onSave();
    feedback?.cancel();
    setState(() => showHeart = true);
    feedback = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => showHeart = false);
    });
  }

  @override
  void dispose() {
    feedback?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.product.photos;
    final sources = photos.isEmpty ? <String?>[null] : photos;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AspectRatio(
        aspectRatio: 1,
        child: Stack(fit: StackFit.expand, children: [
          PageView.builder(
            key: ValueKey((widget.product.id, Object.hashAll(sources))),
            itemCount: sources.length,
            onPageChanged: (index) => setState(() => selected = index),
            itemBuilder: (context, index) => Semantics(
              button: true,
              label:
                  'عرض ${widget.product.name}، الصورة ${index + 1} من ${sources.length}',
              onTap: widget.onOpen,
              child: GestureDetector(
                excludeFromSemantics: true,
                onTap: widget.onOpen,
                onDoubleTap: save,
                child: ProductPhoto(
                    product: widget.product, source: sources[index]),
              ),
            ),
          ),
          if (sources.length > 1)
            PositionedDirectional(
                top: 12,
                end: 12,
                child: IgnorePointer(
                    child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .62),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${selected + 1} / ${sources.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ))),
          IgnorePointer(
              child: Center(
                  child: AnimatedOpacity(
            opacity: showHeart ? 1 : 0,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 160),
            child: AnimatedScale(
              scale: showHeart ? 1 : .8,
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              child: const Icon(CupertinoIcons.heart_fill,
                  color: Colors.white,
                  size: 76,
                  shadows: [Shadow(blurRadius: 16, color: Colors.black38)]),
            ),
          ))),
        ]));
  }
}
