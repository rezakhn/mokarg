import 'order_item.dart'; // ایمپورت مدل آیتم سفارش
import 'payment.dart';    // ایمپورت مدل پرداخت

// مدل داده ای برای نمایش اطلاعات یک سفارش فروش
class SalesOrder {
  final int? id; // شناسه یکتای سفارش فروش در پایگاه داده (اختیاری)
  final int customerId; // شناسه مشتری که این سفارش را ثبت کرده است (کلید خارجی)
  final DateTime orderDate; // تاریخ ثبت سفارش
  DateTime? deliveryDate; // تاریخ تحویل مورد انتظار (می تواند null باشد)
  double totalAmount;    // مبلغ کل سفارش (محاسبه شده از آیتم ها)
  String status;         // وضعیت سفارش، به عنوان مثال: "Pending" (در انتظار بررسی)
                         // "Confirmed" (تایید شده), "Awaiting Payment" (در انتظار پرداخت),
                         // "Shipped" (ارسال شده), "Completed" (تکمیل شده), "Cancelled" (لغو شده)

  List<OrderItem> items; // لیست آیتم های این سفارش (گذرا، به صورت جداگانه بارگذاری می شوند)
  List<Payment> payments; // لیست پرداخت های انجام شده برای این سفارش (گذرا، به صورت جداگانه بارگذاری می شوند)

  // سازنده کلاس SalesOrder
  SalesOrder({
    this.id,
    required this.customerId, // شناسه مشتری الزامی است
    required this.orderDate, // تاریخ سفارش الزامی است
    this.deliveryDate, // تاریخ تحویل اختیاری است
    this.totalAmount = 0.0, // مبلغ کل با مقدار پیش فرض 0.0
    this.status = 'Pending', // وضعیت پیش فرض "در انتظار بررسی" است
    this.items = const [], // لیست آیتم ها با مقدار پیش فرض یک لیست خالی و ثابت
    this.payments = const [], // لیست پرداخت ها با مقدار پیش فرض یک لیست خالی و ثابت
  });

  // تبدیل شی SalesOrder به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  // توجه: لیست آیتم ها و پرداخت ها در اینجا گنجانده نشده و باید جداگانه مدیریت شوند
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'order_date': orderDate.toIso8601String().substring(0, 10), // ذخیره تاریخ به فرمت YYYY-MM-DD
      'delivery_date': deliveryDate?.toIso8601String().substring(0, 10), // ذخیره تاریخ تحویل در صورت وجود
      'total_amount': totalAmount,
      'status': status,
    };
  }

  // ایجاد یک شی SalesOrder از یک نقشه (Map) و لیست های آیتم ها و پرداخت های آن
  factory SalesOrder.fromMap(Map<String, dynamic> map, {List<OrderItem> items = const [], List<Payment> payments = const []}) {
    return SalesOrder(
      id: map['id'],
      customerId: map['customer_id'],
      orderDate: DateTime.parse(map['order_date']), // تبدیل رشته تاریخ سفارش به DateTime
      deliveryDate: map['delivery_date'] != null ? DateTime.parse(map['delivery_date']) : null, // تبدیل رشته تاریخ تحویل در صورت وجود
      totalAmount: map['total_amount']?.toDouble() ?? 0.0, // تبدیل به double و مقدار پیش فرض
      status: map['status'] ?? 'Pending', // مقدار پیش فرض برای وضعیت در صورت null بودن
      items: items, // تنظیم لیست آیتم ها
      payments: payments, // تنظیم لیست پرداخت ها
    );
  }

  // محاسبه مبلغ کل سفارش بر اساس مجموع قیمت کل آیتم های آن
  void calculateTotalAmount() {
    totalAmount = items.fold(0.0, (sum, item) => sum + item.itemTotal); // item.itemTotal خود حاصلضرب مقدار و قیمت واحد است
  }

  // گتر محاسبه شده برای دریافت مجموع مبالغ پرداخت شده برای این سفارش
  double get totalPaid {
    return payments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  // گتر محاسبه شده برای دریافت مبلغ باقی مانده (پرداخت نشده) سفارش
  double get outstandingAmount {
    return totalAmount - totalPaid;
  }

  // بازنمایی رشته ای از شی SalesOrder برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'SalesOrder{id: $id, customerId: $customerId, orderDate: $orderDate, status: $status, totalAmount: $totalAmount, totalPaid: $totalPaid}';
  }
}
