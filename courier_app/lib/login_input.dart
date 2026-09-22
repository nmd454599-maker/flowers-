String latinDigits(String input) =>
    input.replaceAllMapped(RegExp('[٠-٩۰-۹]'), (match) {
      final digit = match[0]!;
      final arabic = '٠١٢٣٤٥٦٧٨٩'.indexOf(digit);
      return (arabic >= 0 ? arabic : '۰۱۲۳۴۵۶۷۸۹'.indexOf(digit)).toString();
    });

String courierPhone(String input) {
  var value = latinDigits(input).replaceAll(RegExp(r'[\s()\-]'), '');
  if (value.startsWith('00964')) value = '+${value.substring(2)}';
  if (value.startsWith('964')) value = '+$value';
  if (value.startsWith('07')) value = '+964${value.substring(1)}';
  if (value.startsWith('7')) value = '+964$value';
  if (!RegExp(r'^\+9647[0-9]{9}$').hasMatch(value)) {
    throw const FormatException('أدخل رقم هاتف عراقي صحيح مثل 07xxxxxxxxx.');
  }
  return value;
}

String courierSmsCode(String input) {
  final value = latinDigits(input).trim();
  if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
    throw const FormatException('أدخل رمز التحقق المكوّن من 6 أرقام.');
  }
  return value;
}
