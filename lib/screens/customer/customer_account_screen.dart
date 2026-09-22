import '../../services/rewards_service.dart';
import '../../domain/accounts/reward_account.dart';
import 'checkout_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../data/firebase_repository.dart';
// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../services/customer_account_service.dart';
import '../../state/app_state.dart';
import '../../domain/accounts/account_identity.dart';
import '../auth/welcome_screen.dart';
import 'orders_screen.dart';
import 'store_reviews_panel.dart';

class CustomerAccountScreen extends StatefulWidget {
  final AppState state;
  final String title;
  const CustomerAccountScreen(
      {super.key, required this.state, required this.title});
  @override
  State<CustomerAccountScreen> createState() => _CustomerAccountScreenState();
}

class _CustomerAccountScreenState extends State<CustomerAccountScreen> {
  CustomerAccountService? service;
  Map<String, Object?> data = {};
  List<Map<String, Object?>> requests = [];
  bool loading = true, saving = false;
  String? error;
  String? redemptionId;
  String get title => widget.title;
  String get section => switch (title) {
        'الملف الشخصي' => 'profile',
        'الأشخاص المحفوظون' => 'recipients',
        'دفتر المناسبات' => 'occasions',
        'عناويني' => 'addresses',
        'مستوى العضوية' || 'النقاط والكوبونات' || 'المحفظة' => 'benefits',
        _ => 'preferences',
      };
  String? get requestKind => switch (title) {
        'المساعدة والشكاوى' => 'support',
        'حوّل إلى حساب متجر' => 'store',
        'سجّل كمندوب' => 'courier',
        _ => null,
      };
  @override
  void initState() {
    super.initState();
    final user = widget.state.user;
    if (user != null) {
      service = CustomerAccountService(widget.state.repository, user);
    }
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final s = service;
      if (s != null) {
        if (section == 'benefits') await RewardsService(widget.state.repository, s.user).syncDelivered();
        final result = await s.read(section);
        final list = requestKind == null
            ? <Map<String, Object?>>[]
            : await s.requests(requestKind!);
        if (!mounted) return;
        data = result;
        requests = list;
      }
      if (title == 'سجل الهدايا' || title == 'تقييماتي') {
        await widget.state.refreshOrders();
      }
    } catch (_) {
      error = 'تعذر تحميل البيانات. تحقق من الاتصال وأعد المحاولة.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> perform(Future<void> Function() action) async {
    if (saving || service == null) return;
    setState(() => saving = true);
    try {
      await action();
      if (!mounted) return;
      await load();
      if (mounted && error == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تعذر الحفظ. لم يتم تأكيد التغيير، حاول مجددًا.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget info(String label, String value) =>
      ListTile(title: Text(label), subtitle: Text(value));
  Widget button(String label, VoidCallback action) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FilledButton(
          onPressed: saving || service == null ? null : action,
          child: Text(label)));

  Future<Map<String, Object?>?> form(String heading, Map<String, String> fields,
          {Map<String, Object?> initial = const {},
          Set<String> optional = const {}}) =>
      showDialog<Map<String, Object?>>(
          context: context,
          builder: (_) => _AccountForm(
              title: heading,
              fields: fields,
              initial: initial,
              optional: optional));

  Future<void> editProfile() async {
    final result = await form('تعديل الملف الشخصي', {
      'name': 'الاسم الكامل',
      'email': 'البريد الإلكتروني',
      'birthDate': 'تاريخ الميلاد',
      'gender': 'الجنس'
    }, initial: {
      'name': widget.state.user?.name,
      ...data
    }, optional: {
      'email',
      'birthDate',
      'gender'
    });
    if (result == null || !mounted) return;
    await perform(() async {
      await service!.save('profile', {...data, ...result});
      final u = widget.state.user;
      if (u != null && u.id == service!.user.id) {
        widget.state.updateCustomerName(result['name'] as String);
      }
    });
  }

  Future<void> photo() async {
    try {
      final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 640,
          maxHeight: 640,
          imageQuality: 75);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 450000) throw StateError('image too large');
      await perform(() => service!.save('profile', {
            'name': widget.state.user!.name,
            ...data,
            'avatar': base64Encode(bytes)
          }));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تعذر اختيار الصورة. اختر صورة أصغر حجمًا.')));
      }
    }
  }

  Map<String, String> get fields => switch (section) {
        'recipients' => {
            'name': 'اسم المستلم',
            'phone': 'رقم الهاتف',
            'address': 'العنوان',
            'preferences': 'تفضيلات الهدية'
          },
        'occasions' => {'name': 'اسم المناسبة', 'date': 'تاريخ المناسبة'},
        _ => {
            'name': 'اسم العنوان',
            'city': 'المحافظة',
            'address': 'العنوان التفصيلي'
          },
      };
  Future<void> editItem([Map<String, Object?>? item]) async {
    final value = await form(item == null ? 'إضافة' : 'تعديل', fields,
        initial: item ?? {}, optional: {'preferences'});
    if (value == null || !mounted) return;
    final rows = CustomerAccountService.rows(data);
    final id = item?['id'] ?? DateTime.now().microsecondsSinceEpoch.toString();
    final index = rows.indexWhere((r) => r['id'] == id);
    final row = {...value, 'id': id};
    if (index < 0) {
      rows.add(row);
    } else {
      rows[index] = row;
    }
    await perform(() => service!.save(section, {...data, 'items': rows}));
  }

  Future<void> remove(Map<String, Object?> item) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) =>
            AlertDialog(title: const Text('حذف هذا السجل؟'), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('إلغاء')),
              TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('حذف'))
            ]));
    if (yes != true || !mounted) return;
    final rows = CustomerAccountService.rows(data)
      ..removeWhere((r) => r['id'] == item['id']);
    await perform(() => service!.save(section, {
          ...data,
          'items': rows,
          if (data['defaultId'] == item['id']) 'defaultId': null
        }));
  }

  Future<void> submitRequest() async {
    final kind = requestKind!;
    final fields = kind == 'support'
        ? {'subject': 'الموضوع', 'details': 'تفاصيل الطلب أو الشكوى'}
        : kind == 'store'
            ? {
                'storeName': 'اسم المتجر',
                'city': 'المحافظة',
                'address': 'العنوان',
                'details': 'نوع المنتجات'
              }
            : {
                'city': 'المحافظة',
                'vehicle': 'نوع المركبة',
                'plate': 'رقم اللوحة'
              };
    final result = await form('طلب جديد', fields);
    if (result == null || !mounted) return;
    await perform(() => service!.submit(kind, result));
  }

  List<Widget> content() {
    if (requestKind != null) {
      return [
        if (widget.state.isDemo)
          info('نسخة محلية',
              'تُحفظ الطلبات على هذا الهاتف وتظهر في حساب سوبر أدمن عند التبديل إليه.'),
        button(
            requestKind == 'support' ? 'إرسال طلب للدعم' : 'تقديم طلب انضمام',
            submitRequest),
        if (requests.isEmpty) info('طلباتي', 'لا توجد طلبات'),
        for (final r in requests)
          info('${(r['fields'] as Map?)?.values.firstOrNull ?? 'طلب'}',
              'الحالة: ${r['status'] == 'pending' ? 'بانتظار المراجعة' : r['status']}\n${r['createdAt']}\n${r['reply'] ?? ''}'),
        if (requestKind == 'support') ...[
          const ExpansionTile(title: Text('كيف أدفع؟'), children: [
            ListTile(title: Text('الدفع نقدًا عند استلام الطلب.'))
          ]),
          const ExpansionTile(title: Text('كيف أتابع طلبي؟'), children: [
            ListTile(
                title: Text(
                    'افتح طلباتي للاطلاع على حالة الطلب والتواصل مع المتجر.'))
          ]),
        ],
      ];
    }
    if (['recipients', 'occasions', 'addresses'].contains(section)) {
      final rows = CustomerAccountService.rows(data);
      return [
        if (section == 'occasions')
          info('المناسبات القادمة',
              'التذكير هنا داخل التطبيق؛ لا توجد تنبيهات خلفية مجدولة.'),
        button('إضافة', () => editItem()),
        if (rows.isEmpty)
          info('لا توجد سجلات', 'أضف أول سجل ليبقى محفوظًا في حسابك'),
        for (final row in rows)
          Card(
              child: Column(children: [
            ListTile(
                title: Text('${row['name']}'),
                subtitle: Text(fields.keys
                    .where((k) => k != 'name')
                    .map((k) => '${row[k] ?? ''}')
                    .where((v) => v.isNotEmpty)
                    .join('\n')),
                onTap: saving ? null : () => editItem(row)),
            Wrap(children: [
              TextButton(
                  onPressed: saving ? null : () => editItem(row),
                  child: const Text('تعديل')),
              TextButton(
                  onPressed: saving ? null : () => remove(row),
                  child: const Text('حذف')),
              if (section == 'addresses')
                TextButton(
                    onPressed: saving
                        ? null
                        : () => perform(() => service!
                            .save(section, {...data, 'defaultId': row['id']})),
                    child: Text(data['defaultId'] == row['id']
                        ? 'العنوان الافتراضي ✓'
                        : 'تعيين افتراضي')),
            ])
          ])),
      ];
    }
    switch (title) {
      case 'الملف الشخصي':
        return [
          if (data['avatar'] is String)
            Center(
                child: CircleAvatar(
                    radius: 48,
                    backgroundImage:
                        MemoryImage(base64Decode(data['avatar'] as String)))),
          button('تغيير الصورة', photo),
          info('الاسم الكامل',
              '${data['name'] ?? widget.state.user?.name ?? ''}'),
          info('رقم الهاتف', widget.state.user?.phone ?? ''),
          info('البريد الإلكتروني', '${data['email'] ?? 'غير محدد'}'),
          info('تاريخ الميلاد', '${data['birthDate'] ?? 'غير محدد'}'),
          info('الجنس', '${data['gender'] ?? 'غير محدد'}'),
          button('تعديل الملف الشخصي', editProfile),
        ];
      case 'الإعدادات':
      case 'اللغة والعملة':
        return [
          info('اللغة', 'العربية'),
          info('العملة', 'الدينار العراقي (د.ع)'),
          info('اللغات والعملات المتاحة',
              'يدعم التطبيق حاليًا العربية والدينار العراقي.'),
          for (final mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
                title: Text(switch (mode) {
                  ThemeMode.system => 'حسب الجهاز',
                  ThemeMode.light => 'فاتح',
                  ThemeMode.dark => 'داكن'
                }),
                value: mode,
                groupValue: AppTheme.mode.value,
                onChanged: (v) async {
                  await AppTheme.setMode(v!);
                  if (mounted) setState(() {});
                }),
        ];
      case 'مستوى العضوية':
        final account = RewardAccount(data);
        final next = account.lifetime < 500 ? 500 : 1500;
        return [
          info('نوع الحساب', account.membership),
          info('النقاط المتاحة', '${account.points} نقطة'),
          info('إجمالي النقاط المكتسبة', '${account.lifetime} نقطة'),
          if (account.lifetime < 1500) ...[
            LinearProgressIndicator(value: account.lifetime / next),
            info('الترقية القادمة',
                'تبقّت ${next - account.lifetime} نقطة للوصول إلى العضوية ${next == 500 ? 'الفضية' : 'الذهبية'}'),
          ],
          info('طريقة اكتساب النقاط',
              'نقطة لكل 1,000 د.ع من قيمة المنتجات بعد الخصم، بعد تسليم الطلب. رسوم التوصيل لا تمنح نقاطًا.'),
          button(
              'عرض الطلبات',
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => OrdersScreen(state: widget.state)))),
          for (final row in (data['transactions'] as List? ?? [])
              .where((r) => r['type'] == 'earned'))
            info('${row['points']} نقطة',
                '${row['description']} • ${row['orderId']}'),
        ];
      case 'النقاط والكوبونات':
        final account = RewardAccount(data);
        return [
          info('النقاط المتاحة', '${account.points} نقطة'),
          info('الاستبدال',
              '100 نقطة = كوبون خصم 1,000 د.ع. كوبون واحد لكل طلب، ولا يُخصم من رسوم التوصيل.'),
          if (account.points >= 100)
            button('استبدال 100 نقطة بكوبون', () async {
              final rewards =
                  RewardsService(widget.state.repository, service!.user);
              redemptionId ??= rewards.id();
              await perform(() async {
                await rewards.redeem(redemptionId!);
                redemptionId = null;
              });
            })
          else
            info('النقاط المطلوبة',
                'تحتاج إلى ${100 - account.points} نقطة إضافية للاستبدال'),
          if (account.coupons.isEmpty)
            info('الكوبونات', 'لا توجد كوبونات متاحة بعد'),
          for (final coupon in account.coupons)
            Card(
                child: ListTile(
              title: const Text('خصم 1,000 د.ع'),
              subtitle: Text('${coupon['code']}'),
              trailing: TextButton(
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: '${coupon['code']}'));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ الكوبون')));
                    }
                  },
                  child: const Text('نسخ')),
            )),
          if (account.coupons.isNotEmpty)
            button('استخدام كوبون عند إتمام الطلب', () {
              if (widget.state.cart.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'أضف منتجات إلى السلة أولًا، ثم اختر كوبونك عند الدفع')));
                return;
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CheckoutScreen(state: widget.state)));
            }),
          for (final row in (data['transactions'] as List? ?? [])
              .where((r) => r['type'] == 'redeem' || r['type'] == 'coupon'))
            info('${row['description']}', '${row['createdAt']}'),
        ];
      case 'المحفظة':
        final account = RewardAccount(data);
        return [
          info('الرصيد المتاح', '${account.balance} د.ع'),
          info('استخدام الرصيد',
              'فعّل استخدام المحفظة عند إتمام الطلب. يُخصم الرصيد ويُدفع المبلغ المتبقي نقدًا.'),
          button('استخدام الرصيد', () {
            if (widget.state.cart.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('أضف منتجات إلى السلة ثم فعّل المحفظة عند الدفع')));
              return;
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CheckoutScreen(state: widget.state)));
          }),
          button(
              'طلب إضافة رصيد من الإدارة',
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CustomerAccountScreen(
                          state: widget.state, title: 'المساعدة والشكاوى')))),
          info('سجل المحفظة', 'آخر 100 حركة مسجلة للحساب'),
          for (final row in (data['transactions'] as List? ?? [])
              .where((r) => r['type'] == 'credit' || r['type'] == 'debit'))
            info('${row['amount']} د.ع • ${row['description']}',
                '${row['createdAt']}'),
        ];
      case 'طرق الدفع':
        return [
          info('الدفع نقدًا عند الاستلام',
              'هذه الطريقة مستخدمة فعليًا عند إتمام الطلب.')
        ];
      case 'سجل الهدايا':
        return [
          info('الطلبات المرسلة', '${widget.state.orders.length}'),
          info('إجمالي الطلبات غير الملغاة',
              '${widget.state.orders.where((o) => o.status != OrderStatus.cancelled).fold<int>(0, (s, o) => s + o.total)} د.ع'),
          button(
              'عرض الطلبات وتفاصيل الإهداء',
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => OrdersScreen(state: widget.state))))
        ];
      case 'تقييماتي':
        final ids = widget.state.orders
            .expand((o) => o.items)
            .map((i) => i.product.storeId)
            .toSet();
        return [
          if (ids.isEmpty)
            info('لا توجد طلبات للتقييم', 'ستظهر متاجر طلباتك هنا'),
          for (final id in ids)
            ExpansionTile(
                title: Text(widget.state.stores
                        .where((s) => s.id == id)
                        .firstOrNull
                        ?.name ??
                    id),
                children: [StoreReviewsPanel(state: widget.state, storeId: id)])
        ];
      case 'خصوصية الهدية':
        return [
          SwitchListTile(
              title: const Text('حفظ آخر رسالة إهداء'),
              subtitle:
                  const Text('تعبئة رسالتك المحفوظة تلقائيًا في الطلب القادم'),
              value: data['saveGiftMessage'] == true,
              onChanged: saving || service == null
                  ? null
                  : (value) => perform(() => service!.save('preferences', {
                        ...data,
                        'saveGiftMessage': value,
                        if (!value) 'lastGiftMessage': '',
                      }))),
          info('معلومات التوصيل',
              'اسم المستلم ورقمه وعنوانه ورسالة الإهداء تصل إلى المتجر لتنفيذ الطلب.'),
        ];
      case 'الخصوصية والإشعارات':
        return [
          info('إشعارات الجهاز',
              'اسمح للتطبيق بإرسال إشعارات الطلبات من خلال نافذة أذونات النظام.'),
          if (widget.state.repository is FirebaseRepository)
            button('إدارة إذن الإشعارات', () async {
              try {
                final settings =
                    await FirebaseMessaging.instance.requestPermission();
                if (!mounted) return;
                final enabled = settings.authorizationStatus ==
                        AuthorizationStatus.authorized ||
                    settings.authorizationStatus ==
                        AuthorizationStatus.provisional;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(enabled
                        ? 'إشعارات الجهاز مسموحة'
                        : 'الإشعارات غير مسموحة. يمكنك تغيير الإذن من إعدادات الجهاز.')));
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تعذر طلب الإذن. راجع إعدادات الجهاز.')));
                }
              }
            })
          else
            info('نسخة محلية', 'الإشعارات البعيدة تتطلب النسخة المتصلة.'),
        ];
      case 'الأجهزة والجلسات':
        return [
          info('الجلسة الحالية', 'أنت مسجل الدخول على هذا الجهاز'),
          info('الجلسات الأخرى', 'إدارة الأجهزة الأخرى غير متاحة حاليًا'),
          button('تسجيل الخروج من هذا الجهاز', () async {
            await widget.state.logout();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => WelcomeScreen(state: widget.state)),
                (_) => false);
          })
        ];
      case 'دعوة الأصدقاء':
        return [
          info('دعوة الأصدقاء',
              'شارك اسم التطبيق مع أصدقائك. برنامج نقاط الدعوات غير مفعّل حاليًا.'),
          button('نسخ نص الدعوة', () async {
            await Clipboard.setData(const ClipboardData(
                text: 'انضم إليّ في أزهارنا، تطبيق الورد والهدايا.'));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ نص الدعوة')));
            }
          })
        ];
      case 'الشروط ومعلومات التطبيق':
        return [
          info('عن أزهارنا',
              'تطبيق عراقي لطلب الورد والهدايا من المتاجر ومتابعة التوصيل.'),
          info('شروط الاستخدام وسياسة الخصوصية',
              'لم تُنشر وثائق معتمدة داخل التطبيق حتى الآن. يمكنك التواصل عبر المساعدة والشكاوى.')
        ];
      default:
        return [
          info(title, 'هذه الخدمة تحتاج ربطًا بالخدمة المتصلة قبل استخدامها.')
        ];
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: TextButton(
                      onPressed: load, child: Text('$error\nإعادة المحاولة')))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  if (service == null)
                    info('تسجيل الدخول مطلوب', 'سجّل الدخول لحفظ بيانات حسابك'),
                  if (saving) const LinearProgressIndicator(),
                  ...content(),
                ]));
}

