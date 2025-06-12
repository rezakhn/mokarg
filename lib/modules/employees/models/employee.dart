// مدل داده ای برای نمایش اطلاعات یک کارمند
class Employee {
  final int? id; // شناسه یکتای کارمند در پایگاه داده (اختیاری، هنگام ایجاد جدید null است)
  final String name; // نام کارمند
  final String payType; // نوع پرداخت: "daily" (روزانه) یا "hourly" (ساعتی)
  final double dailyRate; // نرخ پرداخت روزانه (اگر payType روزانه باشد)
  final double hourlyRate; // نرخ پرداخت ساعتی (اگر payType ساعتی باشد)
  final double overtimeRate; // نرخ اضافه کاری (به ازای هر ساعت)

  // سازنده کلاس Employee
  Employee({
    this.id,
    required this.name, // نام الزامی است
    required this.payType, // نوع پرداخت الزامی است
    this.dailyRate = 0.0, // مقدار پیش فرض برای نرخ روزانه
    this.hourlyRate = 0.0, // مقدار پیش فرض برای نرخ ساعتی
    required this.overtimeRate, // نرخ اضافه کاری الزامی است
  }) : assert(payType == 'daily' || payType == 'hourly', 'نوع پرداخت باید "daily" یا "hourly" باشد'); // بررسی صحت مقدار payType

  // تبدیل شی Employee به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pay_type': payType,
      'daily_rate': dailyRate,
      'hourly_rate': hourlyRate,
      'overtime_rate': overtimeRate,
    };
  }

  // ایجاد یک شی Employee از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      payType: map['pay_type'],
      dailyRate: map['daily_rate']?.toDouble() ?? 0.0, // تبدیل به double و مقدار پیش فرض در صورت null بودن
      hourlyRate: map['hourly_rate']?.toDouble() ?? 0.0,
      overtimeRate: map['overtime_rate']?.toDouble() ?? 0.0,
    );
  }
}

// مدل داده ای برای نمایش اطلاعات یک گزارش کار
class WorkLog {
  final int? id; // شناسه یکتای گزارش کار در پایگاه داده (اختیاری)
  final int employeeId; // شناسه کارمندی که این گزارش کار متعلق به اوست
  final DateTime date; // تاریخ گزارش کار
  final double hoursWorked; // ساعات کارکرد عادی (فقط برای نوع پرداخت ساعتی معنی دار است)
  final bool workedDay; // آیا در این روز کار کرده است؟ (فقط برای نوع پرداخت روزانه، 1 برای کارکرده، 0 برای کار نکرده)
  final double overtimeHours; // ساعات اضافه کاری

  // سازنده کلاس WorkLog
  WorkLog({
    this.id,
    required this.employeeId, // شناسه کارمند الزامی است
    required this.date, // تاریخ الزامی است
    this.hoursWorked = 0.0, // مقدار پیش فرض برای ساعات کارکرد
    this.workedDay = false, // مقدار پیش فرض برای روز کارکرده
    this.overtimeHours = 0.0, // مقدار پیش فرض برای ساعات اضافه کاری
  });

  // تبدیل شی WorkLog به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date.toIso8601String().substring(0, 10), // ذخیره تاریخ به فرمت YYYY-MM-DD
      'hours_worked': hoursWorked,
      'worked_day': workedDay ? 1 : 0, // تبدیل بولین به عدد (1 یا 0)
      'overtime_hours': overtimeHours,
    };
  }

  // ایجاد یک شی WorkLog از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory WorkLog.fromMap(Map<String, dynamic> map) {
    return WorkLog(
      id: map['id'],
      employeeId: map['employee_id'],
      date: DateTime.parse(map['date']), // تبدیل رشته تاریخ به DateTime
      hoursWorked: map['hours_worked']?.toDouble() ?? 0.0,
      workedDay: map['worked_day'] == 1, // تبدیل عدد به بولین
      overtimeHours: map['overtime_hours']?.toDouble() ?? 0.0,
    );
  }
}
