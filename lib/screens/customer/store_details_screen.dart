import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/store_profile_photos.dart';
import '../../widgets/store_media_photos.dart';
import '../../widgets/store_category_strip.dart';
import '../../widgets/store_profile_photo.dart';
import '../store/store_products_screen.dart';
import 'store_reviews_panel.dart';
import '../../services/store_reviews_service.dart';
import '../../services/store_media_service.dart';
import '../store/store_videos_panel.dart';
import '../shared/store_chat_screen.dart';
import 'conversations_screen.dart';
import 'addresses_screen.dart';

class StoreDetailsScreen extends StatefulWidget {
  final Store store;
  final AppState state;
  final int initialTab;
  final VoidCallback? onBack, onOpenSettings;
  const StoreDetailsScreen(
      {super.key,
      required this.store,
      required this.state,
      this.onBack,
      this.onOpenSettings,
      this.initialTab = 0});
  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  late int tab = (widget.initialTab == 5 || widget.initialTab == 1)
      ? (owner ? 1 : 0)
      : widget.initialTab;
  String? selectedCategory, photo;
  Map<String, String> profile = {};
  bool loading = true,
      loadFailed = false,
      expandedBio = false,
      favorite = false,
      searching = false;
  String query = '';
  double? reviewRating;
  StoreMediaService get media => StoreMediaService(widget.state.repository);
  bool get owner =>
      widget.state.user?.role == UserRole.store &&
      widget.state.user?.storeId == widget.store.id;
  String get favoriteKey =>
      'favorite_store_${widget.state.user?.id ?? 'guest'}_${widget.store.id}';
  @override
  void initState() {
    super.initState();
    load();
    loadRating();
  }

  Future<void> loadRating() async {
    try {
      final reviews = await StoreReviewsService(widget.state.repository)
          .list(widget.store.id);
      if (mounted) {
        setState(() => reviewRating = reviews.isEmpty
            ? null
            : reviews.fold<double>(
                    0, (sum, r) => sum + (r.data['rating'] as num).toDouble()) /
                reviews.length);
      }
    } catch (_) {/* Store metadata remains available if reviews cannot load. */}
  }

