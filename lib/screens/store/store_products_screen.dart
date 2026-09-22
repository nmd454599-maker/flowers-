import 'store_product_album.dart';
import '../shared/image_library_screen.dart';
import 'dart:convert';
import '../../widgets/product_photo.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_components.dart';

class StoreProductsScreen extends StatefulWidget {
  final AppState state;
  const StoreProductsScreen({super.key, required this.state});
  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  AppState get state => widget.state;
  bool loading = true;
  bool loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      loading = true;
      loadFailed = false;
    });
    try {
      await state.loadCatalog();
    } catch (_) {
      if (mounted) setState(() => loadFailed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  static const categories = [
    'الكل',
    'ورود',
    'هدايا',
    'حلويات',
    'عطور',
    'إكسسوارات'
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('ألبوم منتجات المتجر'), actions: [
            IconButton(
                tooltip: 'تحديث المنتجات',
                onPressed: loading ? null : _loadProducts,
                icon: const Icon(Icons.refresh_rounded)),
          ]),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : loadFailed
                  ? AppEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'تعذر تحميل المنتجات',
                      message: 'تحقق من الاتصال ثم أعد المحاولة',
                      action: FilledButton(
                          onPressed: _loadProducts,
                          child: const Text('إعادة المحاولة')))
                  : state.user?.storeId == null || state.user!.storeId!.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'الحساب غير مرتبط بمتجر',
                          message:
                              'أكمل تسجيل المتجر وربطه بالحساب لعرض منتجاته')
                      : StoreProductAlbum(
                          products: state.products
                              .where((p) => p.storeId == state.user?.storeId)
                              .toList(),
                          onAdd: () => _editor(context),
                          onEdit: (product) =>
                              _editor(context, product: product),
                        ),
        ),
      );
  void _editor(BuildContext context, {Product? product}) {
    final nameController = TextEditingController(text: product?.name);
    final priceController =
        TextEditingController(text: product?.price.toString());
    final stockController = TextEditingController(
        text: RegExp(r'المخزون:\s*(.*)$')
                .firstMatch(product?.description ?? '')
                ?.group(1) ??
            '');
    final skuController = TextEditingController(
        text: RegExp(r'^SKU:\s*(.*?)\s*•')
                .firstMatch(product?.description ?? '')
                ?.group(1) ??
            '');
    String category = product?.category ?? 'ورود';
    final images = <String>[...?product?.photos];
    bool saving = false;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => StatefulBuilder(
            builder: (context, setSheetState) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
                  child: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        Text(product == null ? 'إضافة منتج' : 'تعديل المنتج',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.collections_outlined),
                          label: const Text('اختيار من صور أزهارنا'),
                          onPressed: saving || images.length >= 10
                              ? null
                              : () async {
                                  final image = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ImageLibraryScreen(
                                                  selectImage: true)));
                                  if (!context.mounted || image == null) return;
                                  if (!images.contains(image))
                                    setSheetState(() => images.add(image));
                                },
                        ),
                        OutlinedButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  try {
                                    final picked = await ImagePicker()
                                        .pickMultiImage(
                                            imageQuality: 85, maxWidth: 1600);
                                    if (!context.mounted) return;
                                    if (images.length + picked.length > 10) {
                                      _toast(context,
                                          'يمكن إضافة 10 صور كحد أقصى');
                                      return;
                                    }
                                    final additions = <String>[];
                                    for (final file in picked) {
                                      final bytes = await file.readAsBytes();
                                      if (bytes.length >= 5 * 1024 * 1024) {
                                        if (context.mounted) {
                                          _toast(context,
                                              'كل صورة يجب أن تكون أصغر من 5 ميغابايت');
                                        }
                                        return;
                                      }
                                      final mime = file.name
                                              .toLowerCase()
                                              .endsWith('.png')
                                          ? 'image/png'
                                          : 'image/jpeg';
                                      additions.add(
                                          'data:$mime;base64,${base64Encode(bytes)}');
                                    }
                                    if (context.mounted) {
                                      setSheetState(
                                          () => images.addAll(additions));
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      _toast(context,
                                          'تعذر اختيار الصور، حاول مرة أخرى');
                                    }
                                  }
                                },
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text('إضافة صور المنتج (${images.length}/10)'),
                        ),
                        if (images.isNotEmpty) ...[
                          const Text(
                              'الصورة الأولى هي الرئيسية. اضغط النجمة لجعل أي صورة رئيسية.'),
                          SizedBox(
                              height: 132,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) => SizedBox(
                                    width: 100,
                                    child: Column(children: [
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: ProductPhoto(
                                              product: product ??
                                                  const Product(
                                                      id: '',
                                                      storeId: '',
                                                      name: 'صورة المنتج',
                                                      category: '',
                                                      price: 0,
                                                      emoji: '',
                                                      rating: 0,
                                                      description: ''),
                                              source: images[index],
                                              width: 100,
                                              height: 80)),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                                tooltip: 'جعل الصورة رئيسية',
                                                onPressed: saving
                                                    ? null
                                                    : () => setSheetState(() {
                                                          final image = images
                                                              .removeAt(index);
                                                          images.insert(
                                                              0, image);
                                                        }),
                                                icon: Icon(index == 0
                                                    ? Icons.star
                                                    : Icons.star_border)),
                                            IconButton(
                                                tooltip: 'حذف الصورة',
                                                onPressed: saving
                                                    ? null
                                                    : () => setSheetState(() {
                                                          images
                                                              .removeAt(index);
                                                        }),
                                                icon: const Icon(Icons.close)),
                                          ]),
                                    ])),
                              )),
                        ],
                        const SizedBox(height: 10),
                        TextField(
                            controller: nameController,
                            decoration:
                                const InputDecoration(labelText: 'اسم المنتج')),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration:
                                const InputDecoration(labelText: 'التصنيف'),
                            items: {...categories.skip(1), category}
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) =>
                                setSheetState(() => category = v ?? category)),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child: TextField(
                                  controller: priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'السعر'))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: TextField(
                                  controller: stockController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'المخزون')))
                        ]),
                        const SizedBox(height: 10),
                        TextField(
                            controller: skuController,
                            decoration: const InputDecoration(
                                labelText: 'SKU / الباركود')),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    final productName =
                                        nameController.text.trim();
                                    final price = int.tryParse(
                                        priceController.text.trim());
                                    if (productName.isEmpty ||
                                        price == null ||
                                        price <= 0) {
                                      _toast(context,
                                          'أدخل اسم المنتج والسعر بصورة صحيحة');
                                      return;
                                    }
                                    setSheetState(() => saving = true);
                                    try {
                                      final storeId =
                                          state.user?.storeId ?? 's1';
                                      final imageUrls = <String>[];
                                      for (var index = 0;
                                          index < images.length;
                                          index++) {
                                        final image = images[index];
                                        if (image.startsWith('data:')) {
                                          final data = UriData.parse(image);
                                          final url = await state.repository
                                              .saveProductImage(
                                                  storeId: storeId,
                                                  bytes: data.contentAsBytes(),
                                                  fileName: data.mimeType ==
                                                          'image/png'
                                                      ? 'product.png'
                                                      : 'product.jpg');
                                          images[index] = url;
                                          imageUrls.add(url);
                                        } else {
                                          imageUrls.add(image);
                                        }
                                      }
                                      final savedProduct = Product(
                                          id: product?.id ??
                                              'merchant_${DateTime.now().microsecondsSinceEpoch}',
                                          storeId: storeId,
                                          name: productName,
                                          category: category,
                                          price: price,
                                          emoji: category == 'عطور'
                                              ? '🧴'
                                              : category == 'إكسسوارات'
                                                  ? '⌚'
                                                  : '💐',
                                          rating: product?.rating ?? 0,
                                          description:
                                              'SKU: ${skuController.text.trim()} • المخزون: ${stockController.text.trim()}',
                                          imageUrl: imageUrls.isEmpty
                                              ? null
                                              : imageUrls.first,
                                          imageUrls: imageUrls);
                                      await state
                                          .saveStoreProduct(savedProduct);
                                    } catch (_) {
                                      if (context.mounted) {
                                        setSheetState(() => saving = false);
                                        _toast(context,
                                            'تعذر رفع الصورة أو حفظ المنتج، حاول مرة أخرى');
                                      }
                                      return;
                                    }
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    _toast(context,
                                        'تم حفظ المنتج فعليًا ضمن قسم $category');
                                  },
                            icon: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.save_outlined),
                            label:
                                Text(saving ? 'جارٍ الحفظ...' : 'حفظ المنتج')),
                      ])),
                )));
  }

  void _toast(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
