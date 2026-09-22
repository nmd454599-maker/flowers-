# ربط أزهارنا بحساب Firebase الجديد

تحديث 22 سبتمبر 2026. اختار المستخدم إنشاء مشروع جديد بحسابه، دون نقل بيانات المشروع السابق `azharna-production`.

تم إنشاء المشروع `azharna-alimahdijable` بالاسم الظاهر **Azharna** بحساب المستخدم. سُجّل التطبيق الأساسي وتطبيق المندوب لكل من Android وiOS في المشروع نفسه. المشروع الافتراضي في `.firebaserc` هو هذا المشروع الجديد. البيانات فارغة؛ لم تُنقل حسابات أو منتجات أو طلبات من حساب صاحب المشروع السابق.

[فتح المشروع في Firebase Console](https://console.firebase.google.com/project/azharna-alimahdijable/overview)

## التطبيقات والمنصات

- التطبيق الأساسي: `com.azharna.azharna_pro`، وإعداده في `android/app/google-services.json`.
- تطبيق المندوب: `com.azharna.azharna_courier`، وإعداده في `courier_app/android/app/google-services.json`.
- تطبيق iOS الأساسي: `com.azharna.azharnaPro`.
- تطبيق مندوب iOS: `com.azharna.azharnaCourier`.
- المشروع الافتراضي لأوامر Firebase يحدد في `.firebaserc`.

تم تنزيل إعدادات Android الرسمية والتحقق من مطابقة المشروع والحزم. أضيفت بصمتا SHA-1 وSHA-256 لمفتاح Android debug المحلي إلى التطبيقين. بصمات توقيع النشر وPlay App Signing تحتاج تسجيلًا عند إعداد النشر.

أضيفت منصتا iOS في `ios/` و`courier_app/ios/`، وملفا `GoogleService-Info.plist` الرسميان ضمن موارد هدف Runner لكل تطبيق. الحد الأدنى iOS 15.0 وفق Firebase SDK المستخدم. أضيفت مخططات URL الخاصة بالتحقق الهاتفي، وقدرات Push Notifications وBackground fetch/Remote notifications. التطبيق الأساسي يطلب الصور والموقع أثناء الاستخدام؛ لم يُضف تتبع موقع في الخلفية. يستخدم التطبيقان CocoaPods بإعداد محلي في `pubspec.yaml`، ولا توجد هوية فريق Apple محفوظة في المشروع.

ضُبط الحد الأدنى لـDart في تطبيق المندوب إلى `^3.12.0` ليتوافق مع Flutter 3.44.0 المثبت. قبِل محلّل الاعتماديات هذا التوافق، وتحدّثت إصدارات الحزم الست المثبتة من Flutter في ملف قفل المندوب فقط؛ ملف قفل التطبيق الأساسي الذي عدله المستخدم لم يتغير ضمن هذا العمل.

من **Run and Debug** في VS Code اختر الجهاز أو المحاكي، ثم اختر:

- **Azharna — iOS / Android Firebase (staging)** لتشغيل التطبيق الأساسي مع Firebase.
- **Azharna — iOS / Android local demo** لتشغيل التجربة المحلية باستخدام SQLite.
- **Azharna Courier — iOS / Android Firebase** لتشغيل تطبيق المندوب.

لا تثبّت الإعدادات جهازًا معينًا؛ تستخدم الجهاز المختار في VS Code. اسم `staging` لا يغيّر مشروع Firebase: المشروع الفعلي يأتي من ملفات الربط. التشغيل العادي للتطبيق الأساسي بوضع debug دون التعريفات يستخدم التجربة المحلية افتراضيًا.

## الخدمات المجهزة بتاريخ 22 سبتمبر 2026

- أُنشئت قاعدة Firestore الأصلية `(default)` بإصدار Standard في `me-central1`، ضمن الحصة المجانية.
- نُشرت `firestore.rules` و`firestore.indexes.json` بنجاح. أصبحت الفهارس الثلاثة بحالة `READY`.
- أُنشئت خدمة Authentication وفُعّل Email/Password مع اشتراط كلمة مرور، وفُعّل Phone. سياسة مناطق رسائل الهاتف تسمح بالعراق `IQ` فقط، بما يناسب أرقام التطبيق الحالية.
- اجتازت اختبارات قواعد Firestore وStorage القائمة 35 اختبارًا في المحاكيات بمشروع `demo-azharna`، ونجح فحص صياغة وظائف الخادم `npm run lint`. نجاح اختبار Storage محليًا لا يعني إنشاء الخدمة سحابيًا.
- نجح تحليل Dart لملفي تهيئة Firebase المعدلين، وفحص ملفات Xcode وplist وربط موارد Firebase ومطابقة معرفاتها. عرض `xcodebuild -list` هدفي Runner وRunnerTests ومخطط Runner في التطبيقين. هذا فحص إعدادات وكود؛ لا يثبت اكتمال تشغيل التطبيق على جهاز iPhone.
- محاولة تجهيز بناء iOS وصلت إلى حل اعتماديات CocoaPods، ثم توقفت بسبب عدم توفر صلاحية كتابة ذاكرته المحلية خارج مساحة العمل. لم ينتج بناء iOS مكتمل ولم يُختبر محاكي أو جهاز. يجب إكمال `flutter pub get` وتثبيت Pods ثم البناء قبل اعتماد iOS.
- اختبارات Flutter لم تكتمل: تعطل مشغّل اختبار المندوب داخل Dart VM في البيئة الحالية. ظهر كذلك خطأ سابق في اختباري التطبيق الأساسي `store_profile_photo_test.dart` و`store_visitor_test.dart` بسبب عدم العثور على `ApplicationDatabase`. لا تعتبر نتائج فحص القواعد أو التحليل نجاحًا لمجموعة اختبارات Flutter كاملة.

## ما يحتاج إكمالًا قبل الاستخدام الفعلي

- المشروع على خطة **Spark**. لم تُنشر Cloud Functions ولم تُنشأ خدمة Storage؛ تتطلبان تفعيل خطة Blaze وربط فوترة. لذلك لا تعمل دورة الطلبات ورفع الصور بعد. القواعد تمنع إنشاء الطلبات مباشرة من العميل؛ الإنشاء مخصص لوظيفة الخادم بعد نشرها.
- تفعيل مزود الهاتف لا يثبت وصول SMS. توثيق Firebase الحالي يشترط Blaze لرسائل التحقق الفعلية؛ يمكن تجهيز أرقام اختبار خيالية بشكل خاص. لم تُضف أرقام أو رموز اختبار إلى المستودع.
- لوحة الإدارة تحتاج حساب مالك ببريد مؤكد، وصلاحيات موثوقة، وإعداد Identity Platform/TOTP المتوافق مع الكود. لم تُنشأ حسابات إدارة أو تُمنح صلاحيات تلقائيًا.
- يستخدم App Check مزود debug أثناء التطوير على Android وiOS. سجّل رموز debug الصادرة من الجهاز بشكل خاص في Firebase، وأكمل إعداد Play Integrity وApple DeviceCheck قبل اختبار إصدار النشر. لم يُعطّل فرض App Check في وظائف الخادم.
- على iOS، أكمل توقيع Xcode وفريق Apple ورفع مفتاح APNs إلى Firebase لتسجيل الدخول بالهاتف والإشعارات، ثم اختبر جهازًا حقيقيًا. مفاتيح Apple وملفات التوقيع الخاصة لا تحفظ في Git.
- وظائف الخادم والعميل تستخدم `me-central1`. لم يُجرَ اختبار تسجيل دخول أو طلب أو رفع صورة من جهاز إلى الخدمات الجديدة بعد.

جرى تحديث أمثلة التشغيل وقالب التنبيه في `ops/` للمشروع الجديد؛ النسخ الاحتياطية والتنبيهات لم تُفعّل. إعداد معاينة Hosting في `firebase.preview.json` وسكربت `functions/scripts/catalog-cloud-inspect.cjs` ما زالا يخصان البيئة السابقة؛ لا تستخدمهما قبل تحديث الوجهة والتحقق منها. لا يوجد إعداد Firebase للويب ضمن هذه الخطوة.

المراجع: [متطلبات Cloud Functions](https://firebase.google.com/docs/functions/quotas)، [متطلبات Storage](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024)، [حدود رسائل Authentication](https://firebase.google.com/docs/auth/limits)، [إعداد هاتف iOS](https://firebase.google.com/docs/auth/ios/phone-auth)، [App Check أثناء التطوير](https://firebase.google.com/docs/app-check/flutter/debug-provider)، [إعداد التشغيل في Dart Code](https://dartcode.org/docs/launch-configuration/).