  Future<void> load() async {
    try {
      final details = await media.profile(widget.store.id);
      final image =
          await widget.state.repository.fetchStoreProfilePhoto(widget.store.id);
      bool saved = false;
      try {
        saved = await SharedPreferencesAsync().getBool(favoriteKey) ?? false;
      } catch (_) {}
      if (mounted) {
        setState(() {
          profile = details;
          photo = image;
          favorite = saved;
          loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadFailed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> toggleFavorite() async {
    final next = !favorite;
    try {
      await SharedPreferencesAsync().setBool(favoriteKey, next);
      if (mounted) setState(() => favorite = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر حفظ المتجر، حاول مجددًا')));
      }
    }
  }

  Future<void> edit() async {
    final result = await showModalBottomSheet<Map<String, String>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _ProfileEditor(data: profile));
    if (result == null || !mounted) return;
    try {
      await media.saveProfile(widget.state.user, widget.store.id, result);
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر حفظ المعلومات، حاول مجددًا')));
      }
    }
  }

  void chat() {
    final user = widget.state.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سجّل الدخول للتواصل مع المتجر')));
      return;
    }
    if (user.role != UserRole.customer) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ConversationsScreen(state: widget.state)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  StoreChatScreen(state: widget.state, conversation: {
                    'storeId': widget.store.id,
                    'storeName': widget.store.name,
                    'customerId': user.id,
                    'customerName': user.name,
                  })));
    }
  }

  Widget avatar() {
    Widget fallback() => Container(
        color: const Color(0xFFF1F4ED),
        child: const Icon(Icons.storefront_outlined,
            size: 36, color: Color(0xFF80946D)));
    final source = photo;
    return ClipOval(
        child: SizedBox(
            width: 68,
            height: 68,
            child: source == null || source.isEmpty
                ? fallback()
                : source.startsWith('data:')
                    ? Image.memory(UriData.parse(source).contentAsBytes(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => fallback())
                    : Image.network(source,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => fallback())));
  }

  Widget header() {
    final store = widget.store;
    final bio = profile['description'] ?? '';
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (owner)
              Tooltip(
                message: 'تغيير صورة المتجر',
                child: Semantics(
                  button: true,
                  label: 'تغيير صورة المتجر',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _editStorePhoto,
                    child: avatar(),
                  ),
                ),
              )
            else
              avatar(),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(store.name,
                      style: const TextStyle(
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                      bio.isEmpty
                          ? 'ورود وهدايا ومنتجات من ${store.name} في ${store.city}'
                          : bio,
                      maxLines: expandedBio ? null : 3,
                      overflow: expandedBio ? null : TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13)),
                  if (bio.length > 100)
                    InkWell(
                        onTap: () => setState(() => expandedBio = !expandedBio),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(expandedBio ? 'أقل' : 'المزيد',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)))),
                  const SizedBox(height: 8),
                  Wrap(spacing: 5, runSpacing: 5, children: [
                    _Badge(store.city, const Color(0xFFE77F89)),
                    const _Badge('توصيل الطلبات', Colors.grey),
                  ]),
                ])),
          ]),
          if (loading)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator())
          else if (loadFailed)
            TextButton(
                onPressed: load,
                child:
                    const Text('تعذر تحميل معلومات المتجر • إعادة المحاولة')),
          const SizedBox(height: 22),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Metric((reviewRating ?? store.rating).toStringAsFixed(1),
                'التقييم / 5'),
            _Metric(
                '${widget.state.products.where((p) => p.storeId == store.id).length}',
                'المنتجات'),
            _Metric('${store.deliveryMinutes} د', 'مدة التوصيل'),
            _Metric('${store.minOrder}', 'أقل طلب / د.ع'),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF3C102F),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('التوصيل إلى بابك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            Expanded(
                child: TextButton.icon(
                    onPressed: toggleFavorite,
                    style: TextButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    icon: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                        color: favorite ? const Color(0xFFE77F89) : null),
                    label: Text(favorite ? 'متجر محفوظ' : 'حفظ المتجر',
                        style: const TextStyle(fontSize: 12)))),
          ]),
        ]));
  }

  Future<void> _editStorePhoto() async {
    if (!owner) return;
    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('صورة المتجر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              StoreProfilePhoto(
                  repository: widget.state.repository,
                  storeId: widget.store.id),
            ])));
    if (mounted) await load();
  }

  Future<void> _manageProductPhotos() async {
    if (!owner) return;
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => StoreProductsScreen(state: widget.state)));
    if (mounted) setState(() {});
  }

  Widget products() {
    final all = widget.state.products
        .where((p) => p.storeId == widget.store.id)
        .toList();
    final categories = all.map((p) => p.category).toSet().toList();
    final activeCategory =
        categories.contains(selectedCategory) ? selectedCategory : null;
    final items = all
        .where((p) =>
            (activeCategory == null || p.category == activeCategory) &&
            (query.trim().isEmpty ||
                p.name.toLowerCase().contains(query.trim().toLowerCase())))
        .toList();
    return CustomScrollView(
        key: const PageStorageKey('store-products-profile'),
        slivers: [
          SliverToBoxAdapter(child: header()),
          if (searching)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                        autofocus: true,
                        onChanged: (value) => setState(() => query = value),
                        decoration: const InputDecoration(
                            hintText: 'ابحث داخل المتجر',
                            prefixIcon: Icon(Icons.search))))),
          SliverToBoxAdapter(
              child: StoreCategoryStrip(
                  products: all,
                  selectedCategory: activeCategory,
                  onSelected: (category) =>
                      setState(() => selectedCategory = category))),
          const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 14),
                  child: Text('مختارات المتجر',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)))),
          if (items.isEmpty)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('لا توجد منتجات متاحة في هذا القسم',
                        textAlign: TextAlign.center)))
          else
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: StoreProfilePhotos(
                        products: items, state: widget.state))),
          SliverToBoxAdapter(child: mediaGallery(items, manage: false)),
        ]);
  }

  Widget mediaGallery(List<Product> items, {required bool manage}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (manage && owner)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: FilledButton.icon(
              onPressed: _manageProductPhotos,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('رفع صور المنتجات'),
            ),
          ),
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('صور المنتجات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        StoreMediaPhotos(products: items),
        const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text('فيديوهات المتجر',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        StoreVideosPanel(
            state: widget.state,
            storeId: widget.store.id,
            storeName: widget.store.name,
            inline: true,
            showManagement: manage),
        const SizedBox(height: 24),
      ]);

  Widget mediaPage() =>
      ListView(key: const PageStorageKey('store-unified-media'), children: [
        mediaGallery(
            widget.state.products
                .where((p) => p.storeId == widget.store.id)
                .toList(),
            manage: true)
      ]);
  Widget about() => ListView(padding: const EdgeInsets.all(16), children: [
        Text('عن ${widget.store.name}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        for (final (label, value) in [
          ('نبذة عن المتجر', profile['description'] ?? ''),
          ('المحافظة', widget.store.city),
          ('العنوان', profile['address'] ?? ''),
          ('ساعات العمل', profile['hours'] ?? ''),
          ('الهاتف', profile['phone'] ?? ''),
          ('الحد الأدنى للطلب', '${widget.store.minOrder} د.ع'),
          ('مدة التوصيل التقريبية', '${widget.store.deliveryMinutes} دقيقة'),
        ])
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label),
              subtitle: Text(
                  value.isEmpty ? 'لم يضف المتجر هذه المعلومة بعد' : value)),
        if (owner)
          FilledButton.icon(
              onPressed: edit,
              icon: const Icon(Icons.edit),
              label: const Text('تعديل معلومات المتجر')),
      ]);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) => Scaffold(
            appBar: owner && tab == 2
                ? null
                : AppBar(
                    leading: widget.onBack == null
                        ? null
                        : IconButton(
                            tooltip: 'لوحة المتجر',
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back)),
                    title: InkWell(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    AddressesScreen(state: widget.state))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('التوصيل إلى',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                              Text(widget.state.selectedCity,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ])),
                    actions: [
                        if (widget.onOpenSettings != null)
                          IconButton(
                              tooltip: 'إعدادات المتجر',
                              onPressed: widget.onOpenSettings,
                              icon: const Icon(Icons.settings_outlined)),
                        IconButton(
                            tooltip: 'بحث في المتجر',
                            onPressed: () => setState(() {
                                  tab = 0;
                                  searching = !searching;
                                  if (!searching) query = '';
                                }),
                            icon: const Icon(Icons.search)),
                        IconButton(
                            tooltip: 'نسخ معلومات المتجر',
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(
                                  text:
                                      '${widget.store.name}\n${widget.store.city}\n${profile['address'] ?? ''}\n${profile['phone'] ?? ''}'));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('تم نسخ معلومات المتجر')));
                              }
                            },
                            icon: const Icon(Icons.ios_share)),
                      ]),
            body: switch (tab) {
              1 => mediaPage(),
              2 => owner
                  ? StoreChatInboxScreen(state: widget.state, embedded: true)
                  : products(),
              3 => StoreReviewsPanel(
                  state: widget.state,
                  storeId: widget.store.id,
                  onSaved: loadRating),
              4 => about(),
              _ => products(),
            },
            bottomNavigationBar: SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                          top: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant))),
                  child: Row(children: [
                    for (final (i, label, icon) in [
                      (0, 'المنتجات', Icons.shopping_bag_outlined),
                      if (owner)
                        (1, 'الصور والفيديوهات', Icons.perm_media_outlined),
                      (
                        2,
                        owner ? 'المحادثات' : 'محادثة',
                        Icons.chat_bubble_outline
                      ),
                      (3, 'التقييمات', Icons.star_border),
                      (4, 'عن المتجر', Icons.verified_user_outlined),
                    ])
                      Expanded(
                          child: InkWell(
                        onTap: () {
                          if (i == 2 && !owner) {
                            chat();
                          } else {
                            setState(() => tab = i);
                          }
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            color: tab == i
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow
                                : null,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon,
                                      size: 24,
                                      color: tab == i
                                          ? const Color(0xFF714161)
                                          : Colors.grey),
                                  const SizedBox(height: 4),
                                  Text(label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: tab == i
                                              ? FontWeight.w700
                                              : FontWeight.w400)),
                                ])),
                      )),
                  ]),
                )),
          ));
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)));
}

class _Metric extends StatelessWidget {
  final String value, label;
  const _Metric(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
          child: Column(children: [
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]));
}

class _ProfileEditor extends StatefulWidget {
  final Map<String, String> data;
  const _ProfileEditor({required this.data});
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final fields = {
    for (final key in ['description', 'address', 'hours', 'phone'])
      key: TextEditingController(text: widget.data[key] ?? '')
  };
  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('معلومات المتجر',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          for (final (key, label) in [
            ('description', 'نبذة عن المتجر'),
            ('address', 'العنوان'),
            ('hours', 'ساعات العمل'),
            ('phone', 'رقم الهاتف')
          ])
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                    controller: fields[key],
                    maxLines: key == 'description' ? 3 : 1,
                    maxLength: key == 'description' ? 1500 : 200,
                    decoration: InputDecoration(labelText: label))),
          FilledButton(
              onPressed: () => Navigator.pop(context, {
                    for (final entry in fields.entries)
                      entry.key: entry.value.text
                  }),
              child: const Text('حفظ المعلومات')),
        ]),
      ));
}
