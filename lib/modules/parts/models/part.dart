// مدل داده ای برای نمایش اطلاعات یک قطعه یا یک ماده اولیه
class Part {
  final int? id; // شناسه یکتای قطعه در پایگاه داده (اختیاری)
  final String name; // نام قطعه یا ماده
  final bool isAssembly; // آیا این قطعه یک مجموعه مونتاژی است؟
                       // true اگر مجموعه مونتاژی باشد (یعنی از قطعات دیگر تشکیل شده)
                       // false اگر یک جزء خام یا ماده اولیه باشد

  // سازنده کلاس Part
  Part({
    this.id,
    required this.name, // نام الزامی است
    required this.isAssembly, // مشخص کردن اینکه آیا مونتاژی است یا خیر، الزامی است
  });

  // تبدیل شی Part به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_assembly': isAssembly ? 1 : 0, // ذخیره به صورت عدد صحیح (0 یا 1) در پایگاه داده
    };
  }

  // ایجاد یک شی Part از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory Part.fromMap(Map<String, dynamic> map) {
    return Part(
      id: map['id'],
      name: map['name'],
      isAssembly: map['is_assembly'] == 1, // تبدیل عدد صحیح به بولین
    );
  }

  // بازنمایی رشته ای از شی Part برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'Part{id: $id, name: $name, isAssembly: $isAssembly}';
  }
}
