import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/shared/stores_map_screen.dart';
import 'package:azharna_pro/screens/store/store_location_screen.dart';
import 'device_location_test.dart' show FakeLocationPlatform;

void main() {
  late GeolocatorPlatform original;
  late AppState state;
  setUp(() {
    original = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = FakeLocationPlatform();
    state = AppState(repository: DemoRepository());
  });
  tearDown(() {
    GeolocatorPlatform.instance = original;
    state.dispose();
  });
  testWidgets('customer map centers and marks the device position', (tester) async {
    await tester.pumpWidget(MaterialApp(home: StoresMapScreen(state: state)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تحديد موقعي'));
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.mapController!.camera.center, const LatLng(30.5, 47.8));
    expect(find.byTooltip('موقعي الحالي'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('registration receives GPS coordinates without an admin write', (tester) async {
    LatLng? selected;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) =>
      Scaffold(body: TextButton(onPressed: () async {
        selected = await Navigator.push<LatLng>(context, MaterialPageRoute(
          builder: (_) => StoreLocationScreen(state: state, selectionOnly: true)));
      }, child: const Text('اختر'))))));
    await tester.tap(find.text('اختر'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تحديد موقعي'));
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.mapController!.camera.center, const LatLng(30.5, 47.8));
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(selected, const LatLng(30.5, 47.8));
    expect(await state.repository.fetchAdminRecords('store_locations'), isEmpty);
  });
}
