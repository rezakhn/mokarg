import 'dart:io'; // برای کار با شیء File در صورت نیاز به لیست کردن مستقیم فایل ها (در اینجا برای Platform.isAndroid استفاده می شود)
import 'package:flutter/foundation.dart'; // برای ChangeNotifier
import 'package:intl/intl.dart'; // برای فرمت کردن تاریخ در یادداشت های پیش فرض
import 'package:permission_handler/permission_handler.dart'; // برای مدیریت دسترسی ها
import '../../../core/database_service.dart'; // سرویس پایگاه داده
import '../models/backup_info.dart'; // مدل اطلاعات پشتیبان
import '../services/backup_service.dart'; // سرویس پشتیبان گیری

// کنترلر برای مدیریت منطق و داده های مربوط به عملیات پشتیبان گیری و بازیابی
class BackupController with ChangeNotifier {
  final BackupService _backupService = BackupService(); // نمونه ای از سرویس پشتیبان گیری
  final DatabaseService _dbService = DatabaseService(); // نمونه ای از سرویس پایگاه داده

  List<BackupInfo> _backupHistory = []; // لیست خصوصی تاریخچه پشتیبان گیری ها
  List<BackupInfo> get backupHistory => _backupHistory; // گتر عمومی

  bool _isLoading = false; // وضعیت بارگذاری یا انجام عملیات
  bool get isLoading => _isLoading; // گتر عمومی

  String? _operationMessage; // پیام نتیجه عملیات (موفقیت یا خطا)
  String? get operationMessage => _operationMessage; // گتر عمومی
  bool _isError = false; // آیا پیام عملیات یک خطا است؟
  bool get isError => _isError; // گتر عمومی

  // سازنده کنترلر
  BackupController() {
    fetchBackupHistory(); // واکشی اولیه تاریخچه پشتیبان گیری
  }

  // متد خصوصی برای تنظیم وضعیت بارگذاری
  void _setLoading(bool loading) {
    _isLoading = loading;
    _operationMessage = null; // پاک کردن پیام قبلی
    _isError = false; // ریست کردن وضعیت خطا
    notifyListeners(); // اطلاع رسانی به UI
  }

  // متد خصوصی برای تنظیم پیام عملیات
  void _setMessage(String message, {bool isError = false}) {
    _operationMessage = message;
    _isError = isError;
    _isLoading = false; // عملیات تمام شده، پس بارگذاری false است
    notifyListeners();
  }

  // واکشی تاریخچه پشتیبان گیری از پایگاه داده
  Future<void> fetchBackupHistory() async {
    _setLoading(true);
    try {
      _backupHistory = await _dbService.getBackupHistory();
    } catch (e) {
      _setMessage('بارگیری تاریخچه پشتیبان گیری با شکست مواجه شد: ${e.toString()}', isError: true);
    }
    _setLoading(false);
  }

  // درخواست دسترسی به حافظه (بیشتر برای اندروید و ذخیره سازی خارجی)
  Future<bool> _requestStoragePermission() async {
    // در اندروید، برای getApplicationDocumentsDirectory معمولا نیازی به دسترسی صریح نیست.
    // اما اگر مسیر به حافظه خارجی اشتراکی تغییر کند، این بخش حیاتی خواهد بود.
    // این بررسی بیشتر یک placeholder است برای زمانی که در مکان های با محدودیت کمتر می نویسیم.
    if (Platform.isAndroid) { // فقط برای اندروید معمولا مرتبط است
        var status = await Permission.storage.status; // بررسی وضعیت فعلی دسترسی
        if (!status.isGranted) { // اگر دسترسی داده نشده
            status = await Permission.storage.request(); // درخواست دسترسی
        }
        if (status.isPermanentlyDenied) { // اگر دسترسی به طور دائم رد شده
            _setMessage("دسترسی به حافظه به طور دائم رد شده است. لطفا برای ایجاد پشتیبان، آن را در تنظیمات برنامه فعال کنید.", isError: true);
            // می توان openAppSettings() را برای هدایت کاربر به تنظیمات اضافه کرد
            return false;
        }
        return status.isGranted; // آیا دسترسی داده شده است؟
    }
    return true; // برای سایر پلتفرم ها برای دایرکتوری های مخصوص برنامه، فرض می کنیم دسترسی وجود دارد یا لازم نیست
  }

