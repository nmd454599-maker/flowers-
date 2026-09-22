import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/models.dart';
import '../../core/product_assets.dart';
import '../../state/app_state.dart';
import '../../widgets/iraq_map_picker.dart';
import '../../widgets/current_location_button.dart';
import 'store_chat_screen.dart';

class StoresMapScreen extends StatefulWidget {
  final AppState state;
  final bool embedded;
  const StoresMapScreen(
      {super.key, required this.state, this.embedded = false});

  @override
  State<StoresMapScreen> createState() => _StoresMapScreenState();
}

class _StoresMapScreenState extends State<StoresMapScreen> {
  final MapController controller = MapController();
  LatLng? currentLocation;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  List<AdminRecord> approvedMerchantLocations = [];

  @override
  void initState() {
    super.initState();
    widget.state.repository.fetchApprovedStoreApplications().then((items) {
      if (!mounted) return;
      setState(() => approvedMerchantLocations = items);
    });
  }

  static const cityCenters = <String, LatLng>{
    'بغداد': LatLng(33.3152, 44.3661),
    'البصرة': LatLng(30.5085, 47.7804),
    'نينوى': LatLng(36.3456, 43.1575),
    'أربيل': LatLng(36.1911, 44.0092),
    'النجف': LatLng(31.9996, 44.3267),
    'كربلاء': LatLng(32.6160, 44.0249),
    'السليمانية': LatLng(35.5570, 45.4356),
    'دهوك': LatLng(36.8671, 42.9885),
    'كركوك': LatLng(35.4681, 44.3922),
    'الأنبار': LatLng(33.4250, 43.3000),
    'صلاح الدين': LatLng(34.6071, 43.6782),
    'ديالى': LatLng(33.7481, 44.6451),
    'بابل': LatLng(32.4682, 44.5502),
    'واسط': LatLng(32.5128, 45.8182),
    'القادسية': LatLng(31.9889, 44.9255),
    'ميسان': LatLng(31.8389, 47.1440),
    'المثنى': LatLng(31.3188, 45.2806),
    'ذي قار': LatLng(31.0439, 46.2573),
  };

  LatLng get center =>
      cityCenters[widget.state.selectedCity] ?? cityCenters['بغداد']!;

  LatLng _storePoint(int index) {
    final angle = index * 2.39996;
    final ring = .006 + (index % 4) * .0035;
    return LatLng(
      center.latitude + ring * (index.isEven ? 1 : -1),
      center.longitude + ring * .9 * (angle % 2 - 1),
    );
  }

