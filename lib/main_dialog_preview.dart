import 'package:flutter/material.dart';
import 'core/app_theme.dart';


void main() => runApp(const DialogPreviewApp());

class _MembershipSample extends StatelessWidget {
  const _MembershipSample({required this.title, required this.icon, required this.items});
  final String title;
  final IconData icon;
  final List<(String, String)> items;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Padding(padding: const EdgeInsets.all(24), child: Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary)),
      for (final item in items) Padding(padding: const EdgeInsets.only(bottom: 12),
        child: Card(child: ListTile(title: Text(item.$1), subtitle: Text(item.$2), trailing: const Icon(Icons.edit_outlined)))),
    ]),
  );
}

enum DialogShape {
  compact('A · صغير', 290, 16, 12),
  wide('B · عريض', 360, 20, 12),
  rounded('C · دائري الحواف', 330, 36, 28),
  sheet('D · لوحة سفلية', 480, 28, 16);

  const DialogShape(this.label, this.width, this.radius, this.fieldRadius);
  final String label;
  final double width;
  final double radius;
  final double fieldRadius;
}

class DialogPreviewApp extends StatelessWidget {
  const DialogPreviewApp({super.key, this.initialShape});
  final DialogShape? initialShape;
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: _Preview(initialShape: initialShape),
      );
}

class _Preview extends StatefulWidget {
  const _Preview({this.initialShape});
  final DialogShape? initialShape;
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  @override
  void initState() {
    super.initState();
    if (widget.initialShape != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => open(widget.initialShape!));
    }
  }

  void open(DialogShape shape) {
    final content = AccountDialogSample(shape: shape);
    if (shape == DialogShape.sheet) {
      showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          constraints: BoxConstraints(maxWidth: shape.width),
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(shape.radius))),
          builder: (_) => content);
    } else {
      showDialog<void>(
          context: context,
          builder: (_) => Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                constraints: BoxConstraints(maxWidth: shape.width),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(shape.radius)),
                child: content,
              ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          SafeArea(
              bottom: false,
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(spacing: 8, children: [
                    for (final shape in DialogShape.values)
                      ActionChip(
                          label: Text(shape.label),
                          onPressed: () => open(shape))
                  ]))),
          const Expanded(
              child: _MembershipSample(
            title: 'مستوى العضوية',
            icon: Icons.workspace_premium_outlined,
            items: [
              ('نوع الحساب', 'عميل ذهبي'),
              ('النقاط', '128'),
              ('الطلبات', '10'),
              ('إجمالي النقاط المكتسبة', '128 نقطة')
            ],
          )),
        ]),
      );
}

/// Isolated visual sample. Does not save or change real account data.
class AccountDialogSample extends StatelessWidget {
  const AccountDialogSample({super.key, required this.shape});
  final DialogShape shape;
  @override
  Widget build(BuildContext context) {
    final compact = shape == DialogShape.compact;
    return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, compact ? 18 : 24, 24,
              24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('نوع الحساب',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: shape == DialogShape.rounded
                        ? TextAlign.center
                        : TextAlign.start),
                SizedBox(height: compact ? 12 : 20),
                TextFormField(
                    initialValue: 'عميل ذهبي',
                    maxLines: shape == DialogShape.rounded ? 2 : 1,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: compact ? 10 : 16),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(shape.fieldRadius),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(shape.fieldRadius),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2)),
                    )),
                SizedBox(height: compact ? 16 : 24),
                Row(children: [
                  Expanded(
                      child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('حفظ'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'))),
                ]),
              ]),
        ));
  }
}
