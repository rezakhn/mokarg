// مدل داده ای برای نمایش اطلاعات یک پرداخت مربوط به سفارش فروش
class Payment {
  final int? id; // شناسه یکتای پرداخت در پایگاه داده (اختیاری)
  final int orderId; // شناسه سفارش فروشی که این پرداخت برای آن ثبت شده است (کلید خارجی به جدول SalesOrder)
  final double amount; // مبلغ پرداخت شده
  final DateTime paymentDate; // تاریخ پرداخت
  final String? paymentMethod; // روش پرداخت، به عنوان مثال: "Cash" (نقد)، "Card" (کارت)، "Transfer" (انتقال وجه) (اختیاری)

  // سازنده کلاس Payment
  Payment({
    this.id,
    required this.orderId, // شناسه سفارش الزامی است
    required this.amount, // مبلغ پرداخت الزامی است
    required this.paymentDate, // تاریخ پرداخت الزامی است
    this.paymentMethod, // روش پرداخت اختیاری است
  });

  // تبدیل شی Payment به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().substring(0, 10), // ذخیره تاریخ به فرمت YYYY-MM-DD
      'payment_method': paymentMethod,
    };
  }

  // ایجاد یک شی Payment از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      orderId: map['order_id'],
      amount: map['amount']?.toDouble() ?? 0.0, // تبدیل به double و مقدار پیش فرض
      paymentDate: DateTime.parse(map['payment_date']), // تبدیل رشته تاریخ به DateTime
      paymentMethod: map['payment_method'],
    );
  }

  // بازنمایی رشته ای از شی Payment برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'Payment{id: $id, orderId: $orderId, amount: $amount, date: $paymentDate, method: $paymentMethod}';
  }
}
