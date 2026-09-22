import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationSettingsAction { app, location }

class DeviceLocationException implements Exception {
  final String message;
  final LocationSettingsAction? settingsAction;
  const DeviceLocationException(this.message, [this.settingsAction]);
}

class DeviceLocation {
  const DeviceLocation();

  Future<LatLng> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceLocationException(
          'خدمة الموقع مغلقة. شغّل الموقع ثم اضغط موقعي مجددًا.',
          LocationSettingsAction.location);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
          'اسمح لأزهارنا باستخدام الموقع من إعدادات التطبيق ثم أعد المحاولة.',
          LocationSettingsAction.app);
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const DeviceLocationException(
          'لم يُسمح بالوصول إلى الموقع. يمكنك إعادة المحاولة والسماح أثناء استخدام التطبيق.');
    }
    try {
      final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 25)));
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      throw const DeviceLocationException(
          'تعذر تحديد موقعك خلال المهلة. انتقل إلى مكان بإشارة أفضل وأعد المحاولة.');
    } on LocationServiceDisabledException {
      throw const DeviceLocationException(
          'شغّل خدمة الموقع ثم أعد المحاولة.', LocationSettingsAction.location);
    } on PermissionDeniedException {
      throw const DeviceLocationException(
          'تحقق من إذن الموقع في إعدادات التطبيق ثم أعد المحاولة.',
          LocationSettingsAction.app);
    }
  }

  Future<bool> openSettings(LocationSettingsAction action) =>
      action == LocationSettingsAction.app
          ? Geolocator.openAppSettings()
          : Geolocator.openLocationSettings();
}
