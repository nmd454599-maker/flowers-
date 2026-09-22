import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/inline_image_cache.dart';

void main() {
  const a = 'data:image/png;base64,AQID';
  const b = 'data:image/png;base64,BAUG';
  test('rebuilds reuse the same bytes for Flutter image cache keys', () {
    final cache = InlineImageCache();
    expect(identical(cache.decode(a), cache.decode(a)), isTrue);
    expect(cache.decode(a), [1, 2, 3]);
  });
  test('evicts old entries and never retains oversized images', () {
    final cache = InlineImageCache(maxEntries: 1);
    final first = cache.decode(a);
    cache.decode(b);
    expect(identical(first, cache.decode(a)), isFalse);
    final tiny = InlineImageCache(maxBytes: 1);
    expect(identical(tiny.decode(a), tiny.decode(a)), isFalse);
  });
  test('rejects non-image and malformed data', () {
    final cache = InlineImageCache();
    expect(() => cache.decode('data:text/plain,hello'), throwsFormatException);
    expect(
        () => cache.decode('data:image/png;base64,***'), throwsFormatException);
  });
}
