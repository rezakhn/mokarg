import 'package:flutter/foundation.dart'; // برای استفاده از ChangeNotifier
import '../../../core/database_service.dart'; // سرویس پایگاه داده
import '../models/employee.dart'; // مدل کارمند و گزارش کار

// کنترلر برای مدیریت داده ها و منطق مربوط به کارمندان و گزارش های کار آنها
class EmployeeController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService(); // نمونه ای از سرویس پایگاه داده

  List<Employee> _employees = []; // لیست خصوصی کارمندان
  List<Employee> get employees => _employees; // گتر عمومی برای لیست کارمندان

  Employee? _selectedEmployee; // کارمند انتخاب شده فعلی
  Employee? get selectedEmployee => _selectedEmployee; // گتر عمومی برای کارمند انتخاب شده

  List<WorkLog> _workLogs = []; // لیست خصوصی گزارش های کار برای کارمند انتخاب شده
  List<WorkLog> get workLogs => _workLogs; // گتر عمومی برای لیست گزارش های کار

  bool _isLoading = false; // وضعیت بارگذاری اطلاعات
  bool get isLoading => _isLoading; // گتر عمومی برای وضعیت بارگذاری

  String? _errorMessage; // پیام خطا در صورت بروز مشکل
  String? get errorMessage => _errorMessage; // گتر عمومی برای پیام خطا

  // سازنده کنترلر
  EmployeeController() {
    // به صورت اختیاری می توان لیست کارمندان را هنگام ایجاد کنترلر بارگذاری کرد
    // fetchEmployees();
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

  // واکشی لیست کارمندان از پایگاه داده
  // قابلیت جستجو بر اساس نام کارمند (query)
  Future<void> fetchEmployees({String? query}) async {
    _setLoading(true); // شروع بارگذاری
    _setError(null); // پاک کردن خطای قبلی
    try {
      _employees = await _dbService.getEmployees(query: query); // دریافت کارمندان از سرویس پایگاه داده
    } catch (e) {
      _setError('بارگیری لیست کارمندان با شکست مواجه شد: ${e.toString()}');
      _employees = []; // اطمینان از خالی بودن لیست در صورت خطا
    }
    _setLoading(false); // پایان بارگذاری
  }

  // افزودن یک کارمند جدید
  Future<bool> addEmployee(Employee employee) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertEmployee(employee); // درج کارمند در پایگاه داده
      await fetchEmployees(); // واکشی مجدد لیست کارمندان برای به روزرسانی
      _setLoading(false);
      return true; // عملیات موفقیت آمیز بود
    } catch (e) {
      _setError('افزودن کارمند با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false; // عملیات ناموفق بود
    }
  }

  // به روزرسانی اطلاعات یک کارمند موجود
  Future<bool> updateEmployee(Employee employee) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateEmployee(employee); // به روزرسانی کارمند در پایگاه داده
      await fetchEmployees(); // واکشی مجدد لیست کارمندان
      // اگر کارمند به روز شده همان کارمند انتخاب شده فعلی است، اطلاعات آن را نیز به روز کن
      if (_selectedEmployee?.id == employee.id) {
        _selectedEmployee = await _dbService.getEmployeeById(employee.id!);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('به روزرسانی کارمند با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // حذف یک کارمند بر اساس شناسه
  Future<bool> deleteEmployee(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteEmployee(id); // حذف کارمند از پایگاه داده
      await fetchEmployees(); // واکشی مجدد لیست کارمندان
      // اگر کارمند حذف شده همان کارمند انتخاب شده فعلی است، آن را null کرده و گزارش های کارش را پاک کن
      if (_selectedEmployee?.id == id) {
        _selectedEmployee = null;
        _workLogs = [];
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('حذف کارمند با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // انتخاب یک کارمند و واکشی گزارش های کار مربوط به او
  Future<void> selectEmployee(Employee? employee) async {
    _selectedEmployee = employee;
    if (employee != null) {
      await fetchWorkLogsForSelectedEmployee(); // واکشی گزارش های کار برای کارمند جدید انتخاب شده
    } else {
      _workLogs = []; // اگر هیچ کارمندی انتخاب نشده، لیست گزارش کار را خالی کن
    }
    notifyListeners(); // اطلاع رسانی برای به روزرسانی UI
  }

  // دریافت اطلاعات یک کارمند خاص بر اساس شناسه
  Future<Employee?> getEmployeeById(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      final employee = await _dbService.getEmployeeById(id);
      _setLoading(false);
      return employee;
    } catch (e) {
      _setError('دریافت اطلاعات کارمند با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  // واکشی گزارش های کار برای کارمند انتخاب شده فعلی
  // قابلیت فیلتر بر اساس تاریخ شروع و پایان
  Future<void> fetchWorkLogsForSelectedEmployee({DateTime? startDate, DateTime? endDate}) async {
    if (_selectedEmployee == null) return; // اگر هیچ کارمندی انتخاب نشده، کاری انجام نده
    _setLoading(true);
    _setError(null);
    try {
      _workLogs = await _dbService.getWorkLogsForEmployee(
        _selectedEmployee!.id!, // شناسه کارمند انتخاب شده
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError('بارگیری گزارش های کار با شکست مواجه شد: ${e.toString()}');
      _workLogs = []; // اطمینان از خالی بودن لیست در صورت خطا
    }
    _setLoading(false);
  }

  // افزودن یک گزارش کار جدید برای کارمند انتخاب شده
  Future<bool> addWorkLog(WorkLog workLog) async {
    // بررسی اینکه آیا کارمند انتخاب شده با شناسه کارمند در گزارش کار مطابقت دارد
    if (_selectedEmployee == null || workLog.employeeId != _selectedEmployee!.id) {
      _setError("عدم تطابق کارمند انتخاب شده یا عدم انتخاب کارمند برای گزارش کار.");
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertWorkLog(workLog); // درج گزارش کار در پایگاه داده
      await fetchWorkLogsForSelectedEmployee(); // واکشی مجدد لیست گزارش های کار
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('افزودن گزارش کار با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // به روزرسانی یک گزارش کار موجود
  Future<bool> updateWorkLog(WorkLog workLog) async {
    if (_selectedEmployee == null || workLog.employeeId != _selectedEmployee!.id) {
       _setError("عدم تطابق کارمند انتخاب شده یا عدم انتخاب کارمند برای به روزرسانی گزارش کار.");
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateWorkLog(workLog); // به روزرسانی گزارش کار در پایگاه داده
      await fetchWorkLogsForSelectedEmployee(); // واکشی مجدد لیست
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('به روزرسانی گزارش کار با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // حذف یک گزارش کار بر اساس شناسه آن
  Future<bool> deleteWorkLog(int workLogId) async {
    if (_selectedEmployee == null) return false; // اگر کارمندی انتخاب نشده، عملیات انجام نمی شود
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteWorkLog(workLogId); // حذف گزارش کار از پایگاه داده
      await fetchWorkLogsForSelectedEmployee(); // واکشی مجدد لیست
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('حذف گزارش کار با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // محاسبه حقوق برای یک دوره مشخص برای یک کارمند خاص و لیست گزارش های کار در آن دوره
  double calculateSalaryForPeriod(Employee employee, List<WorkLog> logsInPeriod) {
    double totalSalary = 0; // حقوق کل
    for (var log in logsInPeriod) {
      if (log.employeeId == employee.id) { // فقط گزارش های مربوط به این کارمند
        if (employee.payType == "hourly") { // اگر نوع پرداخت ساعتی است
          totalSalary += (log.hoursWorked * employee.hourlyRate);
        } else if (employee.payType == "daily") { // اگر نوع پرداخت روزانه است
          if (log.workedDay) { // اگر آن روز کار کرده است
            totalSalary += employee.dailyRate;
          }
        }
        totalSalary += (log.overtimeHours * employee.overtimeRate); // اضافه کردن مبلغ اضافه کاری
      }
    }
    return totalSalary;
  }

  // مثال: محاسبه حقوق برای کارمند انتخاب شده فعلی و گزارش های کار موجود در _workLogs
  // این متد معمولا با یک لیست فیلتر شده از گزارش های کار برای یک دوره خاص فراخوانی می شود
  double calculateCurrentSelectedEmployeeSalary(DateTime startDate, DateTime endDate) {
    if (_selectedEmployee == null) return 0.0; // اگر کارمندی انتخاب نشده، حقوق صفر است

    // فیلتر کردن گزارش های کار در بازه تاریخی مشخص شده
    final relevantLogs = _workLogs.where((log) {
      final logDate = log.date; // فرض می کنیم log.date از نوع DateTime است
      return !logDate.isBefore(startDate) && !logDate.isAfter(endDate.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1))); // شامل خود تاریخ پایان هم می شود
    }).toList();

    return calculateSalaryForPeriod(_selectedEmployee!, relevantLogs);
  }

  // TODO: افزودن منطق برای هشدارهای مربوط به حضور و غیاب (مثلا اگر برای یک روز کاری گزارشی ثبت نشده باشد)
  // نکته: عبارت بالا یک یادآوری برای توسعه آینده است
}
