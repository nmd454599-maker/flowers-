import '../shared/live_conversations_screen.dart';
import '../shared/store_chat_screen.dart';
import '../shared/store_records_screen.dart';
import '../customer/notifications_screen.dart';
import 'customer_requests_screen.dart';
import '../shared/image_library_screen.dart';
import '../../widgets/glass_panel.dart';
import '../../domain/orders/order_transitions.dart';
import '../../data/firebase_repository.dart';
import '../../data/sqlite_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import '../../widgets/app_components.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../auth/welcome_screen.dart';
import 'admin_tools_screen.dart';
import 'admin_products_screen.dart';
import 'admin_entity_details_screen.dart';
import 'store_applications_screen.dart';

class AdminShell extends StatefulWidget {
  final AppState state;
  const AdminShell({super.key, required this.state});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    unawaited(widget.state.loadAdminData().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(
          state: widget.state,
          onNavigate: (value) => setState(() => index = value)),
      _Stores(state: widget.state),
      _AdminOrders(state: widget.state),
      AdminUsersPanel(state: widget.state),
      _AdminAccount(state: widget.state),
    ];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'إجراءات الإدارة',
        icon: const Icon(Icons.add),
        label: const Text('إجراءات'),
        onPressed: () => showModalBottomSheet<void>(
            context: context,
            useSafeArea: true,
            showDragHandle: true,
            builder: (sheetContext) {
              Widget action(String title, IconData icon, Widget page) =>
                  ListTile(
                    leading: Icon(icon),
                    title: Text(title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => page));
                    },
                  );
              return SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (widget.state.repository is! FirebaseRepository) ...[
                  action(
                      'سجلات المتاجر',
                      Icons.folder_open_outlined,
                      StoreRecordsScreen(
                          state: widget.state, title: 'سجلات المتاجر')),
                  action('محادثات العملاء والمتاجر', Icons.chat_outlined,
                      StoreChatInboxScreen(state: widget.state)),
                ],
                action('طلبات العملاء والانضمام', Icons.support_agent_outlined,
                    CustomerRequestsScreen(state: widget.state)),
                if (widget.state.repository is FirebaseRepository)
                  action('محادثات الدعم', Icons.chat_outlined,
                      LiveConversationsScreen(state: widget.state)),
                action('معرض الصور', Icons.photo_library_outlined,
                    const ImageLibraryScreen()),
                const SizedBox(height: 16),
              ]));
            }),
      ),
      body: AnimatedTabBody(index: index, children: pages),
      bottomNavigationBar: FloatingNavigation(
          selectedIndex: index,
          onSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined), label: 'الرئيسية'),
            NavigationDestination(
                icon: Icon(Icons.storefront_outlined), label: 'المتاجر'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined), label: 'الطلبات'),
            NavigationDestination(
                icon: Icon(Icons.group_outlined), label: 'المستخدمون'),
            NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                label: 'حسابي'),
          ]),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  const _AdminHeader(
      {required this.title, required this.subtitle, this.actions = const []});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13))
        ])),
        const ImageLibraryButton(),
        ...actions,
      ]));
}

class _Dashboard extends StatelessWidget {
  final AppState state;
  final ValueChanged<int> onNavigate;
  const _Dashboard({required this.state, required this.onNavigate});

