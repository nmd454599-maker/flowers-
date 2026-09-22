هل # حالة تجهيز أزهارنا للإنتاج — 2026-09-05

هذه حالة تنفيذ فعلية، وليست إعلانًا بأن التطبيق جاهز للإطلاق العام.

| البند | المنجز | ما يحتاج إكمالًا |
|---|---|---|
| Firebase | تم التحقق من المشروع azharna-production وملف Android الموجود | موافقة النشر مستلمة؛ محاولة نشر Functions توقفت لعدم تفعيل Blaze |
| القواعد | منع إسناد متجر عند إنشاء حساب، claims + MFA للإدارة، محادثات الطلب، صلاحيات المندوب | نشر القواعد مع الوظائف بعد إكمال المتطلبات |
| السوبر أدمن | شاشة بريد/كلمة مرور/TOTP وأداة منح claims لحساب موثّق | هوية صاحب الحساب، تفعيل Email/Password وIdentity Platform وTOTP، إنشاء الحساب وتأكيد بريده |
| App Check | تم حفظ إعداد Play Integrity سحابيًا للتطبيقين والتحقق منه بالقراءة؛ TTL ساعة وMEETS_DEVICE_INTEGRITY وrequireLicensed=true | بصمات Play App Signing، اختبار Integrity عبر Internal testing ثم enforcement للخدمات |
| الدفع | منع تنفيذ دفع إلكتروني وهمي؛ طلب نقدي يحسب السعر والمخزون من الخادم | تحديد المزود والتعاقد ومفاتيح Sandbox/Production وWebhook وآلية الاسترداد |
| المحادثات | رسائل Firestore مباشرة لكل طلب بين العميل ومتاجر الطلب والدعم الإداري، منع التزوير والتعديل | اختبار أجهزة متعددة وإشعارات الرسائل والتحميل التدريجي لأقدم من آخر 100 رسالة |
| المندوب | مشروع courier_app مستقل، تسجيل Android حقيقي في Firebase، طلبات مسندة وتحديث حالة، زر إسناد إداري | اعتماد حسابات المندوبين واختبار نسخة الهاتف وموقع التوصيل عمليًا |
| الطلبات | createCashOrder يتحقق من الحساب والمنتجات والمتاجر والأسعار والمخزون، مع معاملة ذرية ومنع تكرار retry | نشر Functions؛ تعريف سياسة رسوم التوصيل والإلغاء وإعادة المخزون واعتماد جميع تفاصيل checkout |
| النسخ والتنبيهات | دليل تشغيل وجدولة واستعادة وتنبيه | التفعيل السحابي وقناة إشعار فعلية واختبار استعادة وتنبيه |
| الاختبارات | 13 اختبار Firebase Emulator نجحت، 15 اختبار Flutter نجحت، والتحليل النهائي للتطبيقين دون ملاحظات، اختبار واجهة المندوب نجح | تجارب OTP/TOTP/Integrity والدفع على أجهزة فعلية |
| Android | مفتاح رفع RSA 3072 محلي، حزمتا AAB موقعتان تم التحقق منهما ومطابقة الشهادة مع Firebase | بصمات Play App Signing واختبار المسار الداخلي واعتماد المتجر |
| الوثائق | مسودة خصوصية وشروط وقائمة قبول إصدار | الاسم القانوني والعنوان والدعم وسياسة الإلغاء والاحتفاظ، روابط عامة ومسار حذف حساب فعلي |

## الحزم المحلية

- التطبيق الأساسي: artifacts/azharna-customer-0.3.0-rc.aab، حجم 82,237,630 بايت، تحقق jarsigner ناجح والشهادة تطابق مفتاح الرفع المسجل في Firebase.
- SHA-256 للملف: 62F53AC5F547E12AE30F2F4350CE29FABC23498C53A74D2AA07FE99732CE39D4.
- تطبيق المندوب: artifacts/azharna-courier-1.0.0-rc.aab، حجم 51,826,611 بايت، تحقق jarsigner ناجح والشهادة مطابقة للتطبيق الأساسي.
- SHA-256 لحزمة المندوب: 3FA20458B40021AA4CC5B9171CB5487CAAE58E328B2FD860D4129CE3D6E796F1.
- الحزمتان من نوع release وموقعتان، لكنهما مرشحتان للاختبار وغير معتمدتين للنشر العام. فحص حزمة العميل أكد وجود خريطة proguard.map ضمن بياناتها.

## نشر قابل للمراجعة

ملفات النشر: firebase.json وfirestore.rules وstorage.rules وfirestore.indexes.json، ووظائف functions/index.js وfunctions/orders.js.

