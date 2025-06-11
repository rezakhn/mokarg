import 'package:flutter/foundation.dart'; // ایمپورت پکیج foundation برای استفاده از ChangeNotifier

// کلاس InventorySyncNotifier یک ChangeNotifier است که برای همگام سازی وضعیت موجودی بین بخش های مختلف برنامه استفاده می شود.
// سایر کنترلرها (مانند PurchaseController) می توانند متد notifyInventoryChanged را فراخوانی کنند
// و InventoryController به این ChangeNotifier گوش می دهد تا در صورت تغییر، لیست موجودی خود را به روز کند.
class InventorySyncNotifier with ChangeNotifier {
  // این متد زمانی فراخوانی می شود که تغییری در موجودی رخ داده است (مثلا پس از ثبت فاکتور خرید یا فروش).
  // با فراخوانی notifyListeners()، تمام شنوندگان (مانند InventoryController) از این تغییر مطلع می شوند.
  void notifyInventoryChanged() {
    notifyListeners(); // اطلاع رسانی به تمام شنوندگان
  }
}