  Future<void> _selectCity() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('اختر المحافظة',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: iraqGovernorates
                    .map((item) => ChoiceChip(
                          label: Text(item.name),
                          selected: item.name == widget.state.selectedCity,
                          onSelected: (_) => Navigator.pop(context, item.name),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    await widget.state.selectCity(chosen);
    controller.move(cityCenters[chosen] ?? center, 12.5);
  }

  void _showStore(Store store) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Image.asset(
                    productImage(store.id == 's3'
                        ? 'p3'
                        : store.id == 's2'
                            ? 'p4'
                            : 'p1'),
                    filterQuality: FilterQuality.high,
                    fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('${store.city} • ${store.deliveryMinutes} دقيقة'),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB21A), size: 18),
                        Text(' ${store.rating}'),
                      ],
                    ),
                    if (widget.state.isDemo)
                      FilledButton.icon(
                        onPressed: () => _openChat(store.id, store.name),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('الدردشة مع المتجر'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(initialCenter: center, initialZoom: 12.5),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.azharna.azharna_pro',
                ),
                MarkerLayer(
                  markers: [
                    if (currentLocation != null)
                      Marker(
                          point: currentLocation!,
                          width: 36,
                          height: 36,
                          child: const Tooltip(
                              message: 'موقعي الحالي',
                              child: Icon(Icons.my_location_rounded,
                                  color: Colors.blue, size: 32))),
                    for (var i = 0; i < widget.state.stores.length; i++)
                      Marker(
                        point: _storePoint(i),
                        width: 40,
                        height: 48,
                        child: GestureDetector(
                          onTap: () => _showStore(widget.state.stores[i]),
                          child: const _StoreMarker(),
                        ),
                      ),
                    for (final record in approvedMerchantLocations)
                      Marker(
                        point: LatLng(
                            (record.data['latitude'] as num).toDouble(),
                            (record.data['longitude'] as num).toDouble()),
                        width: 42,
                        height: 50,
                        child: GestureDetector(
                          key: ValueKey('registered-store-${record.id}'),
                          onTap: () => _showRegisteredStore(record),
                          child: _SpecialtyMarker(
                              specialty:
                                  '${record.data['specialty'] ?? 'ورود'}'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!widget.embedded)
                            Material(
                                color: Theme.of(context).colorScheme.surface,
                                shape: const CircleBorder(),
                                child: BackButton(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                          const Spacer(),
                          Material(
                            color: Theme.of(context).colorScheme.surface,
                            elevation: 2,
                            shadowColor: Colors.black12,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              onTap: _selectCity,
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Text('استكشف هذه المنطقة',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700))),
                            ),
                          ),
                          const Spacer(),
                          CurrentLocationButton(onLocated: (point) {
                            setState(() => currentLocation = point);
                            controller.move(point, 16);
                          }),
                        ]),
                  )),
            ),
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: .82),
                child: const Text('© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 9)),
              ),
            ),
          ],
        ),
      );

  void _showRegisteredStore(AdminRecord record) {
    final data = record.data;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLow,
              child: Icon(_specialtyIcon('${data['specialty']}'),
                  color: const Color(0xFF087E9A)),
            ),
            title: Text('${data['name']}',
                style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(
                '${data['specialty']} • ${data['address']}\n${data['phone']}'),
            isThreeLine: true,
          ),
          if (widget.state.isDemo && data['ownerId'] != widget.state.user?.id)
            Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openChat(record.id, '${data['name']}',
                          ownerId: data['ownerId'] as String?),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('الدردشة مع المتجر'),
                    ))),
        ]),
      ),
    );
  }

  void _openChat(String storeId, String storeName, {String? ownerId}) {
    final user = widget.state.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سجّل الدخول لبدء الدردشة')));
      return;
    }
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StoreChatScreen(
                  state: widget.state,
                  conversation: {
                    'storeId': storeId,
                    'storeName': storeName,
                    'ownerId': ownerId,
                    'customerId': user.id,
                    'customerName': user.name,
                  },
                )));
  }
}

IconData _specialtyIcon(String value) => switch (value) {
      'معجنات' => Icons.bakery_dining_rounded,
      'حلويات' => Icons.cake_rounded,
      'إكسسوارات' => Icons.watch_outlined,
      'عطور' => Icons.spa_outlined,
      _ => Icons.local_florist_rounded,
    };

class _SpecialtyMarker extends StatelessWidget {
  final String specialty;
  const _SpecialtyMarker({required this.specialty});
  @override
  Widget build(BuildContext context) =>
      Stack(alignment: Alignment.topCenter, children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFF5A1742),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 6,
                      offset: Offset(0, 3))
                ]),
            child:
                Icon(_specialtyIcon(specialty), color: Colors.white, size: 18)),
        Positioned(
            top: 33,
            child: Container(
                width: 3,
                height: 11,
                decoration: BoxDecoration(
                    color: const Color(0xFF5A1742),
                    borderRadius: BorderRadius.circular(3)))),
      ]);
}

class _StoreMarker extends StatelessWidget {
  const _StoreMarker();

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF5A1742),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 6,
                    offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.local_florist_rounded,
                color: Colors.white, size: 18),
          ),
          Positioned(
            top: 33,
            child: Container(
                width: 3,
                height: 11,
                decoration: BoxDecoration(
                    color: const Color(0xFF5A1742),
                    borderRadius: BorderRadius.circular(3))),
          ),
        ],
      );
}
