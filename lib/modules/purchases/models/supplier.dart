// مدل داده ای برای نمایش اطلاعات یک تامین کننده
class Supplier {
  final int? id; // شناسه یکتای تامین کننده در پایگاه داده (اختیاری، هنگام ایجاد جدید null است)
  final String name; // نام تامین کننده
  final String contactInfo; // اطلاعات تماس تامین کننده (می تواند شامل تلفن، ایمیل، آدرس و غیره باشد)

  // سازنده کلاس Supplier
  Supplier({
    this.id,
    required this.name, // نام الزامی است
    this.contactInfo = '', // اطلاعات تماس اختیاری است و مقدار پیش فرض آن رشته خالی است
  });

  // تبدیل شی Supplier به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact_info': contactInfo,
    };
  }

  // ایجاد یک شی Supplier از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      contactInfo: map['contact_info'] ?? '', // اگر اطلاعات تماس null بود، رشته خالی در نظر بگیر
    );
  }

  // بازنمایی رشته ای از شی Supplier برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'Supplier{id: $id, name: $name, contactInfo: $contactInfo}';
  }
}
