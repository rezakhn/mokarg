// مدل داده ای برای نمایش اطلاعات یک محصول نهایی قابل فروش
class Product {
  final int? id; // شناسه یکتای محصول در پایگاه داده (اختیاری)
  final String name; // نام محصول نهایی

  // سازنده کلاس Product
  Product({
    this.id,
    required this.name, // نام محصول الزامی است
  });

  // تبدیل شی Product به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // ایجاد یک شی Product از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
    );
  }

  // بازنمایی رشته ای از شی Product برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'Product{id: $id, name: $name}';
  }
}
