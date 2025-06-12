// مدل داده ای برای نمایش اطلاعات گزارش درآمد
class IncomeReportData {
  final DateTime startDate; // تاریخ شروع دوره گزارش
  final DateTime endDate; // تاریخ پایان دوره گزارش
  final double totalRevenue; // مجموع درآمد در این دوره (از فروش ها)
  final double totalExpenses; // مجموع هزینه ها در این دوره (در این مدل ساده، عمدتا از خریدها)

  // گتر محاسبه شده برای دریافت سود خالص
  double get netProfit => totalRevenue - totalExpenses;

  // سازنده کلاس IncomeReportData
  IncomeReportData({
    required this.startDate, // تاریخ شروع الزامی است
    required this.endDate, // تاریخ پایان الزامی است
    required this.totalRevenue, // مجموع درآمد الزامی است
    required this.totalExpenses, // مجموع هزینه ها الزامی است
  });

  // بازنمایی رشته ای از شی IncomeReportData برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'IncomeReportData(startDate: $startDate, endDate: $endDate, revenue: $totalRevenue, expenses: $totalExpenses, profit: $netProfit)';
  }
}
