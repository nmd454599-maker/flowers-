import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_finance_screen.dart';
import 'admin_refunds_screen.dart';
import 'customer_requests_screen.dart';
import '../shared/store_records_screen.dart';
import '../customer/notifications_screen.dart';
import '../../data/sqlite_repository.dart';
import 'admin_shell.dart' show AdminUsersPanel;
import 'local_controls_screen.dart';

enum AdminTool {
  approvals,
  finance,
  disputes,
  delivery,
  content,
  notifications,
  permissions,
  analytics,
  monitoring,
  support,
  platform,
  security,
}

class AdminToolsScreen extends StatelessWidget {
  final AppState state;
  const AdminToolsScreen({super.key, required this.state});

  static const tools = [
    (
      AdminTool.approvals,
      'مركز الموافقات',
      'المتاجر والوثائق والمنتجات',
      Icons.fact_check_rounded,
      Color(0xFF7653D6),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.finance,
      'المالية والعمولات',
      'المستحقات والتحويلات والكشوفات',
      Icons.account_balance_wallet_rounded,
      Color(0xFF238C69),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.disputes,
      'النزاعات والاسترجاع',
      'الشكاوى والإلغاءات والتعويضات',
      Icons.gavel_rounded,
      Color(0xFFFF6F61),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.delivery,
      'المناطق والتوصيل',
      'المدن والأسعار والتغطية',
      Icons.map_rounded,
      Color(0xFF2C73D2),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.content,
      'محتوى التطبيق',
      'البانرات والأقسام والحملات',
      Icons.dashboard_customize_rounded,
      Color(0xFFB65B24),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.notifications,
      'مركز الإشعارات',
      'الإرسال والاستهداف والجدولة',
      Icons.campaign_rounded,
      Color(0xFFD08B19),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.permissions,
      'الأدوار والصلاحيات',
      'مديرو النظام ومستويات الوصول',
      Icons.manage_accounts_rounded,
      Color(0xFF064C65),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.analytics,
      'التقارير والتحليلات',
      'المبيعات والأداء والتحويل',
      Icons.query_stats_rounded,
      Color(0xFF126A7A),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.monitoring,
      'المراقبة والتنبيهات',
      'المخاطر والتأخير وحالة الخدمات',
      Icons.monitor_heart_rounded,
      Color(0xFFC34B42),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.support,
      'خدمة العملاء',
      'البحث والحالات والتعويضات',
      Icons.support_agent_rounded,
      Color(0xFF476B2D),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.platform,
      'إعدادات المنصة',
      'الصيانة والرسوم والسياسات',
      Icons.tune_rounded,
      Color(0xFF617781),
      Color(0xFFE5F4F7)
    ),
    (
      AdminTool.security,
      'الأمان وسجل التدقيق',
      '2FA والجلسات والعمليات',
      Icons.security_rounded,
      Color(0xFF343B78),
      Color(0xFFE5F4F7)
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('مركز إدارة المنصة')),
        body: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          itemCount: tools.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  (MediaQuery.sizeOf(context).width / 240).floor().clamp(2, 4),
              mainAxisExtent: 235 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12),
          itemBuilder: (_, i) {
            final tool = tools[i];
            return Card(
                child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AdminToolScreen(
                          state: state, tool: tool.$1, title: tool.$2))),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                                color: tool.$6,
                                borderRadius: BorderRadius.circular(14)),
                            child: Icon(tool.$4, color: tool.$5)),
                        const Spacer(),
                        Text(tool.$2,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(tool.$3,
                            maxLines: 2,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 11)),
                        const SizedBox(height: 7),
                        const Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Icon(Icons.arrow_back_rounded, size: 18)),
                      ])),
            ));
          },
        ),
      );
}

class AdminToolScreen extends StatefulWidget {
  final AppState state;
  final AdminTool tool;
  final String title;
  const AdminToolScreen(
      {super.key,
      required this.state,
      required this.tool,
      required this.title});
  @override
  State<AdminToolScreen> createState() => _AdminToolScreenState();
}

