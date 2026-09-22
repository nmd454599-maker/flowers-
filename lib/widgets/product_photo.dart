import 'package:flutter/material.dart';

import '../core/product_assets.dart';
import '../core/inline_image_cache.dart';
import '../models/models.dart';
import '../services/local_product_images.dart';

/// Uses the merchant's saved photo consistently across customer screens.
class ProductPhoto extends StatelessWidget {
  final Product product;
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Keep source pixels available in the zoomable viewer.
  final bool originalResolution;

  const ProductPhoto({
    super.key,
    required this.product,
    this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.originalResolution = false,
  });

  Widget _fallback(int? cacheWidth) => Image.asset(
        productImage(product.id),
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        semanticLabel: product.name,
        cacheWidth: cacheWidth,
        frameBuilder: _frame,
      );

  Widget _frame(
      BuildContext context, Widget child, int? frame, bool synchronous) {
    if (synchronous) return child;
    final ready = frame != null;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: AnimatedOpacity(
        opacity: ready ? 1 : 0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final logicalWidth = width?.isFinite == true
            ? width!
            : constraints.hasBoundedWidth
                ? constraints.maxWidth
                : 384.0;
        final cacheWidth = originalResolution
            ? null
            : ((logicalWidth * MediaQuery.devicePixelRatioOf(context) / 64)
                        .ceil() *
                    64)
                .clamp(64, 8192);
        return _image(cacheWidth);
      });

  Widget _image(int? cacheWidth) {
    final source =
        this.source ?? (product.photos.isEmpty ? '' : product.photos.first);
    if (source.isEmpty) return _fallback(cacheWidth);
    Widget onError(BuildContext context, Object error, StackTrace? stack) =>
        _fallback(cacheWidth);
    final local = localProductImage(source);
    if (local != null) {
      return Image(
          image: ResizeImage.resizeIfNeeded(cacheWidth, null, local),
          width: width,
          height: height,
          fit: fit,
          filterQuality: FilterQuality.high,
          semanticLabel: product.name,
          frameBuilder: _frame,
          errorBuilder: onError);
    }
    if (source.startsWith('assets/')) {
      return Image.asset(source,
          cacheWidth: cacheWidth,
          width: width,
          height: height,
          fit: fit,
          filterQuality: FilterQuality.high,
          semanticLabel: product.name,
          frameBuilder: _frame,
          errorBuilder: onError);
    }
    if (source.startsWith('data:')) {
      try {
        final bytes = InlineImageCache.shared.decode(source);
        return Image.memory(bytes,
            cacheWidth: cacheWidth,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.high,
            semanticLabel: product.name,
            frameBuilder: _frame,
            errorBuilder: onError);
      } on FormatException {
        return _fallback(cacheWidth);
      }
    }
    final uri = Uri.tryParse(source);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return _fallback(cacheWidth);
    }
    return Image.network(source,
        cacheWidth: cacheWidth,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        semanticLabel: product.name,
        frameBuilder: _frame,
        errorBuilder: onError);
  }
}