  Widget _localDashboard(BuildContext context) => SafeArea(
          child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('لوحة الإدارة',
              style: Theme.of(context).textTheme.headlineMedium),
          const Text('بيانات الحسابات المحلية على هذا الهاتف'),
          ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('معرض الصور'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ImageLibraryScreen()))),
          for (final row in [
            ('المستخدمون', 'users', 3),
            ('المتاجر', 'stores', 1),
            ('الطلبات', 'orders', 2)
          ])
            Card(
                child: ListTile(
                    title: Text(row.$1),
                    trailing: Text('${state.adminMetrics[row.$2] ?? 0}'),
                    onTap: () => onNavigate(row.$3))),
          Card(
              child: ListTile(
                  title: const Text('قيمة الطلبات غير الملغاة'),
                  trailing:
                      Text('${_money(state.adminMetrics['grossSales'])} د.ع'))),
          ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('مراجعة المنتجات'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AdminProductsScreen(state: state)))),
          ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('الدعم وطلبات الانضمام'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CustomerRequestsScreen(state: state)))),
          ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('طلبات تسجيل المتاجر'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => StoreApplicationsScreen(state: state)))),
          ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('أدوات الإدارة'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AdminToolsScreen(state: state)))),
          OutlinedButton.icon(
              onPressed: state.busy
                  ? null
                  : () async {
                      try {
                        await state.loadAdminData();
                      } catch (_) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تعذر التحديث')));
                      }
                    },
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث البيانات')),
        ],
      ));

  @override
  Widget build(BuildContext context) => state.repository is SqliteRepository
      ? _localDashboard(context)
      : SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([state.loadCatalog(), state.loadAdminData()]);
            },
            child: ListView(padding: EdgeInsets.zero, children: [
              _AdminHeader(
                  title: 'لوحة التحكم',
                  subtitle: 'مرحباً، سوبر أدمن أزهارنا',
                  actions: [
                    Badge(
                        isLabelVisible: state.unreadNotifications > 0,
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        child: IconButton(
                            tooltip: 'الإشعارات',
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        NotificationsScreen(state: state))),
                            icon:
                                const Icon(Icons.notifications_none_rounded))),
                    const SizedBox(width: 9),
                    IconButton(
                        tooltip: 'المنتجات والبحث',
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    AdminProductsScreen(state: state))),
                        icon: const Icon(Icons.search_rounded)),
                  ]),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: const Color(0xFF173D40),
                        borderRadius: BorderRadius.circular(26)),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('إجمالي المبيعات',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 5),
                            Text(
                                '${_money(state.adminMetrics['grossSales'])} د.ع',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withValues(alpha: .14),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Text('من الطلبات المسجلة',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600))),
                          ])),
                      Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: .12),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.trending_up_rounded,
                              color: Colors.white, size: 32))
                    ]),
                  )),
              const SizedBox(height: 16),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount:
                          MediaQuery.textScalerOf(context).scale(1) > 1.3
                              ? 1
                              : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 160 *
                          MediaQuery.textScalerOf(context)
                              .scale(1)
                              .clamp(1.0, 2.0),
                      children: [
                        _Metric(
                            title: 'طلبات اليوم',
                            value:
                                '${state.adminMetrics['orders']?.toInt() ?? state.orders.length}',
                            icon: Icons.shopping_bag_rounded,
                            color: const Color(0xFFFF6F61),
                            background: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow),
                        _Metric(
                            title: 'المتاجر النشطة',
                            value:
                                '${state.adminMetrics['stores']?.toInt() ?? state.stores.length}',
                            icon: Icons.storefront_rounded,
                            color: const Color(0xFF7653D6),
                            background: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow),
                        _Metric(
                            title: 'العملاء',
                            value:
                                '${state.adminMetrics['users']?.toInt() ?? state.adminUsers.length}',
                            icon: Icons.groups_rounded,
                            color: const Color(0xFF238C69),
                            background: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow),
                        _Metric(
                            title: 'بانتظار الموافقة',
                            value:
                                '${state.adminStores.where((store) => store.status == StoreApprovalStatus.pending).length}',
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFD08B19),
                            background: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow),
                      ])),
              const SizedBox(height: 25),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _title('إجراءات سريعة')),
              const SizedBox(height: 12),
              SizedBox(
                  height: 92,
                  child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _Quick(
                            icon: Icons.add_business_rounded,
                            label: 'إضافة متجر',
                            onTap: () => onNavigate(1)),
                        _Quick(
                            icon: Icons.verified_user_rounded,
                            label: 'طلبات التفعيل',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => StoreApplicationsScreen(
                                        state: state)))),
                        _Quick(
                            icon: Icons.inventory_2_rounded,
                            label: 'مراجعة المنتجات',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        AdminProductsScreen(state: state)))),
                        _Quick(
                            icon: Icons.campaign_rounded,
                            label: 'إرسال إشعار',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => AdminToolScreen(
                                        state: state,
                                        tool: AdminTool.notifications,
                                        title: 'مركز الإشعارات')))),
                        _Quick(
                            icon: Icons.admin_panel_settings_rounded,
                            label: 'مركز الإدارة',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        AdminToolsScreen(state: state)))),
                      ])),
              const SizedBox(height: 24),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Expanded(child: _title('آخر النشاطات')),
                    TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AdminToolScreen(
                                    state: state,
                                    tool: AdminTool.security,
                                    title: 'الأمان وسجل التدقيق'))),
                        child: const Text('عرض الكل'))
                  ])),
              const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Card(
                      child: Column(children: [
                    _Activity(
                        icon: Icons.storefront_rounded,
                        color: Color(0xFF7653D6),
                        title: 'طلب انضمام متجر جديد',
                        subtitle: 'بيت الورد · منذ 8 دقائق'),
                    Divider(height: 1, indent: 66),
                    _Activity(
                        icon: Icons.payments_rounded,
                        color: Color(0xFF238C69),
                        title: 'تم تسديد دفعة متجر',
                        subtitle: 'ورود الجوري · 840,000 د.ع'),
                    Divider(height: 1, indent: 66),
                    _Activity(
                        icon: Icons.report_problem_rounded,
                        color: Color(0xFFFF6F61),
                        title: 'بلاغ جديد يحتاج مراجعة',
                        subtitle: 'طلب #AZ-2841 · منذ 35 دقيقة'),
                  ]))),
            ]),
          ));

  static Widget _title(String value) => Text(value,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700));

  static String _money(num? value) {
    final digits = (value ?? 0).round().toString();
    return digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }
}

