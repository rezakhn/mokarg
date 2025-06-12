import 'package:flutter/foundation.dart'; // برای استفاده از ChangeNotifier
import '../../../core/database_service.dart'; // سرویس پایگاه داده
import '../models/income_report_data.dart'; // مدل داده گزارش درآمد
import '../models/employee_performance_data.dart'; // مدل داده گزارش عملکرد کارمندان
import '../../employees/models/employee.dart'; // برای دسترسی به جزئیات کارمند (شامل WorkLog)

// کنترلر برای مدیریت منطق و داده های مربوط به گزارشات
class ReportController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService(); // نمونه ای از سرویس پایگاه داده
  // نکته: اگر دسترسی مستقیم به محاسبه حقوق در EmployeeController پیچیده باشد،
  // می توان یک نسخه ساده شده از آن را در اینجا پیاده سازی کرد یا متد EmployeeController را static یا به راحتی قابل فراخوانی کرد.
  // در حال حاضر، داده های خام را واکشی کرده و محاسبات را در اینجا انجام می دهیم.

  // --- State مربوط به بازه تاریخی گزارش ---
  DateTime? _reportStartDate; // تاریخ شروع گزارش انتخاب شده
  DateTime? _reportEndDate; // تاریخ پایان گزارش انتخاب شده
  DateTime? get reportStartDate => _reportStartDate; // گتر عمومی
  DateTime? get reportEndDate => _reportEndDate; // گتر عمومی

  // --- State مربوط به گزارش درآمد ---
  IncomeReportData? _incomeReportData; // داده های گزارش درآمد تولید شده
  IncomeReportData? get incomeReportData => _incomeReportData; // گتر عمومی

  // --- State مربوط به گزارش عملکرد کارمندان ---
  List<EmployeePerformanceData> _employeePerformanceList = []; // لیست داده های عملکرد کارمندان
  List<EmployeePerformanceData> get employeePerformanceList => _employeePerformanceList; // گتر عمومی
  Employee? _selectedEmployeeForReport; // کارمند انتخاب شده برای فیلتر گزارش عملکرد (اختیاری)
  Employee? get selectedEmployeeForReport => _selectedEmployeeForReport; // گتر عمومی


  // --- State مشترک ---
  bool _isLoading = false; // وضعیت بارگذاری اطلاعات
  bool get isLoading => _isLoading; // گتر عمومی
  String? _errorMessage; // پیام خطا در صورت بروز مشکل
  String? get errorMessage => _errorMessage; // گتر عمومی

  // سازنده کنترلر
  ReportController() {
    // تنظیم بازه تاریخی پیش فرض، به عنوان مثال: ماه جاری
    final now = DateTime.now();
    _reportStartDate = DateTime(now.year, now.month, 1); // اولین روز ماه جاری
    _reportEndDate = DateTime(now.year, now.month + 1, 0); // آخرین روز ماه جاری (روز صفرم ماه بعد)
  }

  // متد خصوصی برای تنظیم وضعیت بارگذاری و اطلاع رسانی به شنوندگان
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners(); // اطلاع رسانی به ویجت ها برای به روزرسانی UI
  }

  // متد خصوصی برای تنظیم پیام خطا و اطلاع رسانی به شنوندگان
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // تنظیم بازه تاریخی برای گزارشات
  void setDateRange(DateTime start, DateTime end) {
    _reportStartDate = start;
    _reportEndDate = end;
    // پاک کردن داده های گزارش قبلی هنگام تغییر بازه تاریخی
    _incomeReportData = null;
    _employeePerformanceList = [];
    notifyListeners();
  }

  // انتخاب یک کارمند خاص برای فیلتر کردن گزارش عملکرد
  void setSelectedEmployeeForReport(Employee? employee) {
    _selectedEmployeeForReport = employee;
    _employeePerformanceList = []; // پاک کردن داده های گزارش عملکرد قبلی
    notifyListeners();
  }

  // تولید گزارش درآمد برای بازه تاریخی مشخص شده
  Future<void> generateIncomeReport({DateTime? startDate, DateTime? endDate}) async {
    final start = startDate ?? _reportStartDate; // استفاده از تاریخ های کنترلر اگر ورودی null باشد
    final end = endDate ?? _reportEndDate;

    if (start == null || end == null) {
      _setError("لطفا یک بازه تاریخی معتبر برای گزارش درآمد انتخاب کنید.");
      return;
    }
    if (end.isBefore(start)) { // بررسی صحت ترتیب تاریخ ها
      _setError("تاریخ پایان نمی تواند قبل از تاریخ شروع باشد.");
      return;
    }

    _setLoading(true);
    _setError(null);
    _incomeReportData = null; // پاک کردن گزارش قبلی

    try {
      // دریافت مجموع فروش و مجموع خرید از سرویس پایگاه داده
      final totalRevenue = await _dbService.getSalesTotalInDateRange(start, end);
      final totalExpenses = await _dbService.getPurchaseTotalInDateRange(start, end);

      // ایجاد شیء داده گزارش درآمد
      _incomeReportData = IncomeReportData(
        startDate: start,
        endDate: end,
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
      );

    } catch (e) {
      _setError('تولید گزارش درآمد با شکست مواجه شد: ${e.toString()}');
      _incomeReportData = null;
    }
    _setLoading(false);
  }

  // تولید گزارش عملکرد کارمندان برای بازه تاریخی و کارمند (اختیاری) مشخص شده
  Future<void> generateEmployeePerformanceReport({DateTime? startDate, DateTime? endDate, Employee? employee}) async {
    final start = startDate ?? _reportStartDate;
    final end = endDate ?? _reportEndDate;
    final targetEmployee = employee ?? _selectedEmployeeForReport; // کارمند مورد نظر یا همه کارمندان

    if (start == null || end == null) {
      _setError("لطفا یک بازه تاریخی معتبر برای گزارش عملکرد کارمندان انتخاب کنید.");
      return;
    }
     if (end.isBefore(start)) {
      _setError("تاریخ پایان نمی تواند قبل از تاریخ شروع باشد.");
      return;
    }

    _setLoading(true);
    _setError(null);
    _employeePerformanceList = []; // پاک کردن گزارش قبلی

    try {
      List<Employee> employeesToReportOn = []; // لیست کارمندانی که باید برای آنها گزارش تهیه شود
      if (targetEmployee != null) {
        // اگر کارمند خاصی انتخاب شده، فقط برای او گزارش تهیه کن
        employeesToReportOn.add(targetEmployee);
      } else {
        // در غیر این صورت، برای همه کارمندان گزارش تهیه کن
        employeesToReportOn = await _dbService.getEmployees();
      }

      for (var emp in employeesToReportOn) { // برای هر کارمند در لیست
        // واکشی گزارش های کار او در بازه تاریخی مشخص
        final workLogs = await _dbService.getWorkLogsForEmployee(emp.id!, startDate: start, endDate: end);

        double salaryForPeriod = 0; // حقوق محاسبه شده برای این دوره
        int daysWorked = 0; // تعداد روزهای کارکرد (برای روزمزد)
        double hoursWorked = 0; // ساعات کارکرد عادی (برای ساعتی)
        double overtimeHours = 0; // ساعات اضافه کاری

        // محاسبه حقوق و سایر آمارها بر اساس گزارش های کار
        for (var log in workLogs) {
          if (emp.payType == "hourly") { // اگر ساعتی بود
            salaryForPeriod += (log.hoursWorked * emp.hourlyRate);
            hoursWorked += log.hoursWorked;
          } else if (emp.payType == "daily") { // اگر روزمزد بود
            if (log.workedDay) {
              salaryForPeriod += emp.dailyRate;
              daysWorked++;
            }
          }
          salaryForPeriod += (log.overtimeHours * emp.overtimeRate); // اضافه کاری
          overtimeHours += log.overtimeHours;
        }

        // افزودن داده عملکرد این کارمند به لیست گزارش
        _employeePerformanceList.add(EmployeePerformanceData(
          employeeId: emp.id!,
          employeeName: emp.name,
          totalDaysWorked: daysWorked,
          totalHoursWorked: hoursWorked,
          totalOvertimeHours: overtimeHours,
          totalSalaryPaid: salaryForPeriod,
          workLogEntryCount: workLogs.length, // تعداد رکوردهای گزارش کار
        ));
      }
    } catch (e) {
      _setError('تولید گزارش عملکرد کارمندان با شکست مواجه شد: ${e.toString()}');
      _employeePerformanceList = [];
    }
    _setLoading(false);
  }
}
