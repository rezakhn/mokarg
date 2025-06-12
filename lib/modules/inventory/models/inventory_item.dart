// مدل داده ای برای نمایش اطلاعات یک آیتم در موجودی انبار
class InventoryItem {
  // در یک سیستم کامل، این ممکن است شناسه قطعه (partId) و کلید خارجی به جدول قطعات باشد.
  // در حال حاضر، نام آیتم (itemName) به عنوان شناسه یکتا برای آیتم موجودی عمل می کند.
  final String itemName; // نام آیتم (کلید اصلی در جدول موجودی)
  double quantity; // مقدار موجود از این آیتم
  double threshold; // حد آستانه برای هشدارهای کمبود موجودی (نقطه سفارش)

  // سازنده کلاس InventoryItem
  InventoryItem({
    required this.itemName, // نام آیتم الزامی است
    required this.quantity, // مقدار موجودی الزامی است
    this.threshold = 0.0, // مقدار پیش فرض برای حد آستانه 0 است اگر مشخص نشود
  });

  // تبدیل شی InventoryItem به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'item_name': itemName,
      'quantity': quantity,
      'threshold': threshold,
    };
  }

  // ایجاد یک شی InventoryItem از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      itemName: map['item_name'],
      quantity: map['quantity']?.toDouble() ?? 0.0, // تبدیل به double و مقدار پیش فرض در صورت null
      threshold: map['threshold']?.toDouble() ?? 0.0, // تبدیل به double و مقدار پیش فرض در صورت null
    );
  }

  // بازنمایی رشته ای از شی InventoryItem برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'InventoryItem{itemName: $itemName, quantity: $quantity, threshold: $threshold}';
  }
}