class _Metric extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color, background;
  const _Metric(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color,
      required this.background});
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 21)),
              const Spacer(),
            ]),
            const Spacer(),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            Text(title,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12)),
          ])));
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Quick({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 11),
      child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
              width: 94,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18)),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        color: Theme.of(context).colorScheme.primary, size: 27),
                    const SizedBox(height: 7),
                    Text(label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600))
                  ]))));
}

class _Activity extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _Activity(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle});
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 21)),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_left_rounded));
}

class _Stores extends StatefulWidget {
  final AppState state;
  const _Stores({required this.state});

  @override
  State<_Stores> createState() => _StoresState();
}

class _StoresState extends State<_Stores> {
  String query = '';
  AppState get state => widget.state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final stores = state.adminStores.where((store) {
          final value = query.trim().toLowerCase();
          return value.isEmpty ||
              store.name.toLowerCase().contains(value) ||
              store.city.toLowerCase().contains(value) ||
              store.ownerName.toLowerCase().contains(value) ||
              store.ownerPhone.contains(value);
        }).toList();
        return SafeArea(
            bottom: false,
            child: Column(children: [
              _AdminHeader(
                  title: 'إدارة المتاجر',
                  subtitle: 'بيانات حقيقية من قاعدة المنصة',
                  actions: [
                    IconButton.filledTonal(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    StoreApplicationsScreen(state: state))),
                        icon: const Icon(Icons.fact_check_outlined),
                        tooltip: 'طلبات التسجيل')
                  ]),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            onChanged: (value) => setState(() => query = value),
                            decoration: const InputDecoration(
                                hintText: 'ابحث عن متجر',
                                prefixIcon: Icon(Icons.search_rounded)))),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                        onPressed: state.busy ? null : state.loadAdminData,
                        icon: const Icon(Icons.refresh_rounded))
                  ])),
              const SizedBox(height: 14),
              if (state.busy) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                  child: stores.isEmpty
                      ? const _AdminEmpty(
                          icon: Icons.storefront_outlined,
                          title: 'لا توجد متاجر',
                          subtitle: 'ستظهر طلبات انضمام المتاجر هنا')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: stores.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final store = stores[i];
                            final pending =
                                store.status == StoreApprovalStatus.pending;
                            return Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(children: [
                                      Container(
                                          width: 58,
                                          height: 58,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: pending
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerLow
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerLow,
                                              borderRadius:
                                                  BorderRadius.circular(17)),
                                          child: const Text('🌼',
                                              style: TextStyle(fontSize: 31))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(store.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            Text(
                                                '${store.city} · ${store.ownerName}',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 12)),
                                            const SizedBox(height: 7),
                                            _Status(
                                                text: _storeStatusLabel(
                                                    store.status),
                                                active: store.status ==
                                                    StoreApprovalStatus
                                                        .approved)
                                          ])),
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                                tooltip: 'تفاصيل المتجر',
                                                onPressed: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            AdminStoreDetailsScreen(
                                                                state: state,
                                                                store: store))),
                                                icon: const Icon(Icons
                                                    .chevron_left_rounded)),
                                            PopupMenuButton<
                                                    StoreApprovalStatus>(
                                                onSelected: (status) => _review(
                                                    context, store, status),
                                                itemBuilder: (_) => const [
                                                      PopupMenuItem(
                                                          value:
                                                              StoreApprovalStatus
                                                                  .approved,
                                                          child: Text(
                                                              'موافقة وتفعيل')),
                                                      PopupMenuItem(
                                                          value:
                                                              StoreApprovalStatus
                                                                  .rejected,
                                                          child: Text(
                                                              'رفض الطلب')),
                                                      PopupMenuItem(
                                                          value:
                                                              StoreApprovalStatus
                                                                  .suspended,
                                                          child: Text(
                                                              'إيقاف مؤقت'))
                                                    ])
                                          ])
                                    ])));
                          }))
            ]));
      });

  String _storeStatusLabel(StoreApprovalStatus status) => switch (status) {
        StoreApprovalStatus.pending => 'بانتظار الموافقة',
        StoreApprovalStatus.approved => 'نشط',
        StoreApprovalStatus.rejected => 'مرفوض',
        StoreApprovalStatus.suspended => 'موقوف',
      };

  Future<void> _review(BuildContext context, AdminStoreRecord store,
      StoreApprovalStatus status) async {
    String? reason;
    if (status == StoreApprovalStatus.rejected) {
      final controller = TextEditingController();
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('سبب رفض المتجر'),
          content: TextField(
              controller: controller,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'اكتب سبباً واضحاً للرفض')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('تأكيد'))
          ],
        ),
      );
      if (accepted != true) return;
      reason = controller.text.trim();
    }
    try {
      await state.reviewStore(store, status, reason: reason);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث حالة المتجر وحفظ العملية')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? 'تعذر تحديث المتجر')));
    }
  }
}

