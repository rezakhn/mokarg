// مدل داده ای برای نمایش ترکیب یک قطعه مونتاژی
// این کلاس مشخص می کند که یک قطعه مونتاژی (assembly) از چه قطعات دیگری (components) و به چه مقدار تشکیل شده است
class PartComposition {
  final int? id; // شناسه یکتای این رکورد ترکیب (اختیاری)
  final int assemblyId;      // شناسه قطعه مونتاژی (کلید خارجی به جدول Part که isAssembly آن true است)
  final int componentPartId; // شناسه قطعه جزء (کلید خارجی به جدول Part، می تواند خودش یک قطعه خام یا یک مجموعه مونتاژی دیگر باشد)
  final double quantity;      // مقدار قطعه جزء که برای ساخت یک واحد از قطعه مونتاژی لازم است

  // سازنده کلاس PartComposition
  PartComposition({
    this.id,
    required this.assemblyId, // شناسه قطعه مونتاژی الزامی است
    required this.componentPartId, // شناسه قطعه جزء الزامی است
    required this.quantity, // مقدار الزامی است
  });

  // تبدیل شی PartComposition به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assembly_id': assemblyId,
      'component_part_id': componentPartId,
      'quantity': quantity,
    };
  }

  // ایجاد یک شی PartComposition از یک نقشه (Map) که از پایگاه داده خوانده شده است
  factory PartComposition.fromMap(Map<String, dynamic> map) {
    return PartComposition(
      id: map['id'],
      assemblyId: map['assembly_id'],
      componentPartId: map['component_part_id'],
      quantity: map['quantity']?.toDouble() ?? 0.0, // تبدیل به double و مقدار پیش فرض
    );
  }

  // بازنمایی رشته ای از شی PartComposition برای چاپ و اشکال زدایی
  @override
  String toString() {
    return 'PartComposition{id: $id, assemblyId: $assemblyId, componentPartId: $componentPartId, quantity: $quantity}';
  }
}
