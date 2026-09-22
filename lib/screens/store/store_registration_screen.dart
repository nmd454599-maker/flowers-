import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../state/app_state.dart';
import 'store_location_screen.dart';
import '../../widgets/store_profile_photo.dart';

class StoreRegistrationScreen extends StatefulWidget {
  final AppState state;
  const StoreRegistrationScreen({super.key, required this.state});
  @override
  State<StoreRegistrationScreen> createState() =>
      _StoreRegistrationScreenState();
}

class _StoreRegistrationScreenState extends State<StoreRegistrationScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: 'ورود الجوري');
  final phone = TextEditingController(text: '07811234567');
  final address = TextEditingController();
  final instagram = TextEditingController();
  final facebook = TextEditingController();
  final tiktok = TextEditingController();
  final whatsapp = TextEditingController();
  String specialty = 'ورود';
  LatLng? location;
  bool submitting = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final records =
          await widget.state.repository.fetchAdminRecords('store_applications');
      final data = records
          .where((r) => r.data['ownerId'] == widget.state.user?.id)
          .firstOrNull
          ?.data;
      if (data == null || !mounted) return;
      setState(() {
        name.text = '${data['name'] ?? ''}';
        phone.text = '${data['phone'] ?? ''}';
        address.text = '${data['address'] ?? ''}';
        instagram.text = '${data['instagram'] ?? ''}';
        facebook.text = '${data['facebook'] ?? ''}';
        tiktok.text = '${data['tiktok'] ?? ''}';
        whatsapp.text = '${data['whatsapp'] ?? ''}';
        specialty = '${data['specialty'] ?? 'ورود'}';
        if (data['latitude'] is num && data['longitude'] is num)
          location = LatLng((data['latitude'] as num).toDouble(),
              (data['longitude'] as num).toDouble());
      });
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تحميل بيانات المتجر')));
    }
  }

  @override
  void dispose() {
    for (final c in [
      name,
      phone,
      address,
      instagram,
      facebook,
      tiktok,
      whatsapp
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static const specialties = {
    'ورود': Icons.local_florist_rounded,
    'معجنات': Icons.bakery_dining_rounded,
    'حلويات': Icons.cake_rounded,
    'إكسسوارات': Icons.watch_outlined,
    'عطور': Icons.spa_outlined
  };

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('بيانات المتجر')),
      body: Form(
          key: formKey,
          child: ListView(padding: const EdgeInsets.all(18), children: [
            StoreProfilePhoto(
                repository: widget.state.repository,
                storeId: widget.state.user?.storeId),
            const SizedBox(height: 16),
            Center(
                child: CircleAvatar(
                    radius: 47,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Icon(specialties[specialty],
                        size: 48, color: const Color(0xFF087E9A)))),
            const SizedBox(height: 8),
            const Center(
                child: Text('يتغير شعار الخريطة حسب تخصص المتجر',
                    style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 20),
            TextFormField(
                controller: name,
                validator: _required,
                decoration: const InputDecoration(
                    labelText: 'اسم المتجر',
                    prefixIcon: Icon(Icons.storefront_outlined))),
            const SizedBox(height: 12),
            TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                validator: _required,
                decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 12),
            TextFormField(
                controller: address,
                validator: _required,
                decoration: const InputDecoration(
                    labelText: 'العنوان الكامل',
                    prefixIcon: Icon(Icons.signpost_outlined))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                initialValue: specialty,
                decoration: const InputDecoration(
                    labelText: 'تخصص المتجر',
                    prefixIcon: Icon(Icons.category_outlined)),
                items: specialties.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Row(children: [
                          Icon(e.value, size: 20),
                          const SizedBox(width: 8),
                          Text(e.key)
                        ])))
                    .toList(),
                onChanged: (v) => setState(() => specialty = v ?? specialty)),
            const SizedBox(height: 20),
            const Text('صفحات التواصل الاجتماعي',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            _social(instagram, 'رابط Instagram', Icons.camera_alt_outlined),
            _social(facebook, 'رابط Facebook', Icons.facebook_rounded),
            _social(tiktok, 'رابط TikTok', Icons.music_note_rounded),
            _social(whatsapp, 'رقم WhatsApp', Icons.chat_outlined),
            const SizedBox(height: 8),
            Card(
                child: ListTile(
                    onTap: _pickLocation,
                    leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        child: Icon(
                            location == null
                                ? Icons.add_location_alt_rounded
                                : Icons.location_on_rounded,
                            color: const Color(0xFF087E9A))),
                    title: Text(
                        location == null
                            ? 'حدد موقع المتجر على الخريطة'
                            : 'تم تحديد موقع المتجر',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(location == null
                        ? 'مطلوب قبل إرسال الطلب'
                        : '${location!.latitude.toStringAsFixed(6)}, ${location!.longitude.toStringAsFixed(6)}'),
                    trailing: const Icon(Icons.chevron_left_rounded))),
            const SizedBox(height: 18),
            FilledButton.icon(
                onPressed: submitting ? null : _submit,
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_outlined),
                label: const Text('إرسال إلى السوبر أدمن للمراجعة')),
            const SizedBox(height: 8),
            const Text('سيظهر المتجر على خريطة العملاء بعد موافقة السوبر أدمن.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ])));
  Widget _social(TextEditingController c, String label, IconData icon) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
              controller: c,
              decoration:
                  InputDecoration(labelText: label, prefixIcon: Icon(icon))));
  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null;
  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
        context,
        MaterialPageRoute(
            builder: (_) =>
                StoreLocationScreen(state: widget.state, selectionOnly: true)));
    if (result != null && mounted) setState(() => location = result);
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدد موقع المتجر على الخريطة أولًا')));
      return;
    }
    setState(() => submitting = true);
    try {
      await widget.state.repository.submitStoreApplication({
        'ownerId': widget.state.user?.id,
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim(),
        'specialty': specialty,
        'instagram': instagram.text.trim(),
        'facebook': facebook.text.trim(),
        'tiktok': tiktok.text.trim(),
        'whatsapp': whatsapp.text.trim(),
        'latitude': location!.latitude,
        'longitude': location!.longitude,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم إرسال بيانات المتجر إلى السوبر أدمن')));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'تعذر إرسال طلب المتجر. أعد المحاولة؛ بياناتك ما زالت محفوظة في النموذج.')));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}
