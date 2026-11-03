# WC Order Manager — اپلیکیشن موبایل (Flutter)

اپلیکیشن اندروید برای مدیریت سفارشات ووکامرس، که از طریق پلاگین
[`wc-order-manager-plugin`](https://github.com/ahmad-alzd/wc-order-manager-plugin)
به فروشگاه وصل می‌شه.

## وضعیت فعلی

این ریپو شامل **کد Dart/Flutter** پروژه‌ست (پوشه `lib/`) ولی چون این محیط به SDK فلاتر
دسترسی ندارد، پوشه‌های پلتفرم (`android/`, `ios/`) هنوز ساخته نشده‌ن — این مرحله باید
یک‌بار روی ماشین خودت (که Flutter نصبه) انجام بشه.

### راه‌اندازی اولیه (فقط یک‌بار)

```bash
flutter create --org com.wcordermanager --project-name wc_order_manager .
flutter pub get
```

این دستور پوشه‌های `android/` و `ios/` رو می‌سازه، بدون اینکه به `lib/` یا
`pubspec.yaml` موجود دست بزنه (چون از قبل وجود دارن، فلاتر فقط فایل‌های پلتفرمی که
کم هستن رو اضافه می‌کنه).

### اجرا برای تست

```bash
flutter run
```

### بررسی کد (چون اینجا امکان اجرای flutter analyze نبود)

```bash
flutter analyze
```

## ساختار پروژه

```
lib/
  main.dart                        نقطه ورود اپ
  app.dart                         MaterialApp + AuthGate (مسیریابی بر اساس وضعیت ورود)
  core/
    store_credentials.dart         مدل Key/Secret/آدرس سایت
    secure_storage_service.dart    ذخیره امن credentials (Android Keystore)
    api_client.dart                کلاینت HTTP با امضای HMAC-SHA256 (مطابق پلاگین)
    api_exception.dart             خطای یکپارچه برای پاسخ‌های ناموفق API
  features/
    auth/
      auth_controller.dart         مدیریت وضعیت ورود (ChangeNotifier)
      login_screen.dart            صفحه ورود Key/Secret
    orders/
      order_models.dart            مدل‌های سفارش/آدرس/آیتم/وضعیت
      orders_repository.dart       فراخوانی اندپوینت‌های wcom/v1 مربوط به سفارش
      orders_controller.dart       وضعیت لیست سفارشات (فیلتر، صفحه‌بندی، Pull-to-refresh)
      orders_list_screen.dart      صفحه لیست سفارشات
      order_detail_controller.dart وضعیت یک سفارش + تغییر وضعیت
      order_detail_screen.dart     صفحه جزئیات سفارش
```

## امضای درخواست‌ها (هماهنگ با پلاگین)

`ApiClient` دقیقاً همون الگوریتمی که سمت پلاگین (`WCOM_Auth`) پیاده‌سازی شده رو
اجرا می‌کنه:

```
string_to_sign = METHOD "\n" PATH "\n" TIMESTAMP "\n" NONCE "\n" sha256_hex(body)
signature      = hex( HMAC-SHA256(string_to_sign, api_secret) )
```

`PATH` فقط مسیر داخل namespace هست (مثل `/wcom/v1/orders/123`)، نه URL کامل و بدون
query string — برای جزئیات کامل به README پلاگین مراجعه کن.

## نکته درباره Provider و Navigator (فاز ۵)

`OrdersRepository` در بالاترین سطح ممکن (کنار `AuthController`، بالاتر از `Navigator` داخلی
`MaterialApp`) تعریف شده، نه داخل مسیر صفحه لیست سفارشات. دلیلش یک رفتار خاص Provider/Navigator
در فلاتره: صفحه‌ای که با `Navigator.push` باز می‌شه، از نظر درخت ویجت **فرزند** صفحه قبلی نیست،
بلکه یک مسیر(route) جداست؛ پس Providerهایی که فقط داخل یک مسیر خاص (مثل لیست سفارشات) تعریف
شده باشن، داخل صفحه‌ای که با push باز می‌شه (مثل جزئیات سفارش) در دسترس نیستن. برای همین
`OrdersRepository` بالای همه مسیرها قرار گرفته (فقط `AuthController` رو نگه می‌داره و در لحظه‌ی
هر درخواست بهش رجوع می‌کنه)، در حالی که `OrdersController` (وضعیت لیست) چون فقط داخل همون صفحه
لیست استفاده می‌شه، محدود به همون مسیر مونده.

## نقشه راه

- [x] فاز ۴ — راه‌اندازی پروژه، صفحه ورود، لایه API با HMAC
- [x] فاز ۵ — صفحات اصلی (لیست سفارشات، جزئیات، تغییر وضعیت)
- [ ] فاز ۶ — نوتیفیکیشن (Firebase) + Fallback با Polling
