import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

class StoreApplicationsScreen extends StatefulWidget {
  final AppState state;
  const StoreApplicationsScreen({super.key, required this.state});
  @override
  State<StoreApplicationsScreen> createState() =>
      _StoreApplicationsScreenState();
}

class _StoreApplicationsScreenState extends State<StoreApplicationsScreen> {
  List<AdminRecord> records = [];
  bool loading = true;
  String? error;
  final reviewing = <String>{};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data =
          await widget.state.repository.fetchAdminRecords('store_applications');
      if (mounted) setState(() => records = data);
    } catch (_) {
      if (mounted) {
        setState(
            () => error = 'تعذر تحميل الطلبات. تحقق من الاتصال وأعد المحاولة.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('طلبات تسجيل المتاجر'), actions: [
        IconButton(
            tooltip: 'تحديث الطلبات',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded)),
      ]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, textAlign: TextAlign.center))
              : records.isEmpty
                  ? const Center(child: Text('لا توجد طلبات جديدة'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: records.length,
                          itemBuilder: (_, i) => _card(records[i]))));
  Widget _card(AdminRecord record) {
    final d = record.data;
    final status = d['status']?.toString() ?? 'pending';
    final icon = _icon(d['specialty']?.toString());
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
            padding: const EdgeInsets.all(15),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                    radius: 27,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Icon(icon, color: const Color(0xFF087E9A))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${d['name'] ?? 'متجر'}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      Text('${d['specialty'] ?? ''} • ${d['phone'] ?? ''}')
                    ])),
                Chip(
                    label: Text(status == 'approved'
                        ? 'مقبول'
                        : status == 'rejected'
                            ? 'مرفوض'
                            : 'قيد المراجعة'))
              ]),
              const Divider(),
              Text('العنوان: ${d['address'] ?? ''}'),
              if ('${d['instagram'] ?? ''}'.isNotEmpty)
                Text('Instagram: ${d['instagram']}'),
              if ('${d['facebook'] ?? ''}'.isNotEmpty)
                Text('Facebook: ${d['facebook']}'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: () => _showMap(d, icon),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('عرض الموقع على الخريطة')),
              if (status == 'pending')
                Row(children: [
                  Expanded(
                      child: FilledButton.icon(
                          onPressed: reviewing.contains(record.id)
                              ? null
                              : () => _review(record, true),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('موافقة ونشر'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: reviewing.contains(record.id)
                              ? null
                              : () => _review(record, false),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('رفض')))
                ])
            ])));
  }

  IconData _icon(String? value) => switch (value) {
        'معجنات' => Icons.bakery_dining_rounded,
        'حلويات' => Icons.cake_rounded,
        'إكسسوارات' => Icons.watch_outlined,
        'عطور' => Icons.spa_outlined,
        _ => Icons.local_florist_rounded
      };
  Future<void> _review(AdminRecord r, bool approve) async {
    if (reviewing.contains(r.id)) return;
    setState(() => reviewing.add(r.id));
    final updated = Map<String, Object?>.from(r.data)
      ..['status'] = approve ? 'approved' : 'rejected'
      ..['reviewedAt'] = DateTime.now().toIso8601String();
    try {
      await widget.state.repository
          .saveAdminRecord('store_applications', r.id, updated);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(approve
                ? 'تمت الموافقة وسيظهر المتجر على الخريطة'
                : 'تم رفض الطلب')));
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر حفظ القرار، حاول مجدداً')));
    } finally {
      if (mounted) setState(() => reviewing.remove(r.id));
    }
  }

  void _showMap(Map<String, Object?> d, IconData icon) {
    if (d['latitude'] is! num ||
        d['longitude'] is! num ||
        !(d['latitude'] as num).isFinite ||
        !(d['longitude'] as num).isFinite ||
        (d['latitude'] as num).abs() > 90 ||
        (d['longitude'] as num).abs() > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يحدد المتجر موقعاً صالحاً بعد')));
      return;
    }
    final point = LatLng(
        (d['latitude'] as num).toDouble(), (d['longitude'] as num).toDouble());
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => Scaffold(
                appBar: AppBar(title: Text('${d['name']}')),
                body: FlutterMap(
                    options: MapOptions(initialCenter: point, initialZoom: 16),
                    children: [
                      TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.azharna.azharna_pro'),
                      MarkerLayer(markers: [
                        Marker(
                            point: point,
                            width: 70,
                            height: 70,
                            child: CircleAvatar(
                                backgroundColor: const Color(0xFF087E9A),
                                child:
                                    Icon(icon, color: Colors.white, size: 32)))
                      ])
                    ]))));
  }
}
