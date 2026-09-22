# نقطة متابعة إعداد Firebase

آخر تحديث: 2026-09-02

## ما اكتمل

- إنشاء مشروع Firebase باسم `Azharna Production`.
- معرّف المشروع: `azharna-production`.
- تسجيل تطبيق Android بالحزمة `com.azharna.azharna_pro`.
- تنزيل `google-services.json` والتحقق من مطابقته.
- نسخ الملف إلى `android/app/google-services.json`.
- إضافة Google Services plugin إلى إعدادات Gradle.
- إنشاء Cloud Firestore بالإصدار Standard وقاعدة `(default)`.
- تجهيز قواعد Firestore محليًا في `firestore.rules`.
- تجهيز الفهارس في `firestore.indexes.json`.
- تجهيز قواعد Storage في `storage.rules`.
- نشر قواعد Firestore بنجاح.
- إنشاء الفهارس الثلاثة المطلوبة وحالتها Enabled.
- تفعيل Phone Authentication.
- إضافة بصمتي SHA-1 وSHA-256 لمفتاح التطوير.
- تنزيل واستبدال `google-services.json` المحدث.
- نجاح مهمة Gradle `processDebugGoogleServices`.
- إضافة رقم اختبار `+9647701234567` بالرمز `123456`.
- تعديل واجهة OTP لدعم رمز Firebase المكوّن من 6 أرقام.
- خفض ذاكرة Gradle إلى 1536MB وعدد العمال إلى 2 لملاءمة الجهاز ذي 3GB RAM.
- نجاح بناء `app-debug.apk` بوضع Firebase.
- تثبيت التطبيق وفتحه على هاتف `RMX3142` بنجاح.

## نقطة التوقف الحالية

إعداد Firestore وPhone Authentication مكتمل. نسخة Firebase مفتوحة على الهاتف، ونقطة المتابعة هي اختبار تسجيل الدخول وإنشاء بيانات فعلية.

## الخطوة التالية

1. تأكد أن الهاتف متصل بالإنترنت؛ السجل أظهر تعذر DNS مؤقتًا لخدمات Google.
2. افتح التطبيق على هاتف `RMX3142` واختر دور العميل.
3. استخدم الرقم `07701234567` واضغط متابعة.
4. أدخل رمز الاختبار `123456` واضغط تأكيد.
5. تحقق من إنشاء مستند المستخدم داخل مجموعة `users` في Firestore.
6. أنشئ طلبًا تجريبيًا وتحقق من ظهوره في مجموعة `orders`.
7. بعد ذلك فعّل Storage وانشر `storage.rules`.

## ملاحظة

لا تنشئ Collections يدويًا قبل إكمال القواعد والفهارس وربط تدفق البيانات بالتطبيق.

## تحديث مركز السوبر أدمن — 2026-09-02

- تم ربط الأقسام الـ12 بطبقة حفظ Firestore وسجل التدقيق محليًا.
- تم تجهيز وظائف خادم للإشعارات والجلسات والحظر والتعويض والتقارير.
- نجح التحليل و9 اختبارات وبناء APK بوضع Firebase.
- تم نشر قواعد الإدارة والفهارس إلى `azharna-production` بنجاح.
- نشر Storage وCloud Functions ينتظر ترقية المشروع إلى Blaze.
