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
    notifications/
      device_token_repository.dart ثبت توکن FCM دستگاه (POST /device-token)
      push_notifications_service.dart دریافت Push، نمایش در foreground، باز کردن سفارش با تپ
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

## راه‌اندازی Firebase برای اندروید (بعد از `flutter create`)

کد Dart سمت اپ (`firebase_core`, `firebase_messaging`) آماده‌ست، ولی چند قدم باقی می‌مونه که
فقط روی فایل‌های پلتفرمی (`android/`) ممکنه، یعنی فقط بعد از اجرای `flutter create` (بخش بالا)
و روی ماشین خودت:

1. در [Firebase Console](https://console.firebase.google.com)، همون پروژه‌ای که برای پلاگین
   وردپرس ساختی رو باز کن (یا پروژه جدید بساز) و یک **اپ اندروید** به‌ش اضافه کن. Package name
   باید دقیقاً همونی باشه که با `--org` به `flutter create` دادی (مثلاً
   `com.wcordermanager.wc_order_manager`).
2. فایل `google-services.json` رو دانلود کن و در `android/app/google-services.json` قرار بده.
   (این فایل در `.gitignore` قرار داره و هیچ‌وقت نباید commit بشه.)
3. در `android/build.gradle` (سطح پروژه)، داخل `buildscript { dependencies { ... } }` اضافه کن:
   ```gradle
   classpath 'com.google.gms:google-services:4.4.2'
   ```
4. در `android/app/build.gradle`، در همون انتهای فایل اضافه کن:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```
   و مطمئن شو `minSdkVersion` حداقل `23` تنظیم شده باشه (نیاز `firebase_messaging`).
5. `flutter pub get` و بعد `flutter run` — روی اندروید ۱۳ به بالا، اولین اجرا از کاربر اجازه
   نوتیفیکیشن می‌پرسه (از طریق `requestPermission()` که در `push_notifications_service.dart`
   صدا زده می‌شه).

> اگه از iOS هم بخوای ساپورت کنی، مراحل مشابهی (`GoogleService-Info.plist` + تنظیمات Xcode) لازمه که
> فعلاً چون پروژه فقط اندرویده، اینجا نیاورده شده.

## Push Notification و Fallback (فاز ۶)

- **دریافت لحظه‌ای**: `PushNotificationsService` توکن FCM دستگاه رو بعد از ورود (و هر بار که
  فایربیس توکن رو عوض کنه) با `POST /wcom/v1/device-token` به پلاگین می‌فرسته.
- **نمایش نوتیف در foreground**: چون FCM خودش فقط وقتی اپ در پس‌زمینه یا بسته باشه نوتیف سیستمی
  نشون می‌ده، برای حالت باز بودن اپ از `flutter_local_notifications` استفاده شده تا نوتیف دستی
  نمایش داده بشه.
- **باز شدن سفارش با تپ روی نوتیف**: چه از پس‌زمینه چه از حالت بسته (`getInitialMessage`)، تپ روی
  نوتیف مستقیم صفحه جزئیات همون سفارش رو باز می‌کنه (از طریق یک `navigatorKey` سراسری).
- **Fallback با Polling**: همون‌طور که قبلاً درباره محدودیت‌های گوگل برای FCM در ایران صحبت کردیم،
  `OrdersController.silentRefresh()` هر ۶۰ ثانیه (و هر بار که اپ از پس‌زمینه برمی‌گرده) لیست
  سفارشات رو بی‌صدا (بدون Loading/Error UI) دوباره می‌گیره؛ یعنی حتی اگه Push به هر دلیلی نرسه،
  کاربر با حداکثر یک دقیقه تاخیر سفارش جدید رو توی لیست می‌بینه.

## نقشه راه

- [x] فاز ۴ — راه‌اندازی پروژه، صفحه ورود، لایه API با HMAC
- [x] فاز ۵ — صفحات اصلی (لیست سفارشات، جزئیات، تغییر وضعیت)
- [x] فاز ۶ — نوتیفیکیشن (Firebase) + Fallback با Polling