class _AdminToolScreenState extends State<AdminToolScreen> {
  bool enabled = true;
  bool second = false;
  double commission = 12;
  final notificationTitle = TextEditingController();
  final notificationBody = TextEditingController();
  String notificationTarget = 'الكل';

  String get scope => widget.tool.name;

  @override
  void initState() {
    super.initState();
    widget.state.loadAdminScope(scope).catchError((_) {});
  }

  @override
  void dispose() {
    notificationTitle.dispose();
    notificationBody.dispose();
    super.dispose();
  }

  void done(String message) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)));

  Future<bool> save(
      String recordId, Map<String, Object?> data, String message) async {
    try {
      await widget.state.saveAdminRecord(scope, recordId, data);
      if (!mounted) return true;
      setState(() {});
      done(message);
      return true;
    } catch (_) {
      if (!mounted) return false;
      done(widget.state.errorMessage ?? 'تعذر حفظ العملية');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.state.repository
              is SqliteRepository &&
          [AdminTool.content, AdminTool.platform].contains(widget.tool)
      ? LocalControlsScreen(
          state: widget.state, platform: widget.tool == AdminTool.platform)
      : widget.state.repository is SqliteRepository &&
              widget.tool == AdminTool.permissions
          ? Scaffold(
              appBar: AppBar(title: const Text('إدارة الحسابات والصلاحيات')),
              body: AdminUsersPanel(state: widget.state))
          : widget.state.repository is SqliteRepository &&
                  widget.tool == AdminTool.support
              ? CustomerRequestsScreen(state: widget.state)
              : widget.state.repository is SqliteRepository &&
                      [AdminTool.analytics, AdminTool.delivery]
                          .contains(widget.tool)
                  ? StoreRecordsScreen(state: widget.state, title: widget.title)
                  : widget.state.repository is SqliteRepository &&
                          widget.tool == AdminTool.monitoring
                      ? NotificationsScreen(state: widget.state)
                      : widget.state.repository is SqliteRepository &&
                              widget.tool == AdminTool.security
                          ? StoreRecordsScreen(
                              state: widget.state, title: 'سجل النشاط والأمان')
                          : widget.tool == AdminTool.finance
                              ? AdminFinanceScreen(state: widget.state)
                              : widget.tool == AdminTool.disputes
                                  ? AdminRefundsScreen(state: widget.state)
                                  : Scaffold(
                                      appBar: AppBar(
                                          title: Text(widget.title),
                                          actions: [
                                            IconButton(
                                                tooltip: 'تحديث',
                                                onPressed: () async {
                                                  await widget.state
                                                      .loadAdminScope(scope);
                                                  if (mounted) setState(() {});
                                                },
                                                icon: const Icon(
                                                    Icons.refresh_rounded))
                                          ]),
                                      body: _content(),
                                    );

  Widget _content() => switch (widget.tool) {
        AdminTool.approvals => _approvals(),
        AdminTool.finance => _finance(),
        AdminTool.disputes => _disputes(),
        AdminTool.delivery => _delivery(),
        AdminTool.content => _contentManager(),
        AdminTool.notifications => _notifications(),
        AdminTool.permissions => _permissions(),
        AdminTool.analytics => _analytics(),
        AdminTool.monitoring => _monitoring(),
        AdminTool.support => _support(),
        AdminTool.platform => _platform(),
        AdminTool.security => _security(),
      };

  Widget _approvals() => _page([
        _SummaryRow(items: [
          (
            'بانتظار المراجعة',
            '${widget.state.adminStores.where((e) => e.status == StoreApprovalStatus.pending).length}'
          ),
          (
            'وثائق ناقصة',
            '${widget.state.adminStores.where((e) => !e.documentsComplete).length}'
          ),
          (
            'المتاجر الفعالة',
            '${widget.state.adminStores.where((e) => e.status == StoreApprovalStatus.approved).length}'
          )
        ]),
        _section('طلبات المتاجر'),
        ...widget.state.adminStores
            .where((e) => e.status == StoreApprovalStatus.pending)
            .map(_approvalStore),
        if (!widget.state.adminStores
            .any((e) => e.status == StoreApprovalStatus.pending))
          const _InfoBox(text: 'لا توجد طلبات متاجر بانتظار المراجعة حالياً.'),
      ]);

  Widget _approvalStore(AdminStoreRecord store) =>
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLow,
              child: const Icon(Icons.storefront_rounded,
                  color: Color(0xFF7653D6))),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(store.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${store.city} · ${store.ownerName}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12))
              ]))
        ]),
        const SizedBox(height: 12),
        Text(
            store.documentsComplete
                ? 'الوثائق مكتملة وجاهزة للمراجعة'
                : 'توجد وثائق ناقصة',
            style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(
              child: FilledButton(
                  onPressed: () =>
                      _reviewStore(store, StoreApprovalStatus.approved),
                  child: const Text('موافقة'))),
          const SizedBox(width: 8),
          Expanded(
              child: OutlinedButton(
                  onPressed: () =>
                      _reviewStore(store, StoreApprovalStatus.rejected),
                  child: const Text('رفض')))
        ]),
      ]));

  Future<void> _reviewStore(
      AdminStoreRecord store, StoreApprovalStatus status) async {
    String? reason;
    if (status == StoreApprovalStatus.rejected) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('سبب الرفض'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'اكتب سبب الرفض'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('تأكيد')),
          ],
        ),
      );
      if (confirmed != true) return;
      reason = controller.text.trim();
    }
    try {
      await widget.state.reviewStore(store, status, reason: reason);
      if (!mounted) return;
      setState(() {});
      done(status == StoreApprovalStatus.approved
          ? 'تم تفعيل المتجر'
          : 'تم رفض المتجر وحفظ السبب');
    } catch (_) {
      if (!mounted) return;
      done(widget.state.errorMessage ?? 'تعذر تنفيذ العملية');
    }
  }

  Widget _finance() => _page([
        const _MoneyBanner(),
        _section('نسبة عمولة المنصة'),
        _card(Column(children: [
          Row(children: [
            const Text('العمولة العامة',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${commission.round()}%',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700))
          ]),
          Slider(
              value: commission,
              min: 0,
              max: 30,
              divisions: 30,
              onChanged: (v) => setState(() => commission = v)),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: () => save(
                      'commission',
                      {'percentage': commission.round(), 'active': true},
                      'تم حفظ نسبة العمولة'),
                  child: const Text('حفظ التغييرات')))
        ])),
        _section('مستحقات المتاجر'),
        _financeItem('ورود الجوري', '1,240,000 د.ع', 'جاهزة للتحويل'),
        _financeItem('بيت الهدايا', '860,000 د.ع', 'تستحق خلال يومين'),
        OutlinedButton.icon(
            onPressed: () => save(
                'export_${DateTime.now().millisecondsSinceEpoch}',
                {'type': 'finance', 'status': 'requested'},
                'تم إنشاء طلب تصدير الكشف'),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('تصدير كشف Excel / PDF')),
      ]);

  Widget _disputes() => _page([
        const _SummaryRow(items: [
          ('مفتوحة', '5'),
          ('عالية الأولوية', '2'),
          ('حُلّت اليوم', '9')
        ]),
        _section('الحالات المفتوحة'),
        _caseCard('#AZ-2841', 'الطلب وصل متأخراً والزهور تالفة',
            'سارة أحمد · منذ 35 دقيقة', Colors.red),
        _caseCard('#AZ-2794', 'طلب استرجاع مبلغ بعد الإلغاء',
            'علي كريم · منذ ساعتين', Colors.orange),
      ]);

  Widget _delivery() => _page([
        _card(SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('التوصيل متاح حالياً',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('إيقافه يمنع استقبال طلبات جديدة'),
            value: enabled,
            onChanged: (v) {
              setState(() => enabled = v);
              save('availability', {'enabled': v},
                  v ? 'تم تفعيل التوصيل' : 'تم إيقاف التوصيل');
            })),
        _section('مناطق التغطية'),
        _area('بغداد', '5,000 د.ع', true),
        _area('البصرة', '7,000 د.ع', true),
        _area('أربيل', '8,000 د.ع', false),
        FilledButton.icon(
            onPressed: () =>
                _textDialog('إضافة منطقة جديدة', 'اسم المدينة أو المنطقة'),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text('إضافة منطقة')),
      ]);

  Widget _contentManager() => _page([
        _section('البانرات النشطة'),
        _banner('حملة عيد الأم', 'تظهر من 15 إلى 21 آذار',
            Theme.of(context).colorScheme.surfaceContainerLow, '💐'),
        _banner('خصم نهاية الأسبوع', 'خصم 15% على المتاجر المحددة',
            Theme.of(context).colorScheme.surfaceContainerLow, '🎁'),
        _section('التحكم بالصفحة الرئيسية'),
        _setting('قسم المناسبات', 'إظهار وترتيب مناسبات الإهداء', enabled,
            (v) => setState(() => enabled = v)),
        _setting('المتاجر المميزة', 'اختيار المتاجر وترتيبها', true, (_) {}),
        FilledButton.icon(
            onPressed: () => _textDialog('إنشاء حملة', 'اسم الحملة'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('حملة أو بانر جديد')),
      ]);

  Widget _notifications() => _page([
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إنشاء إشعار',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 14),
          TextField(
              controller: notificationTitle,
              decoration: const InputDecoration(hintText: 'عنوان الإشعار')),
          const SizedBox(height: 10),
          TextField(
              controller: notificationBody,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'نص الرسالة')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
              initialValue: 'الكل',
              decoration: const InputDecoration(labelText: 'الفئة المستهدفة'),
              items: [
                'الكل',
                'العملاء',
                'المتاجر',
                'مدينة محددة',
                if (widget.state.repository is! SqliteRepository) 'غير النشطين'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) => notificationTarget = value ?? 'الكل'),
          const SizedBox(height: 12),
          _setting('جدولة الإرسال', 'اختر تاريخاً ووقتاً لاحقاً', second,
              (v) => setState(() => second = v)),
          const SizedBox(height: 10),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: _submitNotification,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(second ? 'جدولة' : 'إرسال الآن'))),
        ])),
        if (widget.state.repository is SqliteRepository)
          Text(
              'الإشعارات المحفوظة: ${widget.state.adminRecords['notifications']?.length ?? 0} • تظهر داخل التطبيق عند فتح صفحة الإشعارات.')
        else ...[
          _section('أداء آخر حملة'),
          const _SummaryRow(items: [
            ('تم الإرسال', '2,438'),
            ('تم الفتح', '1,806'),
            ('نسبة الفتح', '74%')
          ]),
        ],
      ]);

  Widget _permissions() => _page([
        const _InfoBox(
            text:
                'امنح كل موظف أقل قدر من الصلاحيات اللازمة لمهمته، ولا تشارك صلاحية السوبر أدمن.'),
        _section('مديرو النظام'),
        _role('أحمد سالم', 'مدير مالي', 'المدفوعات · التقارير'),
        _role('مريم علي', 'خدمة العملاء', 'الطلبات · النزاعات · العملاء'),
        _role('زينب حسن', 'مديرة المحتوى', 'البانرات · الإشعارات'),
        FilledButton.icon(
            onPressed: () =>
                _textDialog('دعوة مدير جديد', 'رقم الهاتف أو البريد'),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('إضافة مدير وصلاحيات')),
      ]);

  Widget _analytics() => _page([
        _SummaryRow(items: [
          (
            'متوسط الطلب',
            '${((widget.state.adminMetrics['averageOrder'] ?? 0) / 1000).round()} ألف'
          ),
          (
            'نسبة الإلغاء',
            '${(widget.state.adminMetrics['cancellationRate'] ?? 0).toStringAsFixed(1)}%'
          ),
          ('عدد الطلبات', '${widget.state.adminMetrics['orders'] ?? 0}')
        ]),
        _section('المبيعات خلال 7 أيام'),
        const _SimpleChart(),
        _section('الأفضل أداءً'),
        _rank('1', 'ورود الجوري', '3,840,000 د.ع'),
        _rank('2', 'بيت الهدايا', '2,650,000 د.ع'),
        _rank('3', 'شوكولا', '1,920,000 د.ع'),
        OutlinedButton.icon(
            onPressed: () => save(
                'report_${DateTime.now().millisecondsSinceEpoch}',
                {'range': '7d', 'status': 'requested'},
                'تم إنشاء طلب التقرير'),
            icon: const Icon(Icons.download_rounded),
            label: const Text('تحميل التقرير الكامل')),
      ]);

  Widget _monitoring() => _page([
        _card(Row(children: [
          Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: Color(0xFF26A678), shape: BoxShape.circle)),
          const SizedBox(width: 9),
          const Expanded(
              child: Text('جميع خدمات المنصة تعمل بشكل طبيعي',
                  style: TextStyle(fontWeight: FontWeight.w700))),
          const Text('99.9%',
              style: TextStyle(
                  color: Color(0xFF238C69), fontWeight: FontWeight.w700))
        ])),
        _section('تنبيهات تحتاج تدخلاً'),
        _alert(Icons.timer_outlined, '3 طلبات متأخرة',
            'تجاوزت وقت التجهيز المحدد', Colors.red),
        _alert(Icons.trending_down_rounded, 'ارتفاع إلغاءات متجر',
            'متجر شوكولا · 14% هذا الأسبوع', Colors.orange),
        _alert(Icons.login_rounded, 'محاولة دخول غير معتادة',
            'جهاز جديد · بغداد · 02:14', const Color(0xFF7653D6)),
        _section('قواعد التنبيه'),
        _setting('تنبيه الطلب المتأخر', 'بعد 60 دقيقة دون تحديث', true, (_) {}),
        _setting('تنبيه ارتفاع الإلغاء', 'عند تجاوز 10%', true, (_) {}),
      ]);

  Widget _support() => _page([
        const TextField(
            decoration: InputDecoration(
                hintText: 'رقم الهاتف أو الطلب',
                prefixIcon: Icon(Icons.search_rounded))),
        _section('حالات خدمة العملاء'),
        _caseCard('#AZ-2841', 'شكوى جودة المنتج',
            'الأولوية: عالية · مسندة إلى مريم', Colors.red),
        _caseCard('#AZ-2810', 'تعديل عنوان التوصيل', 'الأولوية: عادية · جديد',
            Colors.blue),
        _section('إجراءات سريعة'),
        _card(Column(children: [
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.card_giftcard_rounded),
              title: const Text('منح قسيمة تعويض'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _textDialog('قسيمة تعويض', 'قيمة القسيمة')),
          const Divider(),
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.block_rounded),
              title: const Text('حظر حساب مسيء'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _textDialog('حظر حساب', 'رقم الهاتف'))
        ])),
      ]);

  Widget _platform() => _page([
        _card(_setting('وضع الصيانة', 'إيقاف التطبيق مؤقتاً للمستخدمين', second,
            (v) => setState(() => second = v))),
        _section('إعدادات التشغيل'),
        _numberSetting('الحد الأدنى للطلب', '10,000 د.ع'),
        _numberSetting('رسوم الخدمة', '1,000 د.ع'),
        _numberSetting('الضريبة', '0%'),
        _section('المعلومات القانونية والدعم'),
        _linkSetting('شروط الاستخدام'),
        _linkSetting('سياسة الخصوصية'),
        _linkSetting('أرقام وروابط الدعم'),
        SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: () => save(
                    'settings',
                    {
                      'maintenanceMode': second,
                      'minimumOrder': 10000,
                      'serviceFee': 1000,
                      'taxPercent': 0,
                    },
                    'تم حفظ إعدادات المنصة'),
                child: const Text('حفظ الإعدادات'))),
      ]);

  Widget _security() => _page([
        const _InfoBox(
            text:
                'حسابك يمتلك صلاحيات كاملة. ننصح بتفعيل التحقق الثنائي ومراجعة الجلسات باستمرار.'),
        _setting('التحقق الثنائي 2FA', 'طلب رمز إضافي عند تسجيل الدخول',
            enabled, (v) => setState(() => enabled = v)),
        _setting(
            'تأكيد العمليات المالية', 'رمز إضافي قبل التحويلات', true, (_) {}),
        _section('الجلسات النشطة'),
        _session(
            Icons.phone_android_rounded, 'RMX3142', 'بغداد · الجهاز الحالي'),
        _session(Icons.laptop_windows_rounded, 'Chrome على Windows',
            'بغداد · منذ ساعتين'),
        OutlinedButton.icon(
            onPressed: () => save(
                'revoke_sessions_${DateTime.now().millisecondsSinceEpoch}',
                {'action': 'revokeOtherSessions', 'status': 'pendingBackend'},
                'تم إرسال طلب إنهاء الجلسات للخادم'),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('تسجيل خروج كل الأجهزة الأخرى')),
        _section('سجل التدقيق'),
        _audit('تعديل عمولة المنصة', 'سوبر أدمن · اليوم 10:42'),
        _audit('الموافقة على متجر بيت الورد', 'أحمد سالم · اليوم 09:18'),
        _audit('إرسال إشعار إلى العملاء', 'زينب حسن · أمس 18:05'),
      ]);

  Widget _page(List<Widget> children) {
    final records = widget.state.adminRecords[scope] ?? const <AdminRecord>[];
    final allChildren = <Widget>[
      ...children,
      if (records.isNotEmpty) _section('آخر التغييرات المحفوظة'),
      ...records.take(10).map((record) => _card(ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.cloud_done_outlined, color: Color(0xFF238C69)),
            title: Text('${record.data['title'] ?? record.id}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${record.data['value'] ?? record.data['status'] ?? 'محفوظ'}'),
          ))),
    ];
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        children: allChildren
            .expand((e) => [e, const SizedBox(height: 12)])
            .toList());
  }

  Widget _section(String value) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)));
  Widget _card(Widget child) =>
      Card(child: Padding(padding: const EdgeInsets.all(16), child: child));

  Widget _financeItem(String name, String amount, String status) =>
      _card(ListTile(
          onTap: () =>
              _textDialog('مراجعة مستحقات $name', 'ملاحظة أو رقم التحويل'),
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLow,
              child: const Icon(Icons.store_rounded, color: Color(0xFF238C69))),
          title:
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(status),
          trailing: Text(amount,
              style: const TextStyle(fontWeight: FontWeight.w700))));
  Widget _caseCard(String id, String title, String subtitle, Color color) =>
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(id, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const Spacer(),
          const Icon(Icons.chevron_left_rounded)
        ]),
        const SizedBox(height: 7),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(subtitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12)),
        const SizedBox(height: 11),
        SizedBox(
            width: double.infinity,
            child: OutlinedButton(
                onPressed: () =>
                    _textDialog('اتخاذ إجراء للحالة $id', 'القرار أو الملاحظة'),
                child: const Text('مراجعة واتخاذ إجراء')))
      ]));
  Widget _area(String city, String fee, bool active) => _card(Row(children: [
        Icon(Icons.location_on_rounded,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(city, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('رسوم التوصيل $fee',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12))
        ])),
        Switch(
            value: active,
            onChanged: (value) => save(
                'area_$city',
                {'city': city, 'fee': fee, 'active': value},
                'تم تحديث حالة $city'))
      ]));
  Widget _banner(String title, String subtitle, Color color, String emoji) =>
      _card(InkWell(
          onTap: () => _textDialog('تعديل $title', 'اسم الحملة أو الملاحظة'),
          child: Row(children: [
            Container(
                width: 67,
                height: 67,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(16)),
                child: Text(emoji, style: const TextStyle(fontSize: 34))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12))
                ])),
            Icon(Icons.drag_indicator_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant)
          ])));
  Widget _setting(String title, String subtitle, bool value,
          ValueChanged<bool> changed) =>
      SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          value: value,
          onChanged: (value) {
            changed(value);
            save('setting_${title.hashCode}',
                {'title': title, 'enabled': value}, 'تم تحديث $title');
          });
  Widget _role(String name, String role, String access) => _card(ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Text(name[0])),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$role\n$access'),
      isThreeLine: true,
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _textDialog('تعديل صلاحيات $name', 'الصلاحيات الجديدة')));
  Widget _rank(String rank, String title, String value) => _card(Row(children: [
        CircleAvatar(
            radius: 17,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Text(rank,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700))),
        Text(value, style: const TextStyle(fontSize: 12))
      ]));
  Widget _alert(IconData icon, String title, String subtitle, Color color) =>
      _card(Row(children: [
        Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: color)),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(subtitle,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11))
        ])),
        const Icon(Icons.chevron_left_rounded)
      ]));
  Widget _numberSetting(String title, String value) => _card(InkWell(
      onTap: () => _textDialog('تعديل $title', value),
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(value,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 5),
        const Icon(Icons.edit_outlined, size: 18)
      ])));
  Widget _linkSetting(String title) => _card(InkWell(
      onTap: () => _textDialog(title, 'النص أو الرابط'),
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600))),
        const Icon(Icons.chevron_left_rounded)
      ])));
  Widget _session(IconData icon, String title, String subtitle) => _card(
      ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.more_vert_rounded)));
  Widget _audit(String title, String subtitle) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history_rounded),
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)));

  Future<void> _submitNotification() async {
    final title = notificationTitle.text.trim();
    final body = notificationBody.text.trim();
    if (title.isEmpty || body.isEmpty) {
      done('اكتب عنوان الإشعار ونصه');
      return;
    }
    DateTime? scheduledFor;
    if (second) {
      final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (date == null || !mounted) return;
      final time =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time == null) return;
      scheduledFor =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (!scheduledFor.isAfter(DateTime.now())) {
        done('اختر وقتاً لاحقاً للإرسال');
        return;
      }
    }
    final saved = await save(
        'notification_${DateTime.now().millisecondsSinceEpoch}',
        {
          'title': title,
          'body': body,
          'target': notificationTarget,
          'city': widget.state.selectedCity,
          'scheduled': second,
          if (scheduledFor != null) 'scheduledFor': scheduledFor,
          'status': second ? 'scheduled' : 'pendingBackend',
        },
        second
            ? 'تم حفظ جدولة الإشعار'
            : widget.state.repository is SqliteRepository
                ? 'تم نشر الإشعار داخل التطبيق'
                : 'تم وضع الإشعار في قائمة الإرسال');
    if (!saved) return;
    notificationTitle.clear();
    notificationBody.clear();
  }

  Future<void> _textDialog(String title, String hint) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: Text(title),
                content: TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: hint)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('إلغاء')),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, controller.text.trim()),
                      child: const Text('حفظ'))
                ]));
    controller.dispose();
    if (value == null || value.isEmpty) return;
    await save('entry_${DateTime.now().millisecondsSinceEpoch}',
        {'title': title, 'value': value, 'status': 'active'}, 'تم الحفظ بنجاح');
  }
}

