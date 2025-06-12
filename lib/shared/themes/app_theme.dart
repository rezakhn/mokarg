import 'package:flutter/material.dart';

// کلاس AppTheme برای تعریف و مدیریت تم های برنامه
class AppTheme {
  AppTheme._(); // سازنده خصوصی برای جلوگیری از ایجاد نمونه از این کلاس

  // --- تعریف رنگ های اصلی برای تم روشن ---
  static final Color _lightPrimaryColor = Colors.indigo.shade500; // رنگ اصلی روشن (مثلا برای AppBar) - یک درجه مشخص از رنگ نیلی
  static final Color _lightPrimaryVariantColor = Colors.indigo.shade700; // یک درجه تیره تر از رنگ اصلی روشن
  static final Color _lightSecondaryColor = Colors.pinkAccent.shade400; // رنگ ثانویه روشن (مثلا برای FloatingActionButton)
  static final Color _lightOnPrimaryColor = Colors.white; // رنگ متن و آیکون ها روی رنگ اصلی (مثلا متن AppBar)
  static final Color _lightBackground = Colors.grey.shade100; // رنگ پس زمینه کلی برنامه (کمی روشن تر شده)
  static final Color _lightSurface = Colors.white; // رنگ سطوح مانند کارت ها، دیالوگ ها
  static final Color _lightOnError = Colors.white; // رنگ متن و آیکون ها روی رنگ خطا
  static final Color _lightError = Colors.red.shade700; // رنگ خطا