class _AccountForm extends StatefulWidget {
  final String title;
  final Map<String, String> fields;
  final Map<String, Object?> initial;
  final Set<String> optional;
  const _AccountForm(
      {required this.title,
      required this.fields,
      required this.initial,
      required this.optional});
  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final key = GlobalKey<FormState>();
  late final controllers = {
    for (final k in widget.fields.keys)
      k: TextEditingController(text: '${widget.initial[k] ?? ''}')
  };
  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.title),
          content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                  child: Form(
                      key: key,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final e in widget.fields.entries)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: e.key == 'gender'
                                  ? DropdownButtonFormField<String>(
                                      initialValue: [
                                        '',
                                        'ذكر',
                                        'أنثى'
                                      ].contains(controllers[e.key]!.text)
                                          ? controllers[e.key]!.text
                                          : '',
                                      decoration:
                                          InputDecoration(labelText: e.value),
                                      items: ['', 'ذكر', 'أنثى']
                                          .map((v) => DropdownMenuItem(
                                              value: v,
                                              child: Text(
                                                  v.isEmpty ? 'غير محدد' : v)))
                                          .toList(),
                                      onChanged: (v) =>
                                          controllers[e.key]!.text = v ?? '')
                                  : TextFormField(
                                      controller: controllers[e.key],
                                      maxLength:
                                          e.key == 'details' ? 2000 : 300,
                                      keyboardType: e.key == 'phone'
                                          ? TextInputType.phone
                                          : e.key == 'email'
                                              ? TextInputType.emailAddress
                                              : TextInputType.text,
                                      readOnly: e.key == 'date' ||
                                          e.key == 'birthDate',
                                      onTap: e.key == 'date' ||
                                              e.key == 'birthDate'
                                          ? () async {
                                              final now = DateTime.now();
                                              final date = await showDatePicker(
                                                  context: context,
                                                  initialDate:
                                                      DateTime.tryParse(
                                                              controllers[
                                                                      e.key]!
                                                                  .text) ??
                                                          now,
                                                  firstDate: DateTime(1900),
                                                  lastDate: e.key == 'birthDate'
                                                      ? now
                                                      : DateTime(
                                                          now.year + 20));
                                              if (date != null) {
                                                controllers[e.key]!.text = date
                                                    .toIso8601String()
                                                    .split('T')
                                                    .first;
                                              }
                                            }
                                          : null,
                                      decoration:
                                          InputDecoration(labelText: e.value),
                                      validator: (v) {
                                        final text = v?.trim() ?? '';
                                        if (text.isEmpty) {
                                          return widget.optional.contains(e.key)
                                              ? null
                                              : 'هذا الحقل مطلوب';
                                        }
                                        if (e.key == 'phone' &&
                                            !RegExp(r'^\+9647[0-9]{9}$')
                                                .hasMatch(accountPhone(text))) {
                                          return 'أدخل رقم هاتف عراقي صحيح';
                                        }
                                        if (e.key == 'email' &&
                                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                .hasMatch(text)) {
                                          return 'البريد الإلكتروني غير صالح';
                                        }
                                        return null;
                                      })),
                      ])))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () {
                  if (key.currentState!.validate()) {
                    Navigator.pop(context, {
                      for (final e in controllers.entries)
                        e.key: e.value.text.trim()
                    });
                  }
                },
                child: const Text('حفظ'))
          ]);
}
