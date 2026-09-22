import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:azharna_pro/services/device_location.dart';
import 'package:azharna_pro/widgets/current_location_button.dart';

class FakeLocationPlatform extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission requested = LocationPermission.whileInUse;
  int requests = 0;
  int fixes = 0;
  Object? failure;
  LocationSettings? settings;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return requested;
  }

  @override
  Future<Position> getCurrentPosition(
      {LocationSettings? locationSettings}) async {
    fixes++;
    settings = locationSettings;
    if (failure != null) throw failure!;
    return Position(
        latitude: 30.5,
        longitude: 47.8,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0);
  }
}

class PendingDeviceLocation extends DeviceLocation {
  final result = Completer<LatLng>();
  int calls = 0;
  @override
  Future<LatLng> currentPosition() {
    calls++;
    return result.future;
  }
}

void main() {
  late GeolocatorPlatform original;
  late FakeLocationPlatform platform;
  setUp(() {
    original = GeolocatorPlatform.instance;
    platform = FakeLocationPlatform();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  test(
      'requests permission and returns actual coordinates instead of a city center',
      () async {
    final point = await const DeviceLocation().currentPosition();
    expect(point, const LatLng(30.5, 47.8));
    expect(platform.requests, 1);
    expect(platform.settings!.timeLimit, const Duration(seconds: 25));
  });
  test('disabled GPS offers location settings without asking permission',
      () async {
    platform.enabled = false;
    await expectLater(
        const DeviceLocation().currentPosition(),
        throwsA(isA<DeviceLocationException>().having((e) => e.settingsAction,
            'settings', LocationSettingsAction.location)));
    expect(platform.requests, 0);
    expect(platform.fixes, 0);
  });
  test('permanent denial after request offers app settings and never reads GPS',
      () async {
    platform.requested = LocationPermission.deniedForever;
    await expectLater(
        const DeviceLocation().currentPosition(),
        throwsA(isA<DeviceLocationException>().having(
            (e) => e.settingsAction, 'settings', LocationSettingsAction.app)));
    expect(platform.fixes, 0);
  });
  test('ordinary denial stops without reading location', () async {
    platform.requested = LocationPermission.denied;
    await expectLater(const DeviceLocation().currentPosition(),
        throwsA(isA<DeviceLocationException>()));
    expect(platform.fixes, 0);
  });
  test('timeout becomes an actionable Arabic error', () async {
    platform.permission = LocationPermission.whileInUse;
    platform.failure = TimeoutException('timeout');
    await expectLater(
        const DeviceLocation().currentPosition(),
        throwsA(isA<DeviceLocationException>()
            .having((e) => e.message, 'message', contains('المهلة'))));
    expect(platform.requests, 0);
  });
  testWidgets(
      'location button prevents duplicate requests and delivers coordinates',
      (tester) async {
    final location = PendingDeviceLocation();
    LatLng? chosen;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CurrentLocationButton(
                location: location, onLocated: (point) => chosen = point))));
    await tester.tap(find.byTooltip('تحديد موقعي'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    expect(location.calls, 1);
    location.result.complete(const LatLng(30.5, 47.8));
    await tester.pumpAndSettle();
    expect(chosen, const LatLng(30.5, 47.8));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('leaving map during lookup safely discards the result',
      (tester) async {
    final location = PendingDeviceLocation();
    var callbacks = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CurrentLocationButton(
                location: location, onLocated: (_) => callbacks++))));
    await tester.tap(find.byTooltip('تحديد موقعي'));
    await tester.pumpWidget(const SizedBox());
    location.result.complete(const LatLng(30.5, 47.8));
    await tester.pump();
    expect(callbacks, 0);
    expect(tester.takeException(), isNull);
  });
}
