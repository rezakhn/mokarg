// مدل داده ای برای نمایش اطلاعات یک فاکتور خرید
class PurchaseInvoice {
  final int? id; // شناسه یکتای فاکتور خرید در پایگاه داده (اختیاری)
  final int supplierId; // شناسه تامین کننده (کلید خارجی به جدول تامین کنندگان)
  final DateTime date; // تاریخ فاکتور خرید
  double totalAmount; // مبلغ کل فاکتور (محاسبه شده از آیتم ها، اما می تواند ذخیره هم شود)
  List<PurchaseItem> items; // لیست آیتم های موجود در این فاکتور خرید

  // سازنده کلاس PurchaseInvoice
  PurchaseInvoice({
    this.id,
    required this.supplierId, // شناسه تامین کننده الزامی است
    required this.date, // تاریخ الزامی است
    this.totalAmount = 0.0, // مبلغ کل با مقدار پیش فرض 0.0
    this.items = const [], // لیست آیتم ها با مقدار پیش فرض یک لیست خالی و ثابت
  });

  // تبدیل شی PurchaseInvoice به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  // توجه: لیست آیتم ها در اینجا گنجانده نشده و باید جداگانه مدیریت شود
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'date': date.toIso8601String().substring(0, 10), // ذخیره تاریخ به فرمت YYYY-MM-DD
      'total_amount': totalAmount,
    };
  }

  // ایجاد یک شی PurchaseInvoice از یک نقشه (Map) و لیست آیتم های آن
  factory PurchaseInvoice.fromMap(Map<String, dynamic> map, List<PurchaseItem> items) {
    return PurchaseInvoice(
      id: map['id'],
      supplierId: map['supplier_id'],
      date: DateTime.parse(map['date']), // تبدیل رشته تاریخ به DateTime
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      items: items, // تنظیم لیست آیتم ها
    );
  }

  // محاسبه مبلغ کل فاکتور بر اساس مجموع قیمت کل آیتم های آن
  void calculateTotalAmount() {
    totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // بازنمایی رشته ای از شی PurchaseInvoice
  @override
  String toString() {
    return 'PurchaseInvoice{id: $id, supplierId: $supplierId, date: $date, totalAmount: $totalAmount, items: ${items.length}}';
  }
}

// مدل داده ای برای نمایش اطلاعات یک آیتم در فاکتور خرید
class PurchaseItem {
  final int? id; // شناسه یکتای آیتم فاکتور (اختیاری)
  final int? invoiceId; // شناسه فاکتور خریدی که این آیتم به آن تعلق دارد (کلید خارجی)
  final String itemName; // نام آیتم (در حال حاضر مستقیما نام آیتم استفاده می شود، در آینده می تواند شناسه قطعه باشد)
  final double quantity; // مقدار خریداری شده
  final double unitPrice; // قیمت واحد
  late final double totalPrice; // قیمت کل (محاسبه شده: مقدار * قیمت واحد) - late final چون در سازنده مقداردهی می شود

  // سازنده کلاس PurchaseItem
  PurchaseItem({
    this.id,
    this.invoiceId,
    required this.itemName, // نام آیتم الزامی است
    required this.quantity, // مقدار الزامی است
    required this.unitPrice, // قیمت واحد الزامی است
  }) {
    totalPrice = quantity * unitPrice; // محاسبه قیمت کل هنگام ایجاد شی
  }

  // تبدیل شی PurchaseItem به یک نقشه (Map) برای ذخیره سازی در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  // ایجاد یک شی PurchaseItem از یک نقشه (Map)
  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      itemName: map['item_name'],
      quantity: map['quantity']?.toDouble() ?? 0.0,
      unitPrice: map['unit_price']?.toDouble() ?? 0.0,
      // totalPrice در سازنده محاسبه می شود، یا اگر در پایگاه داده ذخیره شده باشد، می توان از map['total_price'] خواند
    );
  }

  // بازنمایی رشته ای از شی PurchaseItem
  @override
  String toString() {
    return 'PurchaseItem{id: $id, itemName: $itemName, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice}';
  }
}