class _Status extends StatelessWidget {
  final String text;
  final bool active;
  const _Status({required this.text, required this.active});
  @override
  Widget build(BuildContext context) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.surfaceContainerLow
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8)),
          child: Text(text,
              style: TextStyle(
                  color: active
                      ? const Color(0xFF238C69)
                      : const Color(0xFFC47C0A),
                  fontSize: 10,
                  fontWeight: FontWeight.w700))));
}

class _AdminOrders extends StatelessWidget {
  final AppState state;
  const _AdminOrders({required this.state});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final orders = state.adminOrders;
        return SafeArea(
            bottom: false,
            child: Column(children: [
              const _AdminHeader(
                  title: 'إدارة الطلبات', subtitle: 'متابعة جميع طلبات المنصة'),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Expanded(child: _Filter(label: 'الكل', selected: true)),
                    SizedBox(width: 8),
                    Expanded(child: _Filter(label: 'نشطة')),
                    SizedBox(width: 8),
                    Expanded(child: _Filter(label: 'مكتملة'))
                  ])),
              const SizedBox(height: 14),
              Expanded(
                  child: orders.isEmpty
                      ? const _AdminEmpty(
                          icon: Icons.receipt_long_outlined,
                          title: 'لا توجد طلبات بعد',
                          subtitle: 'ستظهر طلبات المنصة هنا فور إنشائها')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final order = orders[i];
                            return Card(
                                child: ListTile(
                                    contentPadding: const EdgeInsets.all(15),
                                    leading: state.repository
                                            is! FirebaseRepository
                                        ? null
                                        : IconButton(
                                            tooltip: 'إسناد مندوب',
                                            icon: const Icon(
                                                Icons.delivery_dining_rounded),
                                            onPressed: () => _assignCourier(
                                                context, order.id)),
                                    title: Text(order.id,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    subtitle: Text(
                                        '${order.itemCount} منتجات · ${order.address}\nالعميل: ${order.customerId}'),
                                    isThreeLine: true,
                                    trailing: PopupMenuButton<OrderStatus>(
                                      tooltip: 'تغيير الحالة',
                                      enabled: !state.busy &&
                                          OrderStatus.values.any((status) =>
                                              canAdvanceOrder(
                                                  order.status, status)),
                                      onSelected: (status) =>
                                          _changeStatus(context, order, status),
                                      itemBuilder: (_) => OrderStatus.values
                                          .where((status) => canAdvanceOrder(
                                              order.status, status))
                                          .map((status) => PopupMenuItem(
                                              value: status,
                                              child:
                                                  Text(_statusLabel(status))))
                                          .toList(),
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text('${order.total} د.ع',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary)),
                                            _Status(
                                                text:
                                                    _statusLabel(order.status),
                                                active: order.status !=
                                                    OrderStatus.cancelled)
                                          ]),
                                    )));
                          }))
            ]));
      });

  Future<void> _assignCourier(BuildContext context, String orderId) async {
    final controller = TextEditingController();
    final uid = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('إسناد مندوب معتمد'),
              content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                      labelText: 'معرف حساب المندوب UID')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('إلغاء')),
                FilledButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, controller.text.trim()),
                    child: const Text('إسناد'))
              ],
            ));
    if (uid == null || uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'assignedCourierId': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم إسناد الطلب')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تعذر الإسناد. تأكد من اعتماد المندوب')));
      }
    }
  }

  String _statusLabel(OrderStatus status) => switch (status) {
        OrderStatus.newOrder => 'طلب جديد',
        OrderStatus.preparing => 'قيد التحضير',
        OrderStatus.delivering => 'قيد التوصيل',
        OrderStatus.delivered => 'مكتمل',
        OrderStatus.cancelled => 'ملغي',
      };

  Future<void> _changeStatus(
      BuildContext context, AdminOrderRecord order, OrderStatus status) async {
    try {
      await state.updateAdminOrderStatus(order, status);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تحديث حالة الطلب')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? 'تعذر تحديث الطلب')));
    }
  }
}

