import 'package:flutter/foundation.dart'; // برای استفاده از ChangeNotifier
import '../../../core/database_service.dart'; // سرویس پایگاه داده
import '../models/supplier.dart'; // مدل تامین کننده
import '../models/purchase_invoice.dart'; // مدل فاکتور خرید
import '../../../core/notifiers/inventory_sync_notifier.dart'; // اطلاع رسان همگام سازی موجودی

// کنترلر برای مدیریت داده ها و منطق مربوط به تامین کنندگان و فاکتورهای خرید
class PurchaseController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService(); // نمونه ای از سرویس پایگاه داده
  final InventorySyncNotifier _inventorySyncNotifier; // نمونه ای از اطلاع رسان همگام سازی موجودی

  // --- State مربوط به تامین کنندگان ---
  List<Supplier> _suppliers = []; // لیست خصوصی تامین کنندگان
  List<Supplier> get suppliers => _suppliers; // گتر عمومی برای لیست تامین کنندگان
  Supplier? _selectedSupplier; // تامین کننده انتخاب شده فعلی
  Supplier? get selectedSupplier => _selectedSupplier; // گتر عمومی برای تامین کننده انتخاب شده

  // --- State مربوط به فاکتورهای خرید ---
  List<PurchaseInvoice> _purchaseInvoices = []; // لیست خصوصی فاکتورهای خرید
  List<PurchaseInvoice> get purchaseInvoices => _purchaseInvoices; // گتر عمومی برای لیست فاکتورهای خرید
  PurchaseInvoice? _selectedPurchaseInvoice; // فاکتور خرید انتخاب شده فعلی
  PurchaseInvoice? get selectedPurchaseInvoice => _selectedPurchaseInvoice; // گتر عمومی برای فاکتور خرید انتخاب شده

  // --- State مشترک ---
  bool _isLoading = false; // وضعیت بارگذاری اطلاعات
  bool get isLoading => _isLoading; // گتر عمومی برای وضعیت بارگذاری
  String? _errorMessage; // پیام خطا در صورت بروز مشکل
  String? get errorMessage => _errorMessage; // گتر عمومی برای پیام خطا

  // سازنده کنترلر که اطلاع رسان همگام سازی موجودی را دریافت می کند
  PurchaseController(this._inventorySyncNotifier) {
    // به صورت اختیاری می توان داده های اولیه را هنگام ایجاد کنترلر بارگذاری کرد
    // fetchSuppliers();
    // fetchPurchaseInvoices();
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

  // --- متدهای مربوط به تامین کنندگان ---
  // واکشی لیست تامین کنندگان از پایگاه داده
  // قابلیت جستجو بر اساس نام تامین کننده (query)
  Future<void> fetchSuppliers({String? query}) async {
    _setLoading(true);
    _setError(null);
    try {
      _suppliers = await _dbService.getSuppliers(query: query); // دریافت تامین کنندگان از سرویس پایگاه داده
    } catch (e) {
      _setError('بارگیری لیست تامین کنندگان با شکست مواجه شد: ${e.toString()}');
      _suppliers = []; // اطمینان از خالی بودن لیست در صورت خطا
    }
    _setLoading(false);
  }

  // افزودن یک تامین کننده جدید
  Future<bool> addSupplier(Supplier supplier) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertSupplier(supplier); // درج تامین کننده در پایگاه داده
      await fetchSuppliers(); // واکشی مجدد لیست تامین کنندگان برای به روزرسانی
      _setLoading(false);
      return true; // عملیات موفقیت آمیز بود
    } catch (e) {
      _setError('افزودن تامین کننده با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false; // عملیات ناموفق بود
    }
  }

  // دریافت اطلاعات یک تامین کننده خاص بر اساس شناسه
  Future<Supplier?> getSupplierById(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      final supplier = await _dbService.getSupplierById(id);
      _setLoading(false);
      return supplier;
    } catch (e) {
      _setError('دریافت اطلاعات تامین کننده با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  // به روزرسانی اطلاعات یک تامین کننده موجود
  Future<bool> updateSupplier(Supplier supplier) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateSupplier(supplier); // به روزرسانی تامین کننده در پایگاه داده
      await fetchSuppliers(); // واکشی مجدد لیست تامین کنندگان
      // اگر تامین کننده به روز شده همان تامین کننده انتخاب شده فعلی است، اطلاعات آن را نیز به روز کن
      if (_selectedSupplier?.id == supplier.id) {
        _selectedSupplier = await _dbService.getSupplierById(supplier.id!);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('به روزرسانی تامین کننده با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // حذف یک تامین کننده بر اساس شناسه
  Future<bool> deleteSupplier(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteSupplier(id); // حذف تامین کننده از پایگاه داده
      await fetchSuppliers(); // واکشی مجدد لیست تامین کنندگان
      // همچنین لیست فاکتورها را نیز به روز کن، زیرا ممکن است برخی به دلیل حذف تامین کننده (بسته به محدودیت های پایگاه داده) حذف شده باشند یا حذف تامین کننده ممنوع شده باشد
      await fetchPurchaseInvoices();
      if (_selectedSupplier?.id == id) {
        _selectedSupplier = null; // اگر تامین کننده حذف شده انتخاب شده بود، آن را از انتخاب خارج کن
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('حذف تامین کننده با شکست مواجه شد: ${e.toString()}. بررسی کنید آیا فاکتورهای خرید مرتبطی دارد یا خیر.');
      _setLoading(false);
      return false;
    }
  }

  // انتخاب یک تامین کننده
  void selectSupplier(Supplier? supplier) {
    _selectedSupplier = supplier;
    notifyListeners(); // اطلاع رسانی برای به روزرسانی UI
    // به صورت اختیاری، می توان فاکتورهای مربوط به این تامین کننده را واکشی کرد اگر UI نیاز داشته باشد
    // if (supplier != null) {
    //   fetchPurchaseInvoices(supplierId: supplier.id);
    // } else {
    //   fetchPurchaseInvoices(); // واکشی همه یا پاک کردن لیست
    // }
  }

  // --- متدهای مربوط به فاکتورهای خرید ---
  // واکشی لیست فاکتورهای خرید از پایگاه داده
  // قابلیت فیلتر بر اساس تاریخ شروع، تاریخ پایان و شناسه تامین کننده
  Future<void> fetchPurchaseInvoices({DateTime? startDate, DateTime? endDate, int? supplierId}) async {
    _setLoading(true);
    _setError(null);
    try {
      _purchaseInvoices = await _dbService.getPurchaseInvoices(
        startDate: startDate,
        endDate: endDate,
        supplierId: supplierId,
      );
    } catch (e) {
      _setError('بارگیری لیست فاکتورهای خرید با شکست مواجه شد: ${e.toString()}');
      _purchaseInvoices = []; // اطمینان از خالی بودن لیست در صورت خطا
    }
    _setLoading(false);
  }

  // افزودن یک فاکتور خرید جدید
  Future<bool> addPurchaseInvoice(PurchaseInvoice invoice) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertPurchaseInvoice(invoice); // درج فاکتور خرید در پایگاه داده (این متد موجودی را هم به روز می کند)
      await fetchPurchaseInvoices(); // واکشی مجدد لیست فاکتورهای خرید
      _setLoading(false);
      _inventorySyncNotifier.notifyInventoryChanged(); // اطلاع رسانی به سایر بخش ها برای به روزرسانی موجودی
      return true;
    } catch (e) {
      _setError('افزودن فاکتور خرید با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // دریافت اطلاعات یک فاکتور خرید خاص بر اساس شناسه
  Future<PurchaseInvoice?> getPurchaseInvoiceById(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      final invoice = await _dbService.getPurchaseInvoiceById(id);
      _setLoading(false);
      return invoice;
    } catch (e) {
      _setError('دریافت اطلاعات فاکتور خرید با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  // به روزرسانی یک فاکتور خرید موجود
  Future<bool> updatePurchaseInvoice(PurchaseInvoice invoice) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updatePurchaseInvoice(invoice); // به روزرسانی فاکتور خرید در پایگاه داده (این متد موجودی را هم به روز می کند)
      await fetchPurchaseInvoices(); // واکشی مجدد لیست فاکتورهای خرید
      // اگر فاکتور به روز شده همان فاکتور انتخاب شده فعلی است، اطلاعات آن را نیز به روز کن
      if (_selectedPurchaseInvoice?.id == invoice.id) {
         _selectedPurchaseInvoice = await _dbService.getPurchaseInvoiceById(invoice.id!);
      }
      _setLoading(false);
      _inventorySyncNotifier.notifyInventoryChanged(); // اطلاع رسانی به سایر بخش ها برای به روزرسانی موجودی
      return true;
    } catch (e) {
      _setError('به روزرسانی فاکتور خرید با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // حذف یک فاکتور خرید بر اساس شناسه
  Future<bool> deletePurchaseInvoice(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deletePurchaseInvoice(id); // حذف فاکتور خرید از پایگاه داده (این متد موجودی را هم به روز می کند)
      await fetchPurchaseInvoices(); // واکشی مجدد لیست فاکتورهای خرید
      if (_selectedPurchaseInvoice?.id == id) {
        _selectedPurchaseInvoice = null; // اگر فاکتور حذف شده انتخاب شده بود، آن را از انتخاب خارج کن
      }
      _setLoading(false);
      _inventorySyncNotifier.notifyInventoryChanged(); // اطلاع رسانی به سایر بخش ها برای به روزرسانی موجودی
      return true;
    } catch (e) {
      _setError('حذف فاکتور خرید با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // انتخاب یک فاکتور خرید
  void selectPurchaseInvoice(PurchaseInvoice? invoice) {
    _selectedPurchaseInvoice = invoice;
    notifyListeners(); // اطلاع رسانی برای به روزرسانی UI
  }
}