  // ایجاد یک پشتیبان جدید
  Future<void> createNewBackup({String? notes}) async {
    _setLoading(true);

    bool hasPermission = await _requestStoragePermission(); // بررسی و درخواست دسترسی
    if (!hasPermission && Platform.isAndroid) { // اگر دسترسی وجود ندارد (و پلتفرم اندروید است)
      if (_operationMessage == null || !_isError) { // اگر پیام خطای قبلی برای دسترسی تنظیم نشده
          _setMessage("دسترسی به حافظه رد شد. امکان ایجاد پشتیبان وجود ندارد.", isError: true);
      }
      // _setLoading(false); // این خط تکراری است چون _setMessage آن را false می کند
      return;
    }

    final result = await _backupService.createBackup(); // فراخوانی سرویس برای ایجاد فایل پشتیبان

    if (result['success'] == true) { // اگر ایجاد فایل موفق بود
      final backupInfo = BackupInfo( // ایجاد شیء اطلاعات پشتیبان
        backupDate: DateTime.now(),
        filePath: result['filePath'],
        fileSize: result['fileSize'],
        status: 'Success', // موفق
        notes: notes != null && notes.isNotEmpty ? notes : 'پشتیبان گیری دستی در ${DateFormat.yMMMd().add_jm().format(DateTime.now())}', // یادداشت پیش فرض
      );
      try {
        await _dbService.insertBackupInfo(backupInfo); // ذخیره اطلاعات پشتیبان در پایگاه داده
        await fetchBackupHistory(); // واکشی مجدد تاریخچه
        _setMessage(result['message'] ?? 'پشتیبان با موفقیت ایجاد شد!', isError: false);
      } catch (dbError) {
        _setMessage('فایل پشتیبان ایجاد شد، اما ذخیره تاریخچه با شکست مواجه شد: ${dbError.toString()}', isError: true);
      }
    } else { // اگر ایجاد فایل ناموفق بود
      _setMessage(result['message'] ?? 'ایجاد پشتیبان با شکست مواجه شد.', isError: true);
    }
  }

  // بازیابی از یک فایل پشتیبان
  Future<void> restoreFromBackup(BackupInfo backupToRestore) async {
    _setLoading(true);

    try {
      // قبل از بازیابی، اتصال فعلی پایگاه داده باید بسته شود
      await _dbService.close();
    } catch (e) {
       _setMessage('خطای بحرانی: امکان بستن پایگاه داده فعلی قبل از بازیابی وجود نداشت. عملیات بازیابی لغو شد. ${e.toString()}', isError: true);
       return;
    }

    final result = await _backupService.restoreBackup(backupToRestore.filePath); // فراخوانی سرویس برای بازیابی

    if (result['success'] == true) { // اگر بازیابی موفق بود
      // مهم: پس از بازیابی موفق، برنامه باید ری استارت شود تا با پایگاه داده جدید کار کند
      _setMessage('${result['message']}. شما باید برنامه را مجددا راه اندازی کنید.', isError: false);
      await fetchBackupHistory(); // واکشی تاریخچه (ممکن است پایگاه داده هنوز به درستی مقداردهی اولیه نشده باشد تا بعد از ری استارت)
    } else { // اگر بازیابی ناموفق بود
      _setMessage(result['message'] ?? 'بازیابی با شکست مواجه شد.', isError: true);
      try {
        // تلاش برای مقداردهی اولیه مجدد پایگاه داده پس از بازیابی ناموفق
        // این کار برای اطمینان از این است که برنامه همچنان می تواند با پایگاه داده قبلی (یا یک پایگاه داده خالی جدید) کار کند
        await _dbService.database;
      } catch (e) {
        // در این نقطه، ممکن است وضعیت پایگاه داده نامشخص باشد
        // لاگ کردن خطا برای توسعه دهنده مهم است
        // print("Failed to re-initialize database after failed restore: $e"); // از print پرهیز شد
      }
    }
  }

  // حذف یک فایل پشتیبان و رکورد تاریخچه آن
  Future<void> deleteBackup(BackupInfo backupToDelete) async {
    _setLoading(true);
    bool fileDeleted = await _backupService.deleteBackupFile(backupToDelete.filePath); // ابتدا فایل را حذف کن

    if (fileDeleted) { // اگر فایل با موفقیت حذف شد
      try {
        await _dbService.deleteBackupInfo(backupToDelete.id!); // سپس رکورد تاریخچه را از پایگاه داده حذف کن
        await fetchBackupHistory(); // واکشی مجدد تاریخچه
        _setMessage('فایل پشتیبان و رکورد تاریخچه با موفقیت حذف شدند.', isError: false);
      } catch (dbError) {
        _setMessage('فایل پشتیبان حذف شد، اما حذف رکورد تاریخچه با شکست مواجه شد: ${dbError.toString()}', isError: true);
      }
    } else { // اگر حذف فایل ناموفق بود
      // توجه: در این حالت، رکورد تاریخچه حذف نمی شود تا کاربر از وجود فایل (حتی اگر حذف نشده) مطلع باشد
      _setMessage('حذف فایل پشتیبان با شکست مواجه شد. رکورد تاریخچه حذف نشد.', isError: true);
    }
  }

  // پاک کردن تمام تاریخچه پشتیبان گیری و فایل های مرتبط
  Future<void> clearAllBackupHistoryAndFiles() async {
    _setLoading(true);
    try {
      final history = await _dbService.getBackupHistory(); // دریافت کل تاریخچه
      for (var backupInfo in history) { // برای هر رکورد، فایل آن را حذف کن
        await _backupService.deleteBackupFile(backupInfo.filePath);
      }
      await _dbService.clearBackupHistory(); // پاک کردن تمام رکوردهای تاریخچه از پایگاه داده
      await fetchBackupHistory(); // واکشی مجدد (باید خالی باشد)
      _setMessage('تمام تاریخچه پشتیبان گیری و فایل های مرتبط حذف شدند.', isError: false);
    } catch (e) {
      _setMessage('خطا در پاک کردن تاریخچه/فایل های پشتیبان: ${e.toString()}', isError: true);
    }
    // _setLoading(false); // این خط تکراری است چون _setMessage آن را false می کند
  }
}
