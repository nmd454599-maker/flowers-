# ربط أزهارنا بحساب Firebase الجديد

تحديث 22 سبتمبر 2026. اختار المستخدم إنشاء مشروع جديد بحسابه، دون نقل بيانات المشروع السابق `azharna-production`.

تم إنشاء المشروع `azharna-alimahdijable` بالاسم الظاهر **Azharna** بحساب المستخدم، وتسجيل تطبيقي Android وتنزيل إعداداتهما الرسمية. تم التحقق من مطابقة معرف المشروع وأسماء الحزم ومعرفات التطبيقين داخل ملفات الربط، وتحديث المشروع الافتراضي في `.firebaserc`. هذا تحقق من الإعدادات؛ لم يُختبر تسجيل الدخول أو الطلبات على جهاز بعد.

[فتح المشروع في Firebase Console](https://console.firebase.google.com/project/azharna-alimahdijable/overview)

## إعداد Android

- التطبيق الأساسي: `com.azharna.azharna_pro`، وإعداده في `android/app/google-services.json`.
- تطبيق المندوب: `com.azharna.azharna_courier`، وإعداده في `courier_app/android/app/google-services.json`.
- المشروع الافتراضي لأوامر Firebase يحدد في `.firebaserc`.

من **Run and Debug** في VS Code اختر جهاز Android أو محاكي Android، ثم اختر:

- **Azharna — Android Firebase (staging)** لتشغيل التطبيق الأساسي مع Firebase.
- **Azharna — Android local demo** لتشغيل التجربة المحلية باستخدام SQLite.
- **Azharna Courier — Android Firebase** لتشغيل تطبيق المندوب.

لا تثبّت الإعدادات جهازًا معينًا؛ تستخدم الجهاز المختار في VS Code. اسم `staging` لا يغيّر مشروع Firebase: المشروع الفعلي يأتي من ملفات الربط. التشغيل العادي للتطبيق الأساسي بوضع debug دون التعريفات يستخدم التجربة المحلية افتراضيًا.

## الخدمات التي تحتاج إكمالًا وتحققًا

لم تُجهّز خدمات Firestore وAuthentication وCloud Functions وStorage وApp Check ضمن خطوة ربط الحساب هذه. تحديث ملفات الربط وحده لا يفعّلها ولا يؤكد نجاح تسجيل الدخول أو الطلبات أو رفع الصور.

- يجب إكمال إعداد تسجيل الدخول وبيانات اختبار الهاتف وبصمات Android، ثم التحقق من تسجيل الدخول على جهاز.
- التطبيق يستخدم App Check بوضع debug أثناء التطوير؛ إعداداته في المشروع الجديد تحتاج التحقق.
- وظائف الخادم تستخدم المنطقة `me-central1` في العميل والخادم. نشر الوظائف والقواعد والفهارس وإعداد Storage لم يُؤكّد بعد.
- لا توجد بيانات مستخدمين أو منتجات أو طلبات منقولة من المشروع السابق. أي فوترة أو خدمات مدفوعة تحتاج قرارًا مستقلًا قبل تفعيلها.

هذا الربط يستهدف Android. لا توجد حاليًا ملفات منصة iOS أو macOS، وربط Firebase للويب غير مهيأ.

إعداد معاينة Hosting في `firebase.preview.json` وأمثلة التشغيل في `ops/` وسكربت `functions/scripts/catalog-cloud-inspect.cjs` ما زالت تخص البيئة السابقة؛ تحتاج تحديثًا قبل استخدامها مع المشروع الجديد. لم تُنفّذ هذه الأدوات أثناء الربط.

مرجع إعداد التشغيل: [Dart Code — Launch Configuration](https://dartcode.org/docs/launch-configuration/) و[تعريف متغيرات Flutter](https://dartcode.org/docs/using-dart-define-in-flutter/).
