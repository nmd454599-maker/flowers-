import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../state/app_state.dart';
import '../../widgets/current_location_button.dart';

class StoreLocationScreen extends StatefulWidget {
  final AppState state;
  final bool selectionOnly;
  const StoreLocationScreen(
      {super.key, required this.state, this.selectionOnly = false});
  @override
  State<StoreLocationScreen> createState() => _StoreLocationScreenState();
}

class _StoreLocationScreenState extends State<StoreLocationScreen> {
  final map = MapController();
  final branch = TextEditingController(text: 'الفرع الرئيسي');
  final address = TextEditingController(text: 'بغداد، الكرادة');
  LatLng selected = const LatLng(33.3152, 44.3661);
  bool saving = false;
  @override
  void initState() {
    super.initState();
    if (!widget.selectionOnly) _load();
  }

  Future<void> _load() async {
    try {
      final rows =
          await widget.state.repository.fetchAdminRecords('store_locations');
      final data = rows
          .where((r) => r.data['storeId'] == widget.state.user?.storeId)
          .firstOrNull
          ?.data;
      if (!mounted || data == null) return;
      setState(() {
        branch.text = '${data['branchName'] ?? ''}';
        address.text = '${data['address'] ?? ''}';
        selected = LatLng((data['latitude'] as num).toDouble(),
            (data['longitude'] as num).toDouble());
      });
      map.move(selected, 14);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تحميل الموقع المحفوظ')));
    }
  }

  @override
  void dispose() {
    map.dispose();
    branch.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('موقع المتجر'), actions: [
          TextButton(onPressed: saving ? null : _save, child: const Text('حفظ'))
        ]),
        body: Column(children: [
          Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: const Text(
                  'المس الخريطة لوضع علامة المتجر في موقعه الدقيق',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
              child: Stack(children: [
            FlutterMap(
                mapController: map,
                options: MapOptions(
                    initialCenter: selected,
                    initialZoom: 14,
                    onTap: (_, point) => setState(() => selected = point)),
                children: [
                  TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.azharna.azharna_pro'),
                  MarkerLayer(markers: [
                    Marker(
                        point: selected,
                        width: 70,
                        height: 75,
                        child: const Column(children: [
                          Icon(Icons.location_on_rounded,
                              size: 54, color: Color(0xFF087E9A)),
                          Text('متجري',
                              style: TextStyle(fontWeight: FontWeight.w900))
                        ]))
                  ]),
                ]),
            Positioned(
                top: 12,
                left: 12,
                child: CurrentLocationButton(onLocated: (point) {
                  setState(() => selected = point);
                  map.move(point, 16);
                })),
            Positioned(
                left: 8,
                bottom: 4,
                child: Container(
                    color: Colors.white70,
                    padding: const EdgeInsets.all(3),
                    child: const Text('© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 9)))),
          ])),
          SafeArea(
              top: false,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 12)
                      ]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: branch,
                              decoration: const InputDecoration(
                                  labelText: 'اسم الفرع',
                                  prefixIcon: Icon(Icons.store_outlined)))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: TextField(
                              controller: address,
                              decoration: const InputDecoration(
                                  labelText: 'العنوان',
                                  prefixIcon: Icon(Icons.signpost_outlined))))
                    ]),
                    const SizedBox(height: 8),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                            'الإحداثيات: ${selected.latitude.toStringAsFixed(6)}, ${selected.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey))),
                    const SizedBox(height: 10),
                    SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                            onPressed: saving ? null : _save,
                            icon: saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.add_location_alt_outlined),
                            label: const Text('حفظ موقع المتجر'))),
                  ]))),
        ]),
      );

  Future<void> _save() async {
    if (widget.selectionOnly) {
      Navigator.pop(context, selected);
      return;
    }
    if (branch.text.trim().isEmpty || address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل اسم الفرع والعنوان')));
      return;
    }
    setState(() => saving = true);
    try {
      await widget.state.repository.saveAdminRecord(
          'store_locations', 'location_${widget.state.user?.storeId}', {
        'storeId': widget.state.user?.storeId ?? 's1',
        'branchName': branch.text.trim(),
        'address': address.text.trim(),
        'latitude': selected.latitude,
        'longitude': selected.longitude,
        'updatedAt': DateTime.now().toIso8601String()
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ موقع المتجر بنجاح')));
      Navigator.pop(context, selected);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'تعذر حفظ الموقع. تحقق من الاتصال وصلاحيات المتجر وأعد المحاولة.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
