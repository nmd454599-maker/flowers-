import '../../models/models.dart';

/// Normalizes equivalent phone spellings without changing stored account IDs.
String accountPhone(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  var value = input;
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('964')) return '+$digits';
  if (digits.startsWith('0')) digits = digits.substring(1);
  return '+964$digits';
}

AppUser localAccount(AppUser verified, Map<String, Object?>? existing) {
  final phone = accountPhone(verified.phone);
  final role = existing == null
      ? verified.role
      : parseUserRole(existing['role'] as String?);
  if (role == null) throw StateError('نوع الحساب المحلي غير معروف');
  if (existing?['active'] == 0) throw StateError('هذا الحساب موقوف');
  if (role == UserRole.courier) throw StateError('يرجى استخدام تطبيق المندوب');
  return AppUser(
    id: existing?['id'] as String? ?? 'local-${phone.substring(1)}',
    name: existing?['name'] as String? ?? verified.name,
    phone: existing?['phone'] as String? ?? phone,
    role: role,
    storeId: existing?['store_id'] as String? ?? verified.storeId,
  );
}
