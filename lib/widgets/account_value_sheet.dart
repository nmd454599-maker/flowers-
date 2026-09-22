import 'package:flutter/material.dart';

/// Account field editor, using the user's selected bottom sheet layout (11).
class AccountValueSheet extends StatefulWidget {
  const AccountValueSheet(
      {super.key, required this.title, required this.initialValue});
  final String title;
  final String initialValue;

  @override
  State<AccountValueSheet> createState() => _AccountValueSheetState();
}

class _AccountValueSheetState extends State<AccountValueSheet> {
  late final controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 8, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'أدخل القيمة الجديدة',
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          child: const Text('حفظ'))),
                  const SizedBox(width: 20),
                  Expanded(
                      child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'))),
                ]),
              ]),
        ),
      );
}