class _Filter extends StatelessWidget {
  final String label;
  final bool selected;
  const _Filter({required this.label, this.selected = false});
  @override
  Widget build(BuildContext context) => Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(13)),
      child: Text(label,
          style: TextStyle(
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600)));
}

class AdminUsersPanel extends StatefulWidget {
  final AppState state;
  const AdminUsersPanel({super.key, required this.state});

  @override
  State<AdminUsersPanel> createState() => _UsersState();
}

class _UsersState extends State<AdminUsersPanel> {
  String query = '';
  UserRole? selectedRole;
  AppState get state => widget.state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final users = state.adminUsers.where((user) {
          final value = query.trim().toLowerCase();
          final matchesRole = selectedRole == null || user.role == selectedRole;
          final matchesQuery = value.isEmpty ||
              user.name.toLowerCase().contains(value) ||
              user.phone.contains(value);
          return matchesRole && matchesQuery;
        }).toList();
        return SafeArea(
            bottom: false,
            child: Column(children: [
              const _AdminHeader(
                  title: 'المستخدمون', subtitle: 'حسابات وصلاحيات حقيقية'),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                          hintText: 'الاسم أو رقم الهاتف',
                          prefixIcon: Icon(Icons.search_rounded)))),
              const SizedBox(height: 14),
              SizedBox(
                  height: 42,
                  child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _userFilter(null, 'الكل'),
                        _userFilter(UserRole.customer, 'العملاء'),
                        _userFilter(UserRole.store, 'المتاجر'),
                        _userFilter(UserRole.superAdmin, 'الإدارة'),
                      ])),
              const SizedBox(height: 10),
              Expanded(
                  child: users.isEmpty
                      ? const _AdminEmpty(
                          icon: Icons.group_outlined,
                          title: 'لا يوجد مستخدمون',
                          subtitle: 'ستظهر حسابات المنصة هنا')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: users.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final user = users[i];
                            return Card(
                                child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    leading: CircleAvatar(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLow,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        child: Text(
                                            user.name.isEmpty
                                                ? '؟'
                                                : user.name[0],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700))),
                                    title: Row(children: [
                                      Flexible(
                                          child: Text(user.name,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w700))),
                                      if (!user.active) ...[
                                        const SizedBox(width: 6),
                                        const _Status(
                                            text: 'موقوف', active: false)
                                      ]
                                    ]),
                                    subtitle: Text(
                                        '${user.phone} · ${_roleLabel(user.role)}'),
                                    trailing:
                                        const Icon(Icons.chevron_left_rounded),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                AdminUserDetailsScreen(
                                                    state: state,
                                                    user: user)))));
                          }))
            ]));
      });

  Widget _userFilter(UserRole? role, String label) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
          label: Text(label),
          selected: selectedRole == role,
          onSelected: (_) => setState(() => selectedRole = role)));

  String _roleLabel(UserRole role) => role.label;
}

