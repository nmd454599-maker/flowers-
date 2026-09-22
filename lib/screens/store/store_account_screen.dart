import 'package:flutter/material.dart';
import '../../widgets/app_components.dart';
import '../../core/app_theme.dart';
import '../../state/app_state.dart';
import '../auth/welcome_screen.dart';
import 'store_location_screen.dart';
import 'store_registration_screen.dart';
import 'store_payout_screen.dart';
import '../../widgets/store_profile_photo.dart';
import '../../models/models.dart';
import '../customer/store_details_screen.dart';
import 'store_videos_panel.dart';
import '../customer/customer_account_screen.dart';
import '../customer/notifications_screen.dart';
import '../shared/store_records_screen.dart';

class StoreAccountScreen extends StatelessWidget {
  final AppState state;
  const StoreAccountScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => StoreSettingsScreen(state: state);
}

class StoreSettingsScreen extends StatefulWidget {
  final AppState state;
  const StoreSettingsScreen({super.key, required this.state});
  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  int photoRevision = 0;
  bool acceptingOrders = true;
  bool savingSettings = false;
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final rows =
          await widget.state.repository.fetchAdminRecords('store_settings');
      final data = rows
          .where((r) => r.id == widget.state.user?.storeId)
          .firstOrNull
          ?.data;
      if (mounted)
        setState(() => acceptingOrders = data?['acceptingOrders'] != false);
    } catch (_) {
      if (mounted) _toast('تعذر تحميل إعدادات المتجر');
    }
  }

  Future<void> _setAccepting(bool value) async {
    setState(() => savingSettings = true);
    try {
      await widget.state.repository.saveAdminRecord(
          'store_settings',
          widget.state.user!.storeId,
          {'storeId': widget.state.user!.storeId, 'acceptingOrders': value});
      if (mounted) setState(() => acceptingOrders = value);
    } catch (_) {
      if (mounted) _toast('تعذر حفظ إعدادات المتجر');
    } finally {
      if (mounted) setState(() => savingSettings = false);
    }
  }

  static const groups = <String, List<StoreFeature>>{
    'هوية المتجر والتحقق': [
      StoreFeature(
          'بيانات المتجر القانونية',
          'الاسم التجاري، نوع النشاط والرقم الضريبي',
          Icons.verified_user_outlined),
      StoreFeature('وثائق التحقق', 'هوية المالك، إجازة العمل والحساب البنكي',
          Icons.folder_copy_outlined),
      StoreFeature('حالة التوثيق', 'عرض قرار المراجعة المسجل',
          Icons.workspace_premium_outlined)
    ],
    'الفروع والتوصيل': [
      StoreFeature('الفروع وساعات العمل', 'حفظ الفروع ومواعيد العمل',
          Icons.store_mall_directory_outlined),
      StoreFeature('مناطق ورسوم التوصيل', 'النطاق، الحد الأدنى وطاقة التوصيل',
          Icons.delivery_dining_outlined),
      StoreFeature('الخريطة وموقع الفروع', 'تحديد المواقع على خارطة العراق',
          Icons.map_outlined,
          map: true),
      StoreFeature('العطل والإغلاق المؤقت', 'الجدول الموسمي وأيام الذروة',
          Icons.event_busy_outlined)
    ],
    'التشغيل والإدارة': [
      StoreFeature('المخزون والمواد الخام',
          'الحجز، التلف والتنبيه عند انخفاض الكمية', Icons.inventory_outlined),
      StoreFeature('الموردون وأوامر الشراء', 'التكاليف وتواريخ الاستلام',
          Icons.local_shipping_outlined),
      StoreFeature('الموظفون والصلاحيات', 'مدير، تجهيز، محاسب ومندوب',
          Icons.groups_outlined),
      StoreFeature(
          'جدولة الطلبات والطاقة',
          'الساعات المتاحة والحد الأقصى للتجهيز',
          Icons.calendar_month_outlined),
      StoreFeature('الباقات والتخصيص', 'الورد، التغليف، البطاقة والإضافات',
          Icons.auto_awesome_outlined)
    ],
    'المالية والجودة': [
      StoreFeature(
          'بطاقة استلام الأموال',
          'إضافة بطاقة ائتمان أو حساب مصرفي للتسويات',
          Icons.credit_card_rounded),
      StoreFeature('المالية والتسويات', 'صافي الأرباح، العمولة والتحويلات',
          Icons.account_balance_wallet_outlined),
      StoreFeature('الفواتير وكشف الحساب', 'الدفع الإلكتروني وعند الاستلام',
          Icons.request_quote_outlined),
      StoreFeature('التقييمات وجودة الخدمة', 'تقييمات العملاء المسجلة',
          Icons.star_outline_rounded),
      StoreFeature('التقارير والتحليلات', 'المبيعات والعملاء والمنتجات',
          Icons.insights_outlined),
      StoreFeature('سجل النشاط والأمان', 'كل تعديل ومن نفذه ووقته',
          Icons.security_outlined)
    ],
    'الدعم والإعدادات': [
      StoreFeature('الإشعارات', 'طلبات، مخزون وتسويات',
          Icons.notifications_none_rounded),
      StoreFeature('الدعم ومركز المساعدة', 'تذكرة ومحادثة فريق أزهارنا',
          Icons.support_agent_rounded),
      StoreFeature('الشروط وسياسة المتاجر', 'الإلغاء والاسترجاع والجودة',
          Icons.gavel_outlined)
    ],
  };
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('إعدادات المتجر'), actions: [
        const ThemeModeButton(),
        IconButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NotificationsScreen(state: widget.state))),
            icon: const Icon(Icons.notifications_none_rounded))
      ]),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            StoreProfilePhoto(
                key: ValueKey(photoRevision),
                repository: widget.state.repository,
                storeId: widget.state.user?.storeId),
            const SizedBox(height: 16),
            _header(),
            const SizedBox(height: 12),
            _grid([
              _featureCard(
                icon: Icons.storefront_outlined,
                title: 'بروفايل متجري',
                subtitle: 'الصور والمنتجات والمعلومات والفيديوهات',
                onTap: _openPublicProfile,
              ),
              _featureCard(
                icon: Icons.video_library_outlined,
                title: 'فيديوهات المتجر',
                subtitle: 'إضافة المقاطع وإدارتها ومشاهدتها بالسحب',
                onTap: _openVideos,
              ),
            ]),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
                value: acceptingOrders,
                onChanged: savingSettings ? null : _setAccepting,
                title: Text(
                    acceptingOrders
                        ? 'المتجر يستقبل الطلبات'
                        : 'استقبال الطلبات متوقف',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('إيقاف مؤقت عند اكتمال طاقة التجهيز'),
                secondary: Icon(
                    acceptingOrders
                        ? Icons.check_circle_rounded
                        : Icons.pause_circle_rounded,
                    color: acceptingOrders ? Colors.green : Colors.orange),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18))),
            const SizedBox(height: 14),
            for (final entry in groups.entries) ...[
              _title(entry.key),
              _group(entry.value),
              const SizedBox(height: 14)
            ],
            OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل الخروج')),
          ]));
  Store? get _currentStore {
    final id = widget.state.user?.storeId;
    if (id == null || id.isEmpty) return null;
    for (final store in widget.state.stores) {
      if (store.id == id) return store;
    }
    return Store(
        id: id,
        name: widget.state.user!.name,
        city: widget.state.selectedCity,
        rating: 0,
        emoji: '🏪',
        minOrder: 0,
        deliveryMinutes: 0);
  }

  void _openPublicProfile() {
    final store = _currentStore;
    if (store == null) {
      _toast('أكمل تسجيل المتجر أولاً');
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                StoreDetailsScreen(store: store, state: widget.state)));
  }

  void _openVideos() {
    final store = _currentStore;
    if (store == null) {
      _toast('أكمل تسجيل المتجر أولاً');
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('فيديوهات المتجر')),
                body: StoreVideosPanel(
                    state: widget.state,
                    storeId: store.id,
                    storeName: store.name))));
  }

  Widget _header() => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF087E9A), Color(0xFF087E9A)]),
          borderRadius: BorderRadius.circular(26)),
      child: Row(children: [
        CircleAvatar(
            radius: 34,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: const Icon(Icons.local_florist_rounded,
                color: Color(0xFF087E9A), size: 35)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              widget.state.stores
                      .where((s) => s.id == widget.state.user?.storeId)
                      .firstOrNull
                      ?.name ??
                  widget.state.user?.name ??
                  'متجري',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const Text('إدارة بيانات المتجر وخدماته',
              style: TextStyle(color: Colors.white70)),
        ]))
      ]));
  Widget _title(String text) => Padding(
      padding: const EdgeInsets.all(6),
      child: Text(text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
  Widget _group(List<StoreFeature> items) => _grid([
        for (final item in items)
          _featureCard(
            icon: item.icon,
            title: item.title,
            subtitle: item.subtitle,
            onTap: () => _open(item),
          ),
      ]);

  Widget _grid(List<Widget> cards) => LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final columns = constraints.maxWidth < 300 ||
                  (textScale > 1.3 && constraints.maxWidth < 500)
              ? 1
              : constraints.maxWidth >= 720
                  ? 3
                  : 2;
          return Column(children: [
            for (var start = 0; start < cards.length; start += columns)
              Padding(
                padding: EdgeInsets.only(top: start == 0 ? 0 : 8),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var offset = 0; offset < columns; offset++) ...[
                        if (offset > 0) const SizedBox(width: 8),
                        Expanded(
                            child: start + offset < cards.length
                                ? cards[start + offset]
                                : const SizedBox.shrink()),
                      ],
                    ],
                  ),
                ),
              ),
          ]);
        },
      );

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: colors.primary, size: 20),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    textDirection: Directionality.of(context),
                    size: 16,
                    color: colors.onSurfaceVariant),
              ]),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, height: 1.3, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(StoreFeature f) async {
    Widget? linked;
    if ([
      'المالية والتسويات',
      'الفواتير وكشف الحساب',
      'التقييمات وجودة الخدمة',
      'التقارير والتحليلات',
      'سجل النشاط والأمان',
      'حالة التوثيق'
    ].contains(f.title)) {
      linked = StoreRecordsScreen(
          state: widget.state,
          title: f.title,
          storeId: widget.state.user!.storeId);
    } else if (f.title == 'الدعم ومركز المساعدة') {
      linked = CustomerAccountScreen(
          state: widget.state, title: 'المساعدة والشكاوى');
    } else if (f.title == 'الشروط وسياسة المتاجر') {
      linked = CustomerAccountScreen(
          state: widget.state, title: 'الشروط ومعلومات التطبيق');
    } else if (f.title == 'الإشعارات') {
      linked = NotificationsScreen(state: widget.state);
    }
    if (linked != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => linked!));
      return;
    }
    final page = f.title == 'بطاقة استلام الأموال'
        ? StorePayoutScreen(state: widget.state)
        : f.title == 'بيانات المتجر القانونية'
            ? StoreRegistrationScreen(state: widget.state)
            : f.map
                ? StoreLocationScreen(state: widget.state)
                : StoreFeatureScreen(state: widget.state, feature: f);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() => photoRevision++);
  }

  void _toast(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  Future<void> _logout() async {
    if (!await confirmLogout(context) || !mounted) return;
    await widget.state.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => WelcomeScreen(state: widget.state)),
        (_) => false);
  }
}

