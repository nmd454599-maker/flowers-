import 'dart:typed_data';

/// Keeps stable MemoryImage keys across rebuilds, with bounded memory use.
class InlineImageCache {
  InlineImageCache({this.maxBytes = 8 * 1024 * 1024, this.maxEntries = 32});
  static final shared = InlineImageCache();
  final int maxBytes;
  final int maxEntries;
  final _entries = <String, Uint8List>{};
  int _bytes = 0;

  Uint8List decode(String source) {
    final cached = _entries.remove(source);
    if (cached != null) {
      _entries[source] = cached;
      return cached;
    }
    final data = UriData.parse(source);
    if (!data.mimeType.startsWith('image/')) {
      throw const FormatException('Expected image data');
    }
    final bytes = data.contentAsBytes();
    // Include the retained UTF-16 source in the cache budget.
    final cost = source.length * 2 + bytes.length;
    if (cost > maxBytes || maxEntries <= 0) return bytes;
    while (_entries.isNotEmpty &&
        (_bytes + cost > maxBytes || _entries.length >= maxEntries)) {
      final oldest = _entries.keys.first;
      _bytes -= oldest.length * 2 + _entries.remove(oldest)!.length;
    }
    _entries[source] = bytes;
    _bytes += cost;
    return bytes;
  }
}
