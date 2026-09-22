import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();
  static const environment = String.fromEnvironment('APP_ENV',
      defaultValue: kReleaseMode ? 'production' : 'local');
  static const useFirebase =
      bool.fromEnvironment('USE_FIREBASE', defaultValue: kReleaseMode);
  static const isDemo = !useFirebase;

  static void validate() => validateEnvironment(
      environment: environment, firebase: useFirebase, release: kReleaseMode);

  static void validateEnvironment(
      {required String environment,
      required bool firebase,
      required bool release}) {
    if (!['local', 'staging', 'production'].contains(environment)) {
      throw StateError('إعداد بيئة التطبيق غير صالح');
    }
    if ((release || environment != 'local') && !firebase) {
      throw StateError('هذه النسخة تتطلب الاتصال بالخدمة الفعلية');
    }
    if (release && environment == 'local') {
      throw StateError('لا يمكن تشغيل بيئة التجربة المحلية في النسخة التجارية');
    }
  }
}
