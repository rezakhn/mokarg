// مدل داده ای برای نمایش اطلاعات عملکرد یک کارمند در یک دوره گزارش
class EmployeePerformanceData {
  final int employeeId; // شناسه کارمند
  final String employeeName; // نام کارمند
  final int totalDaysWorked;       // مجموع روزهای کارکرد (مربوط به کارمندان روزمزد)
  final double totalHoursWorked;    // مجموع ساعات کارکرد عادی (مربوط به کارمندان ساعتی)
  final double totalOvertimeHours;  // مجموع ساعات اضافه کاری (مربوط به همه کارمندان)
  final double totalSalaryPaid;     // مجموع حقوق پرداخت شده برای دوره گزارش
  final int workLogEntryCount;     // تعداد رکوردهای گزارش کار ثبت شده برای کارمند

  // سازنده کلاس EmployeePerformanceData
  EmployeePerformanceData({
    required this.employeeId, // شناسه کارمند الزامی است
    required this.employeeName, // نام کارمند الزامی است
    this.totalDaysWorked = 0, // مقدار پیش فرض برای روزهای کارکرد
    this.totalHoursWorked = 0.0, // مقدار پیش فرض برای ساعات کارکرد
    this.totalOvertimeHours = 0.0, // مقدار پیش فرض برای ساعات اضافه کاری
    required this.totalSalaryPaid, // مجموع حقوق پرداخت شده الزامی است
    this.workLogEntryCount = 0, // مقدار پیش فرض برای تعداد رکوردهای گزارش کار
  });

  // بازنمایی رشته ای از شی EmployeePerformanceData برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'EmployeePerformanceData(employee: $employeeName, daysWorked: $totalDaysWorked, hoursWorked: $totalHoursWorked, overtime: $totalOvertimeHours, salary: $totalSalaryPaid, entries: $workLogEntryCount)';
  }
}
