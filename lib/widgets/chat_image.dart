import 'package:flutter/material.dart';

class ChatImage extends StatelessWidget {
  final String source;
  const ChatImage({super.key, required this.source});
  @override
  Widget build(BuildContext context) {
    Widget failed() => const SizedBox(
        height: 100, child: Center(child: Text('تعذر عرض الصورة')));
    try {
      if (source.startsWith('data:image/')) {
        return Image.memory(UriData.parse(source).contentAsBytes(),
            fit: BoxFit.contain, errorBuilder: (_, __, ___) => failed());
      }
      if (source.startsWith('assets/images/')) {
        return Image.asset(source,
            fit: BoxFit.contain, errorBuilder: (_, __, ___) => failed());
      }
      if (source.startsWith('https://')) {
        return Image.network(source,
            fit: BoxFit.contain, errorBuilder: (_, __, ___) => failed());
      }
    } catch (_) {
      return failed();
    }
    return failed();
  }
}