  // --- تعریف استایل های متنی برای تم روشن ---
  // این استایل ها می توانند بیشتر سفارشی سازی شوند
  static const TextTheme _lightTextTheme = TextTheme(
    // استایل های Display (متن بسیار بزرگ، معمولا برای عناوین در صفحه های بزرگ یا تاکید خاص)
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.w400, letterSpacing: -0.25 /*, color: Colors.black87 */), // رنگ از ColorScheme.onBackground/onSurface گرفته خواهد شد
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.w400 /*, letterSpacing: 0.0, color: Colors.black87 */),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w400 /*, letterSpacing: 0.0, color: Colors.black87 */),

    // استایل های Headline (برای متن های برجسته مانند عناوین صفحه)
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.w400 /*, letterSpacing: 0.0, color: Colors.black87 */),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w400 /*, letterSpacing: 0.0, color: Colors.black87 */),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500 /*, letterSpacing: 0.0, color: Colors.black87 */), // مناسب برای عنوان AppBar

    // استایل های Title (کوچکتر از headline، مناسب برای عناوین بخش ها، عناوین کارت ها)
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w500 /*, letterSpacing: 0.15, color: Colors.black87 */), // مناسب برای عناوین Dialog
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, letterSpacing: 0.15 /*, color: Colors.black87 */), // مناسب برای عناوین ListTile، عناوین Card
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, letterSpacing: 0.1 /*, color: Colors.black87 */),

    // استایل های Body (برای محتوای متنی عادی)
    bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400, letterSpacing: 0.5 /*, color: Colors.black87 */),
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400, letterSpacing: 0.25 /*, color: Colors.black87 */), // استایل پیش فرض برای ویجت Text()
    bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, letterSpacing: 0.4 /*, color: Colors.black54 */), // مناسب برای زیرنویس ها، توضیحات کوتاه

    // استایل های Label (برای دکمه ها، کپشن ها، اورلاین ها)
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, letterSpacing: 0.1 /*, color: _lightPrimaryColor */), // مناسب برای دکمه ها
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, letterSpacing: 0.5 /*, color: Colors.black54 */),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, letterSpacing: 0.5 /*, color: Colors.black54 */),
  );

  // گتر برای دریافت تم روشن برنامه
  static ThemeData get lightTheme {
    // تعریف طرح رنگی (ColorScheme) برای تم روشن
    final colorScheme = ColorScheme.light(
      primary: _lightPrimaryColor, // رنگ اصلی
      primaryContainer: _lightPrimaryVariantColor, // یک درجه از رنگ اصلی (معمولا برای پس زمینه عناصر مرتبط با رنگ اصلی)
      secondary: _lightSecondaryColor, // رنگ ثانویه
      secondaryContainer: Colors.pinkAccent.shade700, // یک درجه از رنگ ثانویه
      surface: _lightSurface, // رنگ سطوح
      background: _lightBackground, // رنگ پس زمینه
      error: _lightError, // رنگ خطا
      onPrimary: _lightOnPrimaryColor, // رنگ متن و آیکون روی رنگ اصلی
      onSecondary: Colors.white, // رنگ متن و آیکون روی رنگ ثانویه
      onSurface: Colors.black87, // رنگ پیش فرض متن روی سطوح مانند کارت ها
      onBackground: Colors.black87, // رنگ پیش فرض متن روی پس زمینه
      onError: _lightOnError, // رنگ متن و آیکون روی رنگ خطا
      brightness: Brightness.light, // روشنایی تم: روشن
    );

    // برگرداندن شیء ThemeData برای تم روشن
    return ThemeData(
      brightness: Brightness.light, // روشنایی تم
      primaryColor: _lightPrimaryColor, // رنگ اصلی (برای سازگاری با ویجت های قدیمی تر)
      colorScheme: colorScheme, // طرح رنگی تعریف شده
      scaffoldBackgroundColor: _lightBackground, // رنگ پس زمینه پیش فرض برای Scaffold

      fontFamily: null, // استفاده از فونت پیش فرض سیستم (می توان نام فونت سفارشی را اینجا قرار داد)

      // اعمال طرح رنگی به استایل های متنی
      textTheme: _lightTextTheme.apply(
        bodyColor: colorScheme.onBackground, // رنگ پیش فرض برای متون body
        displayColor: colorScheme.onBackground, // رنگ پیش فرض برای متون display
        // در صورت نیاز می توان رنگ استایل های خاصی را اینجا بازنویسی کرد،
        // اما معمولا باید بر اساس مکانی که استفاده می شوند (onPrimary, onSurface و غیره) تطبیق پیدا کنند.
      ),

      // تم AppBar
      appBarTheme: AppBarTheme(
        color: _lightPrimaryColor, // یا استفاده از colorScheme.primary
        foregroundColor: colorScheme.onPrimary, // برای متن عنوان و آیکون ها
        elevation: 2.0, // سایه ملایم
        iconTheme: IconThemeData(color: colorScheme.onPrimary), // تم آیکون ها
        actionsIconTheme: IconThemeData(color: colorScheme.onPrimary), // تم آیکون های اکشن
        titleTextStyle: _lightTextTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary), // استفاده از استایل متنی تعریف شده برای عنوان
      ),

      // تم ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary, // رنگ پس زمینه دکمه
          foregroundColor: colorScheme.onPrimary, // رنگ متن و آیکون دکمه
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // پدینگ داخلی
          textStyle: _lightTextTheme.labelLarge?.copyWith(color: colorScheme.onPrimary), // استایل متن
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // شکل دکمه با گوشه های گرد
        ),
      ),

      // تم TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary, // رنگ متن دکمه
          textStyle: _lightTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600), // اطمینان از استفاده از labelLarge
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // پدینگ داخلی
        ),
      ),

      // تم OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary, // رنگ متن و حاشیه دکمه
          side: BorderSide(color: colorScheme.primary, width: 1.5), // تعریف حاشیه
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // پدینگ داخلی
          textStyle: _lightTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600), // استایل متن
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // شکل دکمه
        ),
      ),

      // تم InputDecoration (برای فیلدهای متنی)
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder( // حاشیه پیش فرض
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder( // حاشیه در حالت فعال (نه فوکوس شده)
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder( // حاشیه در حالت فوکوس شده
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        labelStyle: _lightTextTheme.bodyMedium?.copyWith(color: Colors.grey.shade700), // استایل لیبل
        floatingLabelStyle: _lightTextTheme.bodySmall?.copyWith(color: colorScheme.primary), // استایل لیبل وقتی شناور است
        hintStyle: _lightTextTheme.bodyMedium?.copyWith(color: Colors.grey.shade500), // استایل متن راهنما (hint)
        // filled: true, // آیا فیلد باید پر شده نمایش داده شود؟
        // fillColor: Colors.grey.shade50, // رنگ پر شدن (کمی متفاوت از پس زمینه)
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // پدینگ محتوا
      ),

      // تم Card
      cardTheme: CardTheme(
        elevation: 1.5, // میزان سایه کارت
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0), // مارجین استاندارد
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // شکل کارت با گوشه های نرم تر
        surfaceTintColor: Colors.transparent, // رفع مشکل surface tint در متریال 3 اگر از آن استفاده نمی شود
        color: _lightSurface, // رنگ سطح کارت
      ),

      // تم ListTile
      listTileTheme: ListTileThemeData(
        // dense: true, // باعث فشرده تر شدن ListTile ها می شود
        iconColor: colorScheme.primary, // رنگ آیکون ها
        titleTextStyle: _lightTextTheme.titleMedium, // استایل پیش فرض عنوان ListTile
        subtitleTextStyle: _lightTextTheme.bodySmall, // استایل پیش فرض زیرنویس ListTile
      ),

      // تم Drawer (منوی کشویی)
      drawerTheme: DrawerThemeData(
        backgroundColor: _lightSurface, // یا _lightBackground
      ),

      // تم Dialog (پنجره های محاوره ای)
      dialogTheme: DialogTheme(
        backgroundColor: _lightSurface, // رنگ پس زمینه دیالوگ
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // شکل دیالوگ
        titleTextStyle: _lightTextTheme.titleLarge?.copyWith(color: colorScheme.onSurface), // استایل عنوان دیالوگ
      ),

      // تم FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary, // رنگ پس زمینه
        foregroundColor: colorScheme.onSecondary, // رنگ آیکون
      ),

      // تم PopupMenu (منوهای بازشو)
      popupMenuTheme: PopupMenuThemeData(
        color: _lightSurface, // رنگ پس زمینه منو
        textStyle: _lightTextTheme.bodyMedium?.copyWith(color: colorScheme.onSurface), // استایل متن آیتم های منو
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // شکل منو
      ),

      // تم SegmentedButton (دکمه های چند قسمتی)
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          // backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
          //   if (states.contains(MaterialState.selected)) return colorScheme.primary.withOpacity(0.12);
          //   return null; // استفاده از پیش فرض برای حالت انتخاب نشده
          // }),
          // رنگ متن و آیکون بر اساس انتخاب شدن یا نشدن
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) return colorScheme.primary;
            return colorScheme.onSurface.withOpacity(0.6);
          }),
          iconColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) return colorScheme.primary;
            return colorScheme.onSurface.withOpacity(0.6);
          }),
          textStyle: MaterialStateProperty.all(_lightTextTheme.labelMedium), // استایل متن
        )
      ),

      // تراکم بصری تطبیقی برای پلتفرم های مختلف
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  // TODO: در صورت نیاز می توان یک darkTheme نیز به همین شکل تعریف کرد
}