class StoreFeatureScreen extends StatefulWidget {
  final AppState state;
  final StoreFeature feature;
  const StoreFeatureScreen(
      {super.key, required this.state, required this.feature});
  @override
  State<StoreFeatureScreen> createState() => _StoreFeatureScreenState();
}

class _StoreFeatureScreenState extends State<StoreFeatureScreen> {
  bool enabled = true;
  bool loading = true, saving = false;
  String? error, selectedId;
  List<AdminRecord> records = [];
  String get scope => 'store_feature_${widget.feature.title}';
  String get storeId => widget.state.user!.storeId!;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await widget.state.repository.fetchAdminRecords(scope);
      records = all.where((r) => r.data['storeId'] == storeId).toList();
      if (selectedId != null) {
        final r = records.where((r) => r.id == selectedId).firstOrNull;
        if (r != null) _select(r);
      } else if (records.isNotEmpty) {
        _select(records.first);
      }
      error = null;
    } catch (_) {
      error = 'تعذر تحميل السجلات';
    }
    if (mounted) setState(() => loading = false);
  }

  void _select(AdminRecord r) {
    selectedId = r.id;
    title.text = '${r.data['title'] ?? ''}';
    reference.text = '${r.data['reference'] ?? ''}';
    notes.text = '${r.data['notes'] ?? ''}';
    enabled = r.data['enabled'] != false;
  }

  @override
  void dispose() {
    title.dispose();
    reference.dispose();
    notes.dispose();
    super.dispose();
  }

  final title = TextEditingController();
  final reference = TextEditingController();
  final notes = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.feature.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(18), children: [
              if (error != null)
                TextButton(
                    onPressed: _load, child: Text('$error — إعادة المحاولة')),
              for (final record in records)
                ListTile(
                    selected: selectedId == record.id,
                    title: Text('${record.data['title']}'),
                    subtitle: Text('${record.data['notes'] ?? ''}'),
                    onTap:
                        saving ? null : () => setState(() => _select(record))),
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24)),
                  child: Column(children: [
                    Icon(widget.feature.icon,
                        size: 48, color: const Color(0xFF087E9A)),
                    const SizedBox(height: 10),
                    Text(widget.feature.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    Text(widget.feature.subtitle, textAlign: TextAlign.center)
                  ])),
              const SizedBox(height: 18),
              SwitchListTile.adaptive(
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v),
                  title: const Text('تفعيل هذه الخدمة',
                      style: TextStyle(fontWeight: FontWeight.w800))),
              TextField(
                  controller: title,
                  decoration: const InputDecoration(
                      labelText: 'الاسم أو العنوان',
                      prefixIcon: Icon(Icons.edit_outlined))),
              const SizedBox(height: 12),
              TextField(
                  controller: reference,
                  decoration: const InputDecoration(
                      labelText: 'الهاتف أو الرقم المرجعي',
                      prefixIcon: Icon(Icons.numbers_rounded))),
              const SizedBox(height: 12),
              TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'ملاحظات وتفاصيل',
                      prefixIcon: Icon(Icons.notes_rounded))),
              const SizedBox(height: 18),
              FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ التغييرات')),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                  onPressed: saving ? null : _add,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة سجل جديد')),
            ]));
  void _toast(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  Future<void> _save() async {
    if (title.text.trim().isEmpty) {
      _toast('اكتب اسم السجل');
      return;
    }
    setState(() => saving = true);
    try {
      selectedId =
          await widget.state.repository.saveAdminRecord(scope, selectedId, {
        'storeId': storeId,
        'ownerId': widget.state.user!.id,
        'enabled': enabled,
        'title': title.text.trim(),
        'reference': reference.text.trim(),
        'notes': notes.text.trim(),
        'updatedAt': DateTime.now().toIso8601String()
      });
      await _load();
      if (mounted) _toast('تم حفظ السجل');
    } catch (_) {
      if (mounted) _toast('تعذر حفظ السجل؛ أعد المحاولة');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _add() => setState(() {
        selectedId = null;
        title.clear();
        reference.clear();
        notes.clear();
        enabled = true;
      });
}

class StoreFeature {
  final String title, subtitle;
  final IconData icon;
  final bool map;
  const StoreFeature(this.title, this.subtitle, this.icon, {this.map = false});
}
