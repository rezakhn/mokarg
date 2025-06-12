// مدل داده ای برای نمایش اطلاعات یک رکورد پشتیبان گیری
class BackupInfo {
  final int? id; // شناسه یکتای رکورد پشتیبان گیری در پایگاه داده (اختیاری)
  final DateTime backupDate; // تاریخ و زمان انجام پشتیبان گیری
  final String filePath; // مسیر فایل پشتیبان ذخیره شده
  final int? fileSize; // اندازه فایل پشتیبان به بایت (اختیاری)
  final String? status; // وضعیت پشتیبان گیری، به عنوان مثال: "Success" (موفق)، "Failed" (ناموفق) (اختیاری)
  final String? notes;  // یادداشت های کاربر یا سیستم مربوط به این پشتیبان گیری (اختیاری)

  // سازنده کلاس BackupInfo
  BackupInfo({
    this.id,
    required this.backupDate, // تاریخ پشتیبان گیری الزامی است
    required this.filePath, // مسیر فایل الزامی است
    this.fileSize, // اندازه فایل اختیاری است
    this.status, // وضعیت اختیاری است
    this.notes, // یادداشت ها اختیاری هستند
  });

  // تبدیل شی BackupInfo به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // ذخیره تاریخ و زمان به صورت رشته ISO8601 (YYYY-MM-DD HH:MM:SS.SSS) برای سازگاری با SQLite
      'backup_date': backupDate.toIso8601String(),
      'file_path': filePath,
      'file_size': fileSize,
      'status': status,
      'notes': notes,
    };
  }

  // ایجاد یک شی BackupInfo از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory BackupInfo.fromMap(Map<String, dynamic> map) {
    return BackupInfo(
      id: map['id'],
      backupDate: DateTime.parse(map['backup_date']), // تبدیل رشته تاریخ به DateTime
      filePath: map['file_path'],
      fileSize: map['file_size'], // ممکن است null باشد اگر در دیتابیس ذخیره نشده
      status: map['status'],
      notes: map['notes'],
    );
  }

  // بازنمایی رشته ای از شی BackupInfo برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'BackupInfo{id: $id, date: $backupDate, path: $filePath, size: $fileSize, status: $status}';
  }
}
