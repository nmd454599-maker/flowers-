import 'package:azharna_courier/login_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Iraqi phone formats reach the same international number', () {
    for (final input in [
      '07701234567',
      '7701234567',
      '+9647701234567',
      '9647701234567',
      '009647701234567',
      '٠٧٧٠١٢٣٤٥٦٧',
      '۰۷۷۰۱۲۳۴۵۶۷',
      '0770 123 4567',
    ]) {
      expect(courierPhone(input), '+9647701234567');
    }
  });
  test('invalid input is rejected before requesting an SMS', () {
    for (final input in ['', '0770', 'abc07701234567', '+971501234567']) {
      expect(() => courierPhone(input), throwsFormatException);
    }
  });
  test('SMS accepts Arabic digits and preserves leading zeroes', () {
    expect(courierSmsCode(' ٠١٢٣٤٥ '), '012345');
    expect(courierSmsCode('۰۱۲۳۴۵'), '012345');
    expect(() => courierSmsCode('1234'), throwsFormatException);
    expect(() => courierSmsCode('abcdef'), throwsFormatException);
  });
}
