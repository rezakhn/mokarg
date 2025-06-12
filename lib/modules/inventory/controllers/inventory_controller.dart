import 'package:flutter/foundation.dart'; // برای استفاده از ChangeNotifier
import '../../../core/database_service.dart'; // سرویس پایگاه داده
import '../models/inventory_item.dart'; // مدل آیتم موجودی
import '../../../core/notifiers/inventory_sync_notifier.dart'; // اطلاع رسان همگام سازی موجودی

// کنترلر برای مدیریت داده ها و منطق مربوط به موجودی کالا
class InventoryController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService(); // نمونه ای از سرویس پایگاه داده
  final InventorySyncNotifier _inventorySyncNotifier; // نمونه ای از اطلاع رسان همگام سازی موجودی

  List<InventoryItem> _inventoryItems = []; // لیست خصوصی آیتم های موجودی
  List<InventoryItem> get inventoryItems => _inventoryItems; // گتر عمومی برای لیست آیتم های موجودی

  List<InventoryItem> _lowStockItems = []; // لیست خصوصی آیتم های با موجودی کم (نیاز به سفارش)
  List<InventoryItem> get lowStockItems => _lowStockItems; // گتر عمومی برای لیست آیتم های با موجودی کم

  InventoryItem? _selectedInventoryItem; // آیتم موجودی انتخاب شده فعلی
  InventoryItem? get selectedInventoryItem => _selectedInventoryItem; // گتر عمومی برای آیتم موجودی انتخاب شده

  bool _isLoading = false; // وضعیت بارگذاری اطلاعات
  bool get isLoading => _isLoading; // گتر عمومی برای وضعیت بارگذاری

  String? _errorMessage; // پیام خطا در صورت بروز مشکل
  String? get errorMessage => _errorMessage; // گتر عمومی برای پیام خطا

  // سازنده کنترلر که اطلاع رسان همگام سازی موجودی را دریافت می کند
  InventoryController(this._inventorySyncNotifier) {
    // افزودن شنونده به اطلاع رسان همگام سازی موجودی
    // هرگاه تغییری در موجودی از بخش دیگری از برنامه اعلام شود، متد _handleInventorySync فراخوانی می شود
    _inventorySyncNotifier.addListener(_handleInventorySync);
    // به صورت اختیاری می توان آیتم ها را هنگام مقداردهی اولیه کنترلر واکشی کرد
    // fetchInventoryItems();
  }

  // متدی که هنگام دریافت اعلان از InventorySyncNotifier فراخوانی می شود
  void _handleInventorySync() {
    fetchInventoryItems(); // واکشی مجدد لیست آیتم های موجودی برای اطمینان از به روز بودن داده ها
  }

  // این متد زمانی فراخوانی می شود که کنترلر از بین می رود (dispose)
  // مهم است که شنونده ها در اینجا حذف شوند تا از نشت حافظه (memory leak) جلوگیری شود
  @override
  void dispose() {
    _inventorySyncNotifier.removeListener(_handleInventorySync); // حذف شنونده
    super.dispose();
  }

  // متد خصوصی برای تنظیم وضعیت بارگذاری و اطلاع رسانی به شنوندگان
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners(); // اطلاع رسانی به ویجت ها برای به روزرسانی UI
  }

  // متد خصوصی برای تنظیم پیام خطا و اطلاع رسانی به شنوندگان
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // واکشی لیست آیتم های موجودی از پایگاه داده
  // قابلیت جستجو بر اساس نام آیتم (query)
  Future<void> fetchInventoryItems({String? query}) async {
    _setLoading(true);
    _setError(null);
    try {
      _inventoryItems = await _dbService.getAllInventoryItems(query: query); // دریافت آیتم ها از سرویس پایگاه داده
      _filterLowStockItems(); // فیلتر کردن آیتم های با موجودی کم پس از واکشی
    } catch (e) {
      _setError('بارگیری لیست آیتم های موجودی با شکست مواجه شد: ${e.toString()}');
      _inventoryItems = []; // اطمینان از خالی بودن لیست ها در صورت خطا
      _lowStockItems = [];
    }
    _setLoading(false);
  }

  // متد خصوصی برای فیلتر کردن و جدا کردن آیتم هایی که مقدارشان از حد آستانه کمتر است
  void _filterLowStockItems() {
    _lowStockItems = _inventoryItems.where((item) => item.quantity < item.threshold).toList();
    // در اینجا notifyListeners() فراخوانی نمی شود زیرا این متد توسط متدهای عمومی که خودشان notifyListeners() را صدا می زنند، فراخوانی می شود
  }

  // انتخاب یک آیتم موجودی
  void selectInventoryItem(InventoryItem? item) {
    _selectedInventoryItem = item;
    notifyListeners(); // اطلاع رسانی برای به روزرسانی UI
  }

  // دریافت جزئیات یک آیتم موجودی خاص بر اساس نام آن
  Future<InventoryItem?> getInventoryItemDetails(String itemName) async {
    _setLoading(true);
    _setError(null);
    try {
      final item = await _dbService.getInventoryItemByName(itemName);
      _setLoading(false);
      return item;
    } catch (e) {
       _setError('واکشی جزئیات آیتم با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  // به روزرسانی حد آستانه (threshold) برای یک آیتم موجودی
  Future<bool> updateItemThreshold(String itemName, double newThreshold) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateInventoryItemThreshold(itemName, newThreshold); // به روزرسانی در پایگاه داده
      // به روزرسانی آیتم در لیست محلی یا واکشی مجدد کل لیست
      final index = _inventoryItems.indexWhere((item) => item.itemName == itemName);
      if (index != -1) {
        // واکشی آیتم به روز شده برای دریافت مقدار جدید (ممکن است عملیات دیگری همزمان رخ داده باشد)
        final updatedItem = await _dbService.getInventoryItemByName(itemName);
        if(updatedItem != null){
             _inventoryItems[index] = updatedItem; // جایگزینی آیتم در لیست
        } else {
            // اگر آیتم پس از به روزرسانی دیگر وجود نداشت (مثلا توسط فرآیند دیگری حذف شده)
            _inventoryItems.removeAt(index);
        }
      } else {
        // اگر آیتم در لیست نبود (مثلا حد آستانه برای آیتم جدیدی تنظیم شده)، کل لیست را واکشی کن
        await fetchInventoryItems();
      }
      _filterLowStockItems(); // فیلتر مجدد آیتم های با موجودی کم
      _setLoading(false);
      // به روزرسانی آیتم انتخاب شده اگر همان آیتمی است که تغییر کرده
      if (_selectedInventoryItem?.itemName == itemName) {
          // استفاده از orElse برای جلوگیری از خطا در صورتی که آیتم دیگر در لیست نباشد
          _selectedInventoryItem = _inventoryItems.firstWhere((i) => i.itemName == itemName, orElse: () => null as InventoryItem?);
      }
      notifyListeners(); // اطمینان از به روزرسانی UI برای آیتم انتخاب شده در صورت لزوم
      return true;
    } catch (e) {
      _setError('به روزرسانی حد آستانه برای $itemName با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // متد برای تنظیم دستی مقدار موجودی (در حال حاضر در برنامه استفاده نمی شود اما برای آینده ممکن است مفید باشد)
  // Future<bool> manuallyAdjustItemQuantity(String itemName, double newQuantity) async {
  //   _setLoading(true);
  //   _setError(null);
  //   try {
  //     await _dbService.manuallyAdjustInventoryItemQuantity(itemName, newQuantity);
  //     // Refresh item or list
  //     // ...
  //     _filterLowStockItems();
  //     _setLoading(false);
  //     return true;
  //   } catch (e) {
  //     _setError('Failed to adjust quantity for $itemName: ${e.toString()}');
  //     _setLoading(false);
  //     return false;
  //   }
  // }
}
