Fasl | 3ème Info — ملفات المشروع

محتويات الحزمة:
- index.html: واجهة Fasl.
- fasl-config.js: رابط Supabase والمفتاح العام وLiveKit URL.
- api/livekit-token.js: endpoint على Vercel لإصدار رمز LiveKit من جهة الخادم.
- supabase_setup.sql: مخطط الجداول وسياسات RLS الأساسية.
- package.json و vercel.json: إعدادات النشر.

مهم: هذه الحزمة ليست نشرًا مكتملًا تلقائيًا، ولا يمكن تعديل مشروع Vercel البعيد من هنا. يجب ضبط متغيرات البيئة في Vercel ثم إعادة النشر.

Vercel > Project > Settings > Environment Variables:
LIVEKIT_URL = عنوان WebSocket الظاهر في لوحة LiveKit (نفس LIVEKIT_URL الموجود في fasl-config.js)
LIVEKIT_API_KEY = مفتاح API من LiveKit
LIVEKIT_API_SECRET = سر LiveKit (خزّنه هنا فقط، لا تضعه في HTML أو GitHub)

بعد حفظ المتغيرات، اعمل Redeploy للمشروع.

Supabase:
- نفّذ supabase_setup.sql داخل SQL Editor في مشروع Supabase.
- تأكد من تفعيل Realtime للجداول المطلوبة.
- رابط المشروع والمفتاح العام موضوعان في fasl-config.js.
- إعدادات الاتصال وحدها لا تحول واجهة localStorage الحالية إلى تسجيل دخول وشات مشتركين؛ يلزم إكمال تكامل Auth/Realtime في التطبيق واختباره مع إعدادات المشروع الفعلية.

LiveKit:
- الكود في api/livekit-token.js يصدر الرموز من الخادم، لذلك يجب توفر LIVEKIT_API_KEY و LIVEKIT_API_SECRET في Vercel.
- اختبر بعد النشر على HTTPS ومن جهازين مختلفين.
- يجب السماح للمتصفح باستخدام الكاميرا والميكروفون، ومشاركة الشاشة تتطلب متصفحًا يدعم getDisplayMedia.

الأمان:
- لا تضع LiveKit API Secret أو Supabase service_role key في ملفات الواجهة.
- رمز الأستاذ المضمّن في واجهة HTML لا يعتبر حماية آمنة للإنتاج؛ يجب التحقق من صلاحية الأستاذ على الخادم قبل إتاحة حذف الرسائل/الحسابات أو إنهاء الحصة للجميع.
