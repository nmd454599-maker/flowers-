import 'package:flutter/material.dart';
import '../../widgets/account_value_sheet.dart';

class AccountFeatureScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> items;
  final bool editable;
  final Future<void> Function(List<(String, String)>)? onSave;
  final Future<void> Function()? onDeleteAccount;
  const AccountFeatureScreen(
      {super.key,
      required this.title,
      required this.icon,
      required this.items,
      this.onDeleteAccount,
      this.onSave,
      this.editable = false});
  @override
  State<AccountFeatureScreen> createState() => _AccountFeatureScreenState();
}

class _AccountFeatureScreenState extends State<AccountFeatureScreen> {
  late final List<(String, String)> values = [...widget.items];
  bool changed = false;
  bool deleting = false;
  bool deletionRequested = false;

  Future<void> edit(int index) async {
    if (!widget.editable || widget.onSave == null) return;
    final value = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        constraints: const BoxConstraints(maxWidth: 560),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => AccountValueSheet(
            title: values[index].$1, initialValue: values[index].$2));
    if (!mounted) return;
    if (value != null && value.isNotEmpty) {
      setState(() {
        values[index] = (values[index].$1, value);
        changed = true;
      });
    }
  }

  Future<void> save() async {
    if (widget.onSave == null) return;
    try {
      await widget.onSave!(List.unmodifiable(values));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر حفظ التغييرات')));
      return;
    }
    if (!mounted) return;
    setState(() => changed = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات بنجاح')));
  }

  Future<void> deleteAccount() async {
    if (deleting || deletionRequested || widget.onDeleteAccount == null) return;
    final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('حذف الحساب؟'),
                content: const Text(
                    'سيُحذف حسابك وبيانات ملفك ومحادثات طلباتك بعد اكتمال الطلبات والاستردادات المفتوحة. ستُزال بيانات الاتصال من سجلات المعاملات المتبقية. لن تتمكن من إنشاء طلبات جديدة، ولا يمكن التراجع من التطبيق بعد إرسال طلب الحذف.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء')),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('متابعة'))
                ]));
    if (approved == true && mounted) {
      setState(() => deleting = true);
      try {
        await widget.onDeleteAccount!();
        if (!mounted) return;
        setState(() => deletionRequested = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'تم تسجيل طلب الحذف. يمكنك متابعة طلباتك الحالية حتى اكتمالها.')));
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', ''))));
      } finally {
        if (mounted) setState(() => deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: [
          if (widget.editable && widget.onSave != null)
            TextButton(
                onPressed: changed ? save : null, child: const Text('حفظ'))
        ]),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          Container(
              width: 88,
              height: 88,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle),
              child: Icon(widget.icon,
                  size: 40, color: Theme.of(context).colorScheme.primary)),
          ...List.generate(
              values.length,
              (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow)),
                      child: ListTile(
                          onTap: () => edit(i),
                          title: Text(values[i].$1,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(values[i].$2,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                          trailing: widget.editable
                              ? const Icon(Icons.edit_outlined, size: 19)
                              : const Icon(Icons.chevron_left_rounded))))),
          if (widget.title == 'طرق الدفع')
            Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18)),
                child: const Row(children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF896016)),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text('الدفع المتاح حاليًا نقدًا عند الاستلام.',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF654814))))
                ])),
          if (widget.title == 'حذف الحساب')
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary),
                    onPressed: deleting ||
                            deletionRequested ||
                            widget.onDeleteAccount == null
                        ? null
                        : deleteAccount,
                    child: Text(deleting
                        ? 'جارٍ إرسال الطلب…'
                        : deletionRequested
                            ? 'تم تسجيل طلب الحذف'
                            : 'طلب حذف الحساب نهائياً'))),
        ]),
      );
}