الوظيفة الجديدة createCashOrder تستخدم المنطقة me-central1 وتفرض App Check. وظائف الإدارة والجدولة السابقة ما تزال ضمن الحزمة وتحتاج مراجعة تشغيلية قبل الإنتاج. القواعد الجديدة تمنع كتابة الطلبات والمدفوعات مباشرة من التطبيق؛ يجب عدم نشرها منفردة قبل نشر وظيفة إنشاء الطلبات وتجهيز نسخة العميل. العملاء القدامى الذين يكتبون الطلبات مباشرة سيتوقف checkout لديهم بعد ترقية القواعد، لذلك يلزم تنسيق تحديث التطبيق.

وافق المستخدم صراحة على النشر والإعدادات بعد توضيح النطاق. قُبلت محاولة نشر Functions فقط، لكنها توقفت لأن تفعيل cloudbuild.googleapis.com يتطلب خطة Blaze. لم تُنشر الوظائف أو القواعد الجديدة. أُجّل نشر القواعد عمدًا إلى ما بعد نجاح نشر الوظائف وتجهيز العملاء.

فحص Functions أعاد أن Cloud Functions API غير مفعّلة. محاولة إنشاء نسخة يومية باحتفاظ 7 أيام أعادت خطأ 403 يؤكد أن الفوترة غير مفعّلة. قائمة جداول النسخ الاحتياطي فارغة. لم يتم إنشاء أي جدول.

تم تسجيل SHA-1 وSHA-256 لشهادة الرفع في تطبيقي Firebase وتحديث ملفي google-services.json. إعداد تقليص Android النهائي يستخدم إعداد Flutter الافتراضي. توقفت أول محاولة بناء لاستهلاك الموارد، ثم أعيد البناء واكتمل. جُرّب تمرير خيار لتخفيف البناء، لكن فحص الحزمة الفعلي أظهر وجود خريطة تقليص؛ أزيل هذا الخيار التجريبي من المصدر، ولا نعتمد افتراض تعطيل التقليص في وصف الحزمة.

## ملفات حساسة محلية

android/azharna-upload.jks وandroid/key.properties وcourier_app/android/key.properties مستثناة من Git. لا ترسل محتوياتها في المحادثة. احفظ نسخة آمنة منفصلة من مفتاح الرفع وكلمات مروره؛ لا يمثل وجودها على جهاز واحد نسخة احتياطية.

## تشغيل الاختبارات

```powershell
flutter.bat analyze
flutter.bat test
firebase.cmd emulators:exec --only firestore,storage --project demo-azharna "npm.cmd --prefix functions run test:rules"
```

اختبارات الخادم تستدعي handler على المحاكي للتحقق من المعاملات؛ لا تمثل اختبار شبكة callable أو attestation لـApp Check. بيئة Node المحلية 24 بينما Functions تستهدف Node 22؛ يجب تنفيذ تحقق إضافي على Node 22 قبل نشر Functions.

## المراجع الفنية

- https://firebase.google.com/docs/app-check/flutter/default-providers
- https://firebase.google.com/docs/auth/android/totp-mfa
- https://firebase.google.com/docs/firestore/backups
- https://support.google.com/googleplay/android-developer/answer/10144311

## إعداد App Check بعد موافقة المستخدم

بعد موافقة المستخدم الصريحة، نُفّذ إعداد Play Integrity للتطبيقين بنجاح، ثم أعادت قراءة كل منهما tokenTtl=3600s وminDeviceRecognitionLevel=MEETS_DEVICE_INTEGRITY وrequireLicensed=true. استُخدم الخيار --no-allow-unrecognized-version؛ تعيد الواجهة appIntegrity={} دون عرض الحقل المنطقي صراحة. أعادت واجهة CLI configured=null، لذلك نثبت حفظ الإعدادات ولا نعتبره إثباتًا لنجاح attestation على الأجهزة.

لم نُفعّل enforcement للخدمات. أعادت قراءة قائمة الخدمات enforcementMode=null لكل الخدمات المعروضة؛ يلزم اختبار رموز Play Integrity من Internal testing وإضافة شهادة Play App Signing قبل فرض التحقق. سجلات التطبيق والتحقق: appcheck-configure-main.log وappcheck-configure-courier.log وappcheck-verified-main.log وappcheck-verified-courier.log وappcheck-verified-services.log.

العائق الحالي للنشر هو عدم تفعيل Blaze، وليس انتظار موافقة جديدة. سجل المحاولة: approved-functions-deploy.log. يلزم كذلك بريد صاحب حساب السوبر أدمن واسم مزود الدفع والبيانات القانونية وبريد الدعم وقناة التنبيهات لإكمال البنود المعتمدة عليها.