import 'dart:math';
import '../../domain/accounts/reward_account.dart';
import '../../services/customer_account_service.dart';
import '../../domain/accounts/account_identity.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import 'order_success_screen.dart';
import 'order_review_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final AppState state;
  const CheckoutScreen({super.key, required this.state});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final recipient = TextEditingController();
  final phone = TextEditingController();
  final message = TextEditingController();
  final addressDetails = TextEditingController();
  String area = 'الكرادة';
  String time = 'أقرب وقت متاح';
  int card = -1;
  bool submitting = false;

  List<Map<String, Object?>> savedRecipients = [], savedAddresses = [];
  String? accountLoadError;
  Map<String, Object?> giftPreferences = {};
  RewardAccount rewards = RewardAccount({});
  String? selectedCoupon;
  bool useWallet = false;
  @override
  void initState() {
    super.initState();
    loadSavedDetails();
  }

  Future<void> loadSavedDetails() async {
    final user = widget.state.user;
    if (user == null) return;
    try {
      final service = CustomerAccountService(widget.state.repository, user);
      final people = await service.read('recipients');
      final addresses = await service.read('addresses');
      final prefs = await service.read('preferences');
      final benefits = await service.read('benefits');
      if (!mounted || widget.state.user?.id != user.id) return;
      setState(() {
        giftPreferences = prefs;
        rewards = RewardAccount(benefits);
        if (prefs['saveGiftMessage'] == true && message.text.isEmpty) {
          message.text = prefs['lastGiftMessage'] as String? ?? '';
        }
        savedRecipients = CustomerAccountService.rows(people);
        savedAddresses = CustomerAccountService.rows(addresses);
        final selected = savedAddresses
            .where((r) => r['id'] == addresses['defaultId'])
            .firstOrNull;
        if (selected != null && addressDetails.text.isEmpty) {
          addressDetails.text = '${selected['city']}، ${selected['address']}';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => accountLoadError =
            'تعذر تحميل البيانات المحفوظة. يمكنك إدخالها يدويًا.');
      }
    }
  }

  int get discount => selectedCoupon == null ? 0 : 1000;
  int get walletAmount =>
      useWallet ? min(rewards.balance, widget.state.cartTotal - discount) : 0;
  int get total => widget.state.cartTotal - discount - walletAmount;

  @override
  void dispose() {
    recipient.dispose();
    phone.dispose();
    message.dispose();
    addressDetails.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('إتمام الطلب')),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
            children: [
              const _Title('بطاقة الإهداء', 'اختياري ويمكنك تخطيه'),
              const SizedBox(height: 12),
              SizedBox(
                  height: 118,
                  child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => GestureDetector(
                          onTap: () =>
                              setState(() => card = card == i ? -1 : i),
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 145,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  gradient:
                                      LinearGradient(colors: _cardColors[i]),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: card == i
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.transparent,
                                      width: 3)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(_cardIcons[i], color: Colors.white),
                                    const Spacer(),
                                    Text(_cardNames[i],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800)),
                                    Text(
                                        card == i
                                            ? 'تم الاختيار'
                                            : 'اختر البطاقة',
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 9))
                                  ]))))),
              const SizedBox(height: 12),
              TextField(
                  controller: message,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'رسالة الإهداء',
                      hintText: 'اكتب رسالتك أو اتركها فارغة',
                      prefixIcon: Icon(Icons.edit_note_rounded))),
              const _Gap(),
              const _Title('معلومات التوصيل', 'بيانات المستلم'),
              if (accountLoadError != null) Text(accountLoadError!),
              if (savedRecipients.isNotEmpty)
                DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'اختيار شخص محفوظ'),
                    items: savedRecipients
                        .map((r) => DropdownMenuItem(
                            value: '${r['id']}', child: Text('${r['name']}')))
                        .toList(),
                    onChanged: (id) {
                      final r =
                          savedRecipients.firstWhere((r) => r['id'] == id);
                      recipient.text = '${r['name']}';
                      phone.text = '${r['phone']}';
                      addressDetails.text = '${r['address']}';
                    }),
              if (savedAddresses.isNotEmpty)
                DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'اختيار عنوان محفوظ'),
                    items: savedAddresses
                        .map((r) => DropdownMenuItem(
                            value: '${r['id']}', child: Text('${r['name']}')))
                        .toList(),
                    onChanged: (id) {
                      final r = savedAddresses.firstWhere((r) => r['id'] == id);
                      addressDetails.text = '${r['city']}، ${r['address']}';
                    }),
              const SizedBox(height: 10),
              TextField(
                  controller: recipient,
                  decoration: const InputDecoration(
                      labelText: 'اسم المستلم',
                      prefixIcon: Icon(Icons.person_outline_rounded))),
              const SizedBox(height: 10),
              TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      hintText: '07XX XXX XXXX',
                      prefixIcon: Icon(Icons.phone_iphone_rounded))),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                  initialValue: area,
                  decoration: const InputDecoration(
                      labelText: 'منطقة التوصيل',
                      prefixIcon: Icon(Icons.location_on_outlined)),
                  items: ['الكرادة', 'المنصور', 'زيونة', 'الجادرية', 'الأعظمية']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => area = v!)),
              const SizedBox(height: 10),
              TextField(
                  controller: addressDetails,
                  maxLength: 300,
                  decoration: const InputDecoration(
                      labelText: 'العنوان التفصيلي وأقرب نقطة دالة')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                  initialValue: time,
                  decoration: const InputDecoration(
                      labelText: 'وقت التوصيل',
                      prefixIcon: Icon(Icons.schedule_rounded)),
                  items: ['أقرب وقت متاح']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => time = v!)),
              const _Gap(),
              const _Title('طريقة الدفع', 'اختر الطريقة المناسبة'),
              if (rewards.coupons.isNotEmpty &&
                  widget.state.cartSubtotal >= 1000)
                DropdownButtonFormField<String>(
                    key: const Key('checkout-coupon'), isExpanded: true,
                    initialValue: selectedCoupon ?? '',
                    decoration: const InputDecoration(labelText: 'كوبون الخصم'),
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('بدون كوبون')),
                      ...rewards.coupons.map((c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Text('خصم 1,000 د.ع • ${c['code']}', overflow: TextOverflow.ellipsis)))
                    ],
                    onChanged: submitting
                        ? null
                        : (v) => setState(
                            () => selectedCoupon = v == '' ? null : v)),
              SwitchListTile(
                  key: const Key('checkout-wallet'),
                  title: const Text('استخدام رصيد المحفظة'),
                  subtitle: Text('الرصيد المتاح: ${rewards.balance} د.ع'),
                  value: useWallet,
                  onChanged: submitting || rewards.balance == 0
                      ? null
                      : (v) => setState(() => useWallet = v)),
              const SizedBox(height: 10),
              const ListTile(
                  leading: Icon(Icons.payments_outlined),
                  title: Text('الدفع عند الاستلام'),
                  subtitle: Text('نقداً عند وصول الطلب')),
              const _Gap(),
              const _Title('ملخص الطلب', 'تفاصيل المبلغ'),
              const SizedBox(height: 10),
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLow)),
                  child: Column(children: [
                    _Price('المجموع', widget.state.cartSubtotal),
                    const SizedBox(height: 9),
                    _Price('رسم التوصيل', widget.state.deliveryFee),
                    const Divider(height: 24),
                    if (discount > 0) _Price('خصم الكوبون', -discount),
                    if (walletAmount > 0) _Price('من المحفظة', -walletAmount),
                    _Price('المطلوب نقدًا', total, bold: true),
                  ])),
              const SizedBox(height: 18),
              FilledButton(
                  onPressed: submitting ? null : _confirm,
                  child: Text(submitting
                      ? 'جارٍ تأكيد الطلب…'
                      : 'مراجعة الطلب • $total د.ع')),
            ]),
      );

  Future<void> _confirm() async {
    if (submitting) return;
    final normalizedPhone = accountPhone(phone.text);
    if (recipient.text.trim().isEmpty ||
        !RegExp(r'^\+9647[0-9]{9}$').hasMatch(normalizedPhone) ||
        addressDetails.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('أدخل اسم المستلم ورقم هاتف عراقي صحيح والعنوان التفصيلي')));
      return;
    }
    setState(() => submitting = true);
    try {
      final approved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => OrderReviewScreen(
                    state: widget.state,
                    discount: discount,
                    walletUsed: walletAmount,
                    recipient: recipient.text.trim(),
                    phone: normalizedPhone,
                    address:
                        '${widget.state.selectedCity} - $area، ${addressDetails.text.trim()}',
                    schedule: time,
                    gift:
                        '${card < 0 ? 'بدون بطاقة' : _cardNames[card]}\n${message.text.trim()}',
                  )));
      if (!mounted || approved != true) return;
      final order = await widget.state.checkout(
        '${widget.state.selectedCity} - $area، العنوان: ${addressDetails.text.trim()}، المستلم: ${recipient.text.trim()}، الهاتف: $normalizedPhone، الموعد: $time، بطاقة الإهداء: ${card < 0 ? 'بدون' : _cardNames[card]}، رسالة الإهداء: ${message.text.trim()}',
        paymentMethod: PaymentMethod.cash,
        couponId: selectedCoupon,
        discount: discount,
        walletUsed: walletAmount,
      );
      if (!mounted) return;
      final current = widget.state.user;
      if (current != null && giftPreferences['saveGiftMessage'] == true) {
        try {
          await CustomerAccountService(widget.state.repository, current)
              .save('preferences', {
            ...giftPreferences,
            'lastGiftMessage': message.text.trim(),
          });
        } catch (_) {
          // The order is already confirmed; saving an optional draft must not retry checkout.
        }
      }
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.state.errorMessage ?? 'تعذر تأكيد الطلب')));
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  static const _cardNames = ['حب', 'عيد ميلاد', 'شكراً', 'مبارك'];
  static const _cardIcons = [
    Icons.favorite_rounded,
    Icons.cake_outlined,
    Icons.volunteer_activism_outlined,
    Icons.celebration_outlined
  ];
  static const _cardColors = [
    [Color(0xFF7A174F), Color(0xFF3B0425)],
    [Color(0xFFFF8B7F), Color(0xFFB73855)],
    [Color(0xFFB89563), Color(0xFF755031)],
    [Color(0xFF8067B7), Color(0xFF4A326F)]
  ];
}

class _Title extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Title(this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800))),
        Text(subtitle,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant))
      ]);
}

class _Gap extends StatelessWidget {
  const _Gap();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 27);
}

class _Price extends StatelessWidget {
  final String label;
  final int amount;
  final bool bold;
  const _Price(this.label, this.amount, {this.bold = false});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
        Text('${amount < 0 ? '-${-amount}' : amount} د.ع',
            style: TextStyle(
                fontSize: bold ? 19 : 14,
                color: bold ? Theme.of(context).colorScheme.primary : null,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600))
      ]);
}
