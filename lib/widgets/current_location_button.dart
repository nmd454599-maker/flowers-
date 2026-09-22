import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/device_location.dart';

class CurrentLocationButton extends StatefulWidget {
  final ValueChanged<LatLng> onLocated;
  final DeviceLocation location;
  const CurrentLocationButton(
      {super.key,
      required this.onLocated,
      this.location = const DeviceLocation()});

  @override
  State<CurrentLocationButton> createState() => _CurrentLocationButtonState();
}

class _CurrentLocationButtonState extends State<CurrentLocationButton> {
  bool locating = false;

  Future<void> locate() async {
    if (locating) return;
    setState(() => locating = true);
    try {
      final point = await widget.location.currentPosition();
      if (mounted) widget.onLocated(point);
    } on DeviceLocationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message),
        duration: const Duration(seconds: 8),
        action: error.settingsAction == null
            ? null
            : SnackBarAction(
                label: 'الإعدادات',
                onPressed: () => openSettings(error.settingsAction!),
              ),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'تعذر الحصول على موقعك. تحقق من إعدادات الموقع وأعد المحاولة.'),
        ));
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> openSettings(LocationSettingsAction action) async {
    try {
      if (await widget.location.openSettings(action)) return;
    } catch (_) {
      // Some platforms cannot open the settings screen programmatically.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('افتح إعدادات الهاتف يدويًا واسمح بالموقع لتطبيق أزهارنا.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
        heroTag: null,
        tooltip: locating ? 'جارٍ تحديد موقعك' : 'تحديد موقعي',
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: const Color(0xFF087E9A),
        onPressed: locating ? null : locate,
        child: locating
            ? const SizedBox.square(
                dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.my_location_rounded),
      );
}