class _AdminAccount extends StatelessWidget {
  final AppState state;
  const _AdminAccount({required this.state});
  @override
  Widget build(BuildContext context) => SafeArea(
      bottom: false,
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const Text('حساب الإدارة',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 22),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.admin_panel_settings_rounded,
                              color: Colors.white, size: 35)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(state.user?.name ?? 'سوبر أدمن أزهارنا',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            Text(state.user?.phone ?? '',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            const SizedBox(height: 5),
                            const _Status(text: 'صلاحية كاملة', active: true)
                          ]))
                    ]))),
            const SizedBox(height: 18),
            Card(
                child: Column(children: [
              _Setting(Icons.security_rounded, 'الأمان وسجل التدقيق',
                  onTap: () => _openTool(
                      context, AdminTool.security, 'الأمان وسجل التدقيق')),
              const Divider(height: 1, indent: 60),
              _Setting(Icons.manage_accounts_rounded, 'مديرو النظام والصلاحيات',
                  onTap: () => _openTool(
                      context, AdminTool.permissions, 'الأدوار والصلاحيات')),
              const Divider(height: 1, indent: 60),
              _Setting(Icons.payments_outlined, 'العمولات والمدفوعات',
                  onTap: () => _openTool(
                      context, AdminTool.finance, 'المالية والعمولات')),
              const Divider(height: 1, indent: 60),
              _Setting(Icons.notifications_outlined, 'إعدادات الإشعارات',
                  onTap: () => _openTool(
                      context, AdminTool.notifications, 'مركز الإشعارات')),
              const Divider(height: 1, indent: 60),
              _Setting(Icons.settings_outlined, 'إعدادات المنصة',
                  onTap: () =>
                      _openTool(context, AdminTool.platform, 'إعدادات المنصة'))
            ])),
            const SizedBox(height: 18),
            Row(children: [
              const Expanded(
                  child: Text('جميع أدوات السوبر أدمن',
                      style: TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800))),
              Text('${AdminToolsScreen.tools.length} قسم',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AdminToolsScreen.tools.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
                childAspectRatio: .88,
              ),
              itemBuilder: (context, index) {
                final tool = AdminToolsScreen.tools[index];
                return Material(
                  color: tool.$6,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openTool(context, tool.$1, tool.$2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 43,
                            height: 43,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: .82),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(tool.$4, color: tool.$5, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(tool.$2,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
                onPressed: () async {
                  if (!await confirmLogout(context) || !context.mounted) return;
                  await state.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => WelcomeScreen(state: state)),
                      (_) => false);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل الخروج')),
          ]));

  void _openTool(BuildContext context, AdminTool tool, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminToolScreen(state: state, tool: tool, title: title),
      ),
    );
  }
}

class _Setting extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  const _Setting(this.icon, this.title, {this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: onTap);
}

class _AdminEmpty extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _AdminEmpty(
      {required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle),
                child: Icon(icon,
                    size: 45, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 18),
            Text(title,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))
          ])));
}
