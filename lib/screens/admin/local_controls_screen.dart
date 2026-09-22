import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../models/models.dart';

class LocalControlsScreen extends StatefulWidget {
  const LocalControlsScreen(
      {super.key, required this.state, required this.platform});
  final AppState state;
  final bool platform;
  @override
  State<LocalControlsScreen> createState() => _LocalControlsScreenState();
}

class _LocalControlsScreenState extends State<LocalControlsScreen> {
  final title = TextEditingController(),
      body = TextEditingController(),
      minimum = TextEditingController(text: '0');
  bool enabled = true, maintenance = false, busy = true;
  String? selected, error;
  List<AdminRecord> records = [];
  String get scope => widget.platform ? 'platform' : 'content';
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    minimum.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      records = await widget.state.repository.fetchAdminRecords(scope);
      if (widget.platform) {
        final data = records.where((r) => r.id == 'settings').firstOrNull?.data;
        maintenance = data?['maintenanceMode'] == true;
        minimum.text = '${data?['minimumOrder'] ?? 0}';
      }
      error = null;
    } catch (_) {
      error = 'تعذر تحميل البيانات';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> save() async {
    if (widget.platform
        ? int.tryParse(minimum.text) == null || int.parse(minimum.text) < 0
        : title.text.trim().isEmpty || body.text.trim().isEmpty) {
      setState(() => error = 'أكمل الحقول بقيم صحيحة');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.state.repository.saveAdminRecord(
          scope,
          widget.platform ? 'settings' : selected,
          widget.platform
              ? {
                  'maintenanceMode': maintenance,
                  'minimumOrder': int.parse(minimum.text)
                }
              : {
                  'title': title.text.trim(),
                  'body': body.text.trim(),
                  'active': enabled,
                  'updatedAt': DateTime.now().toIso8601String()
                });
      if (!widget.platform) {
        selected = null;
        title.clear();
        body.clear();
        enabled = true;
      }
      await load();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
    } catch (_) {
      if (mounted)
        setState(() {
          error = 'تعذر الحفظ';
          busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.platform
              ? 'إعدادات المنصة المحلية'
              : 'المحتوى المنشور للمستخدمين')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (busy) const LinearProgressIndicator(),
        if (error != null) TextButton(onPressed: load, child: Text(error!)),
        if (widget.platform) ...[
          SwitchListTile(
              title: const Text('إيقاف الطلبات الجديدة للصيانة'),
              value: maintenance,
              onChanged: busy ? null : (v) => setState(() => maintenance = v)),
          TextField(
              controller: minimum,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'الحد الأدنى لقيمة المنتجات بالدينار')),
        ] else ...[
          const Text(
              'تظهر الرسائل الفعالة في إشعارات حساب المستخدم والمتجر عند فتحها.'),
          for (final r in records)
            ListTile(
                title: Text('${r.data['title']}'),
                subtitle: Text(r.data['active'] == false ? 'مخفي' : 'منشور'),
                onTap: busy
                    ? null
                    : () => setState(() {
                          selected = r.id;
                          title.text = '${r.data['title']}';
                          body.text = '${r.data['body']}';
                          enabled = r.data['active'] != false;
                        })),
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'العنوان')),
          TextField(
              controller: body,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'المحتوى')),
          SwitchListTile(
              title: const Text('نشر للمستخدمين والمتاجر'),
              value: enabled,
              onChanged: busy ? null : (v) => setState(() => enabled = v)),
          TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                        selected = null;
                        title.clear();
                        body.clear();
                        enabled = true;
                      }),
              child: const Text('رسالة جديدة')),
        ],
        FilledButton(onPressed: busy ? null : save, child: const Text('حفظ')),
      ]));
}
