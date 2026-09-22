import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/models.dart';

class WelcomeForm extends StatefulWidget {
  const WelcomeForm(
      {super.key,
      required this.phone,
      required this.role,
      required this.busy,
      required this.onRole,
      required this.onSubmit});
  final TextEditingController phone;
  final UserRole role;
  final bool busy;
  final ValueChanged<UserRole> onRole;
  final VoidCallback onSubmit;
  @override
  State<WelcomeForm> createState() => _WelcomeFormState();
}

class _WelcomeFormState extends State<WelcomeForm> {
  bool register = false;
  static const teal = Color(0xFF007A83);
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final white = dark ? const Color(0xFF1C1C1E) : Colors.white;
    final muted = dark ? const Color(0xFFB0C1C5) : const Color(0xFF747E82);
    final admin = widget.role == UserRole.superAdmin;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxHeight < 500;
          return FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                  width: constraints.maxWidth,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!compact) ...[
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (Navigator.of(context).canPop())
                                    IconButton.filledTonal(
                                        onPressed: widget.busy
                                            ? null
                                            : () => Navigator.maybePop(context),
                                        tooltip: 'رجوع',
                                        style: IconButton.styleFrom(
                                            backgroundColor: white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12))),
                                        icon: const Icon(
                                            Icons.arrow_forward_rounded))
                                  else
                                    const SizedBox(width: 48),
                                  const ThemeModeButton(),
                                ]),
                            const SizedBox(height: 12),
                            Center(
                                child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                        color: teal,
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: const Icon(
                                        Icons.local_florist_rounded,
                                        color: Colors.white,
                                        size: 48))),
                            const SizedBox(height: 8),
                            const Text('أزهارنا',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: teal,
                                    fontSize: 35,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3)),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      width: 24,
                                      child: Divider(
                                          color: muted.withValues(alpha: .4))),
                                  Flexible(
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                              'نوصل الورد، ونقرّب القلوب',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: muted,
                                                  fontSize: 12)))),
                                  SizedBox(
                                      width: 24,
                                      child: Divider(
                                          color: muted.withValues(alpha: .4))),
                                ]),
                            const SizedBox(height: 12),
                            Text(register ? 'أنشئ حسابك' : 'أهلاً بعودتك',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 29, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 5),
                            Text(
                                register
                                    ? 'اختر أجمل الهدايا، وأوصل الفرحة لمن تحب'
                                    : 'سجّل دخولك، وخلي هديتك القادمة تحكي أجمل حكاية',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: muted, fontSize: 15, height: 1.5)),
                            const SizedBox(height: 12),
                          ],
                          Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14)),
                              child: Row(children: [
                                for (final item in [
                                  (false, 'تسجيل الدخول'),
                                  (true, 'إنشاء حساب')
                                ])
                                  Expanded(
                                      child: Semantics(
                                          selected: register == item.$1,
                                          child: TextButton(
                                              onPressed: widget.busy
                                                  ? null
                                                  : () => setState(
                                                      () => register = item.$1),
                                              style: TextButton.styleFrom(
                                                  backgroundColor:
                                                      register == item.$1
                                                          ? white
                                                          : Colors.transparent,
                                                  foregroundColor:
                                                      register == item.$1
                                                          ? teal
                                                          : colors.onSurface,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12))),
                                              child: Text(item.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))))),
                              ])),
                          const SizedBox(height: 14),
                          const Text('رقم الهاتف',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 9),
                          TextField(
                              key: const ValueKey('welcome-phone'),
                              controller: widget.phone,
                              enabled: !widget.busy,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              textDirection: TextDirection.ltr,
                              autofillHints: const [
                                AutofillHints.telephoneNumber
                              ],
                              onSubmitted: (_) {
                                if (!widget.busy) widget.onSubmit();
                              },
                              decoration: InputDecoration(
                                hintText: '0770 123 4567',
                                hintTextDirection: TextDirection.ltr,
                                hintStyle: TextStyle(
                                    color: muted.withValues(alpha: .7),
                                    fontSize: 17),
                                prefixIcon: Icon(Icons.phone_iphone_outlined,
                                    color: muted, size: 23),
                              )),
                          const SizedBox(height: 10),
                          Text('سنرسل لك رمز تحقق برسالة نصية لتأكيد رقمك',
                              style: TextStyle(fontSize: 12, color: muted)),
                          const SizedBox(height: 12),
                          Row(children: [
                            Text('نوع الحساب',
                                style: TextStyle(color: muted, fontSize: 13)),
                            const SizedBox(width: 12),
                            for (final item in [
                              (UserRole.customer, 'عميل'),
                              (UserRole.store, 'متجر')
                            ]) ...[
                              Expanded(
                                  child: ChoiceChip(
                                      label: Center(child: Text(item.$2)),
                                      selected: widget.role == item.$1,
                                      selectedColor:
                                          teal.withValues(alpha: .12),
                                      backgroundColor: white,
                                      side: BorderSide.none,
                                      labelStyle: TextStyle(
                                          color: widget.role == item.$1
                                              ? (dark ? colors.primary : teal)
                                              : muted),
                                      onSelected: widget.busy
                                          ? null
                                          : (_) => widget.onRole(item.$1))),
                              const SizedBox(width: 6),
                            ],
                          ]),
                          const SizedBox(height: 14),
                          FilledButton(
                              onPressed: widget.busy ? null : widget.onSubmit,
                              style: FilledButton.styleFrom(
                                  backgroundColor: teal,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(58),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15))),
                              child: widget.busy
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      admin
                                          ? 'دخول الإدارة'
                                          : register
                                              ? 'إنشاء حساب'
                                              : 'تسجيل الدخول',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600))),
                          if (!compact) ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                  child: Divider(
                                      color: muted.withValues(alpha: .3))),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Icon(Icons.lock_outline_rounded,
                                      size: 17, color: muted)),
                              Expanded(
                                  child: Divider(
                                      color: muted.withValues(alpha: .3)))
                            ]),
                            const SizedBox(height: 14),
                            Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                      register
                                          ? 'لديك حساب بالفعل؟'
                                          : 'ليس لديك حساب؟',
                                      style: TextStyle(
                                          color: muted, fontSize: 14)),
                                  TextButton(
                                      onPressed: widget.busy
                                          ? null
                                          : () => setState(
                                              () => register = !register),
                                      style: TextButton.styleFrom(
                                          foregroundColor:
                                              dark ? colors.primary : teal),
                                      child: Text(register
                                          ? 'تسجيل الدخول'
                                          : 'إنشاء حساب')),
                                ]),
                            Center(
                                child: TextButton(
                                    onPressed: widget.busy
                                        ? null
                                        : () =>
                                            widget.onRole(UserRole.superAdmin),
                                    style: TextButton.styleFrom(
                                        foregroundColor: muted),
                                    child: Text(
                                        admin
                                            ? 'تم اختيار حساب الإدارة'
                                            : 'دخول الإدارة',
                                        style: const TextStyle(fontSize: 12)))),
                          ],
                        ]),
                  )));
        }),
      ))),
    );
  }
}