class _SummaryRow extends StatelessWidget {
  final List<(String, String)> items;
  const _SummaryRow({required this.items});
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Row(
              children: items
                  .map((e) => Expanded(
                          child: Column(children: [
                        Text(e.$2,
                            style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 3),
                        Text(e.$1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 10))
                      ])))
                  .toList())));
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF7653D6)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Text(text, style: const TextStyle(fontSize: 12, height: 1.5)))
      ]));
}

class _MoneyBanner extends StatelessWidget {
  const _MoneyBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF176B55), Color(0xFF2B9777)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رصيد المنصة هذا الشهر',
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 6),
            Text('3,284,000 د.ع',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('مستحقات المتاجر\n8,420,000 د.ع',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                Expanded(
                  child: Text('عمولات المنصة\n1,540,000 د.ع',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      );
}

class _SimpleChart extends StatelessWidget {
  const _SimpleChart();
  @override
  Widget build(BuildContext context) {
    const values = [42.0, 70.0, 54.0, 88.0, 66.0, 96.0, 82.0];
    const days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    return Card(
        child: SizedBox(
            height: 190,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                        values.length,
                        (i) => Expanded(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                  Container(
                                      height: values[i],
                                      width: 22,
                                      decoration: BoxDecoration(
                                          color: i == 5
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant,
                                          borderRadius:
                                              BorderRadius.circular(7))),
                                  const SizedBox(height: 8),
                                  Text(days[i],
                                      style: const TextStyle(fontSize: 11))
                                ])))))));
  }
}
