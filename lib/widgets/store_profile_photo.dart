import '../core/inline_image_cache.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/app_repository.dart';

class StoreProfilePhoto extends StatefulWidget {
  const StoreProfilePhoto(
      {super.key,
      required this.repository,
      required this.storeId,
      this.chooseImage});
  final AppRepository repository;
  final String? storeId;
  final Future<XFile?> Function()? chooseImage;
  @override
  State<StoreProfilePhoto> createState() => _StoreProfilePhotoState();
}

class _StoreProfilePhotoState extends State<StoreProfilePhoto> {
  String? photo;
  bool loading = true, busy = false, loadFailed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StoreProfilePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeId != widget.storeId ||
        oldWidget.repository != widget.repository) {
      photo = null;
      loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.storeId;
    try {
      final value = id == null || id.isEmpty
          ? null
          : await widget.repository.fetchStoreProfilePhoto(id);
      if (mounted && widget.storeId == id) {
        setState(() {
          photo = value;
          loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted && widget.storeId == id) setState(() => loadFailed = true);
    } finally {
      if (mounted && widget.storeId == id) setState(() => loading = false);
    }
  }

  Future<void> _pick() async {
    final id = widget.storeId;
    if (busy || id == null || id.isEmpty) return;
    setState(() => busy = true);
    try {
      final file = await (widget.chooseImage?.call() ??
          ImagePicker().pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
              maxWidth: 1200,
              maxHeight: 1200));
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length >= 5 * 1024 * 1024) {
        throw StateError('اختر صورة أصغر من 5 ميغابايت');
      }
      // Decode before saving so a non-image cannot replace the current photo.
      final decoded = await decodeImageFromList(bytes);
      decoded.dispose();
      if (!mounted || widget.storeId != id) return;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('صورة المتجر'),
                content: SizedBox(
                    width: 280,
                    height: 240,
                    child: Image.memory(bytes, fit: BoxFit.contain)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('حفظ الصورة'))
                ],
              ));
      if (confirmed != true || !mounted || widget.storeId != id) return;
      final value = await widget.repository.saveStoreProfilePhoto(
          storeId: id, bytes: bytes, fileName: file.name);
      if (!mounted || widget.storeId != id) return;
      setState(() {
        photo = value;
        loadFailed = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ صورة المتجر')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'تعذر حفظ الصورة. اختر صورة صالحة أصغر من 5 ميغابايت وحاول مجدداً.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _image() {
    const fallback = Icon(Icons.storefront_rounded, size: 48);
    if (photo == null) return fallback;
    try {
      if (photo!.startsWith('data:')) {
        return Image.memory(InlineImageCache.shared.decode(photo!),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => fallback);
      }
      return Image.network(photo!,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => fallback);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Semantics(
            label: 'صورة الملف التعريفي للمتجر',
            image: true,
            child: ClipOval(
                child: Container(
                    width: 104,
                    height: 104,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: loading || busy
                        ? const Center(child: CircularProgressIndicator())
                        : _image()))),
        const SizedBox(height: 8),
        if (loadFailed)
          TextButton(
              onPressed: loading || busy ? null : _load,
              child: const Text('إعادة تحميل الصورة')),
        TextButton.icon(
            onPressed: loading ||
                    busy ||
                    widget.storeId == null ||
                    widget.storeId!.isEmpty
                ? null
                : _pick,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(busy
                ? 'جارٍ تجهيز الصورة…'
                : photo == null
                    ? 'إضافة صورة المتجر'
                    : 'تغيير صورة المتجر')),
        if (widget.storeId == null || widget.storeId!.isEmpty)
          const Text('اربط الحساب بمتجرك أولاً', textAlign: TextAlign.center),
      ]);
}
