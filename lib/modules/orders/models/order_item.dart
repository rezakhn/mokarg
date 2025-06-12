// مدل داده ای برای نمایش اطلاعات یک آیتم در سفارش فروش
class OrderItem {
  final int? id; // شناسه یکتای آیتم سفارش در پایگاه داده (اختیاری)
  final int orderId;    // شناسه سفارش فروشی که این آیتم به آن تعلق دارد (کلید خارجی به جدول SalesOrder)
  final int productId;  // شناسه محصول (کلید خارجی به جدول Product از ماژول Parts)
  final double quantity; // مقدار سفارش داده شده از این محصول
  final double priceAtSale; // قیمت هر واحد از محصول در زمان فروش (برای ثبت قیمت تاریخی)

  // سازنده کلاس OrderItem
  OrderItem({
    this.id,
    required this.orderId, // شناسه سفارش الزامی است
    required this.productId, // شناسه محصول الزامی است
    required this.quantity, // مقدار الزامی است
    required this.priceAtSale, // قیمت در زمان فروش الزامی است
  });

  // تبدیل شی OrderItem به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_sale': priceAtSale,
    };
  }

  // ایجاد یک شی OrderItem از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      productId: map['product_id'],
      quantity: map['quantity']?.toDouble() ?? 0.0, // تبدیل به double و مقدار پیش فرض
      priceAtSale: map['price_at_sale']?.toDouble() ?? 0.0, // تبدیل به double و مقدار پیش فرض
    );
  }

  // گتر محاسبه شده برای دریافت قیمت کل این آیتم سفارش (مقدار * قیمت واحد)
  double get itemTotal => quantity * priceAtSale;

  // بازنمایی رشته ای از شی OrderItem برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'OrderItem{id: $id, orderId: $orderId, productId: $productId, quantity: $quantity, priceAtSale: $priceAtSale}';
  }
}
