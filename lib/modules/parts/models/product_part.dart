// مدل داده ای برای نمایش قطعات تشکیل دهنده یک محصول
// این کلاس مشخص می کند که یک محصول از چه قطعاتی و به چه مقدار تشکیل شده است
class ProductPart {
  final int? id; // شناسه یکتای این رکورد قطعه محصول (اختیاری)
  final int productId;  // شناسه محصول (کلید خارجی به جدول Product)
  final int partId;     // شناسه قطعه (کلید خارجی به جدول Part، می تواند یک جزء خام یا یک مجموعه مونتاژی باشد)
  final double quantity; // مقدار قطعه مورد نیاز برای ساخت یک واحد از محصول

  // سازنده کلاس ProductPart
  ProductPart({
    this.id,
    required this.productId, // شناسه محصول الزامی است
    required this.partId, // شناسه قطعه الزامی است
    required this.quantity, // مقدار الزامی است
  });

  // تبدیل شی ProductPart به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'part_id': partId,
      'quantity': quantity,
    };
  }

  // ایجاد یک شی ProductPart از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory ProductPart.fromMap(Map<String, dynamic> map) {
    return ProductPart(
      id: map['id'],
      productId: map['product_id'],
      partId: map['part_id'],
      quantity: map['quantity']?.toDouble() ?? 0.0, // تبدیل به double و مقدار پیش فرض
    );
  }

  // بازنمایی رشته ای از شی ProductPart برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'ProductPart{id: $id, productId: $productId, partId: $partId, quantity: $quantity}';
  }
}
