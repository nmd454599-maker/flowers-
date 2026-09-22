import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// All bundled user/design images, discovered from Flutter's asset manifest.
class ImageLibraryScreen extends StatefulWidget {
  const ImageLibraryScreen({super.key, this.selectImage = false});
  final bool selectImage;
  @override
  State<ImageLibraryScreen> createState() => _ImageLibraryScreenState();
}

class _ImageLibraryScreenState extends State<ImageLibraryScreen> {
  late final images =
      AssetManifest.loadFromAssetBundle(rootBundle).then((manifest) {
    final paths = manifest
        .listAssets()
        .where((p) =>
            p.startsWith('assets/images/') &&
            RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false).hasMatch(p))
        .toList()
      ..sort();
    return paths;
  });
  bool catalogOnly = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.selectImage ? 'اختر صورة' : 'معرض الصور')),
        body: FutureBuilder<List<String>>(
          future: images,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Center(child: Text('تعذر تحميل الصور'));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final all = snapshot.data!;
            final visible = all
                .where((p) => !catalogOnly || p.contains('/catalog/'))
                .toList();
            return Column(children: [
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    ChoiceChip(
                        label: Text('الكل (${all.length})'),
                        selected: !catalogOnly,
                        onSelected: (_) => setState(() => catalogOnly = false)),
                    const SizedBox(width: 8),
                    Flexible(
                        child: ChoiceChip(
                            label: const Text('صور المنتجات'),
                            selected: catalogOnly,
                            onSelected: (_) =>
                                setState(() => catalogOnly = true))),
                  ])),
              Expanded(
                  child: GridView.builder(
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2),
                itemCount: visible.length,
                itemBuilder: (context, index) => Semantics(
                  button: true,
                  label: 'صورة ${index + 1}',
                  child: InkWell(
                    onTap: () => widget.selectImage
                        ? Navigator.pop(context, visible[index])
                        : Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => _ImageViewer(
                                    images: visible, initialIndex: index))),
                    child: Image.asset(visible[index],
                        fit: BoxFit.cover,
                        cacheWidth:
                            (200 * MediaQuery.devicePixelRatioOf(context))
                                .ceil()),
                  ),
                ),
              )),
            ]);
          },
        ),
      );
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.images, required this.initialIndex});
  final List<String> images;
  final int initialIndex;
  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final pages = PageController(initialPage: widget.initialIndex);
  late int index = widget.initialIndex;
  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('${index + 1} / ${widget.images.length}')),
        body: PageView.builder(
            controller: pages,
            itemCount: widget.images.length,
            onPageChanged: (value) => setState(() => index = value),
            itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                    child:
                        Image.asset(widget.images[i], fit: BoxFit.contain)))),
      );
}

class ImageLibraryButton extends StatelessWidget {
  const ImageLibraryButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'معرض الصور',
        icon: const Icon(Icons.photo_library_outlined),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ImageLibraryScreen())),
      );
}
