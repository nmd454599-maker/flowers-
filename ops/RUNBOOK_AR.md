# التشغيل والنسخ الاحتياطي

المشروع الحالي: `azharna-alimahdijable`؛ راجع [حالة التجهيز](../docs/FIREBASE_ACCOUNT_SETUP_AR.md) قبل أي نشر. لا تشغّل أوامر المحاكي بهذا المعرف؛ استخدم `demo-azharna`.

## Firestore
بعد تفعيل الفوترة، أنشئ نسخة يومية باحتفاظ 7 أيام ونسخة أسبوعية باحتفاظ 4 أسابيع. افحص الجداول الموجودة أولًا لتجنب التكرار. راجع صيغة CLI المثبتة عبر --help:

```sh
firebase firestore:backups:schedules:list --database '(default)' --project azharna-alimahdijable
firebase firestore:backups:schedules:create --database '(default)' --recurrence DAILY --retention 7d --project azharna-alimahdijable
```

نفّذ استعادة اختبار إلى قاعدة منفصلة؛ لا تستعد فوق بيانات الإنتاج. تحقق من عينات الطلبات والمستخدمين والصلاحيات وسجل وقت الاستعادة. نسخة Firestore لا تشمل Firebase Auth أو ملفات Storage.

## Storage وAuth
فعّل حماية حذف Storage وObject Versioning/سياسة Lifecycle بعد تحديد مدة الاحتفاظ والتكلفة. جهز نسخة مستقلة من ملفات المستخدمين حسب سياسة الاحتفاظ؛ تصدير Auth يحتوي بيانات حساسة ولا يُحفظ في المستودع. اختبر استرجاع الملف وربطه بمرجعه في Firestore.

## التنبيهات
اختر قناة فعلية وبريد مسؤول التشغيل. إعداد Log-based alert في Cloud Monitoring بمرشح:

```
resource.type="cloud_run_revision" severity>=ERROR
```

احصر السياسة في خدمات أزهارنا المنشورة، واضبط منع التكرار إلى 15 دقيقة. اختبر خطأ معروفًا وتحقق من وصول الإشعار؛ إنشاء السياسة وحده لا يكفي. راقب فشل الوظائف، تراكم مهام الإدارة، فشل الدفع والـWebhook بعد ربطه، فشل النسخ الاحتياطية، وميزانية الفوترة. لا تسجل رموز OTP أو بيانات البطاقات أو محتوى المحادثات.

مراجع:
- https://firebase.google.com/docs/firestore/backups
- https://cloud.google.com/logging/docs/alerting/log-based-alerts

الحالة: هذا إجراء تشغيل مُعدّ، وليس إثبات تفعيل النسخ والتنبيهات في السحابة.

ملف backend-errors-alert.json قالب قابل للاستيراد بعد ملء notificationChannels بمعرّف قناة معتمدة. لا تستورده بقائمة قنوات فارغة؛ لن يصل تنبيه فعلي. تمت إضافة تسجيل خطأ منظّم لفشل الإشعارات المجدولة في كود Functions، ولم يُنشر بعد.
