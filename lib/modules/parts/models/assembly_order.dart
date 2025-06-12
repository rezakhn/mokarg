// مدل داده ای برای نمایش اطلاعات یک سفارش مونتاژ
class AssemblyOrder {
  final int? id; // شناسه یکتای سفارش مونتاژ در پایگاه داده (اختیاری)
  final int partId; // شناسه قطعه ای که قرار است مونتاژ شود (کلید خارجی به جدول Part که isAssembly آن true است)
  final double quantityToProduce; // مقدار مورد نیاز برای تولید از این قطعه مونتاژی
  final DateTime date; // تاریخ ثبت سفارش مونتاژ
  String status; // وضعیت سفارش مونتاژ، به عنوان مثال: "Pending" (در انتظار)، "In Progress" (در حال انجام)، "Completed" (تکمیل شده)

  // سازنده کلاس AssemblyOrder
  AssemblyOrder({
    this.id,
    required this.partId, // شناسه قطعه مونتاژی الزامی است
    required this.quantityToProduce, // مقدار تولید الزامی است
    required this.date, // تاریخ الزامی است
    this.status = 'Pending', // وضعیت پیش فرض "در انتظار" است
  });

  // تبدیل شی AssemblyOrder به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'part_id': partId,
      'quantity_to_produce': quantityToProduce,
      'date': date.toIso8601String().substring(0, 10), // ذخیره تاریخ به فرمت YYYY-MM-DD
      'status': status,
    };
  }

  // ایجاد یک شی AssemblyOrder از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory AssemblyOrder.fromMap(Map<String, dynamic> map) {
    return AssemblyOrder(
      id: map['id'],
      partId: map['part_id'],
      quantityToProduce: map['quantity_to_produce']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']), // تبدیل رشته تاریخ به DateTime
      status: map['status'],
    );
  }

  // بازنمایی رشته ای از شی AssemblyOrder برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'AssemblyOrder{id: $id, partId: $partId, quantity: $quantityToProduce, date: $date, status: $status}';
  }
}
