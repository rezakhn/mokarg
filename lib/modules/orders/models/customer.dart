// مدل داده ای برای نمایش اطلاعات یک مشتری
class Customer {
  final int? id; // شناسه یکتای مشتری در پایگاه داده (اختیاری)
  final String name; // نام مشتری
  final String contactInfo; // اطلاعات تماس مشتری (مانند تلفن، آدرس و غیره)

  // سازنده کلاس Customer
  Customer({
    this.id,
    required this.name, // نام مشتری الزامی است
    this.contactInfo = '', // اطلاعات تماس اختیاری است و مقدار پیش فرض آن رشته خالی است
  });

  // تبدیل شی Customer به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact_info': contactInfo,
    };
  }

  // ایجاد یک شی Customer از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      contactInfo: map['contact_info'] ?? '', // اگر اطلاعات تماس null بود، رشته خالی در نظر بگیر
    );
  }

  // بازنمایی رشته ای از شی Customer برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'Customer{id: $id, name: $name, contactInfo: $contactInfo}';
  }
}
