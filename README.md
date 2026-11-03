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
    home/
      home_placeholder_screen.dart صفحه موقت بعد از ورود (فاز ۵ جایگزین می‌شه)
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

## نقشه راه

- [x] فاز ۴ — راه‌اندازی پروژه، صفحه ورود، لایه API با HMAC
- [ ] فاز ۵ — صفحات اصلی (لیست سفارشات، جزئیات، تغییر وضعیت)
- [ ] فاز ۶ — نوتیفیکیشن (Firebase) + Fallback با Polling
