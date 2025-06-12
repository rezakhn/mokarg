import 'package:flutter/foundation.dart'; // برای استفاده از ChangeNotifier
import '../../../core/database_service.dart'; // سرویس پایگاه داده
import '../models/customer.dart'; // مدل مشتری
import '../models/sales_order.dart'; // مدل سفارش فروش
import '../models/order_item.dart'; // مدل آیتم سفارش
import '../models/payment.dart'; // مدل پرداخت
import '../../parts/models/product.dart'; // برای واکشی لیست محصولات جهت استفاده در سفارشات
import '../../parts/models/part.dart';    // برای بررسی جزئیات قطعات تشکیل دهنده (در بررسی موجودی)
import '../../inventory/models/inventory_item.dart'; // برای بررسی موجودی انبار
import '../../../core/notifiers/inventory_sync_notifier.dart'; // اطلاع رسان همگام سازی موجودی

// کنترلر برای مدیریت داده ها و منطق مربوط به مشتریان، سفارشات فروش و پرداخت ها
class OrderController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService(); // نمونه ای از سرویس پایگاه داده
  final InventorySyncNotifier _inventorySyncNotifier; // نمونه ای از اطلاع رسان همگام سازی موجودی

  // --- State مربوط به مشتریان ---
  List<Customer> _customers = []; // لیست خصوصی مشتریان
  List<Customer> get customers => _customers; // گتر عمومی برای لیست مشتریان
  Customer? _selectedCustomer; // مشتری انتخاب شده فعلی
  Customer? get selectedCustomer => _selectedCustomer; // گتر عمومی برای مشتری انتخاب شده

  // --- State مربوط به سفارشات فروش ---
  List<SalesOrder> _salesOrders = []; // لیست خصوصی سفارشات فروش
  List<SalesOrder> get salesOrders => _salesOrders; // گتر عمومی برای لیست سفارشات فروش
  SalesOrder? _selectedSalesOrder; // سفارش فروش انتخاب شده فعلی (شامل آیتم ها و پرداخت ها پس از بارگذاری کامل)
  SalesOrder? get selectedSalesOrder => _selectedSalesOrder; // گتر عمومی

  // لیست محصولات موجود برای انتخاب در آیتم های سفارش
  List<Product> _availableProducts = [];
  List<Product> get availableProducts => _availableProducts;
  // نقشه برای نگهداری نام محصولات بر اساس شناسه آنها (برای نمایش)
  Map<int, String> _productIdToNameMap = {};
  Map<int, String> get productIdToNameMap => _productIdToNameMap;

  // اطلاعات مربوط به در دسترس بودن / کمبود آیتم ها برای سفارش انتخاب شده
  Map<String, double> _itemShortages = {}; // کلید: نام قطعه/محصول، مقدار: مقدار کمبود
  Map<String, double> get itemShortages => _itemShortages;
  bool _isCheckingStock = false; // آیا در حال بررسی موجودی هستیم؟
  bool get isCheckingStock => _isCheckingStock;

  // --- State مشترک ---
  bool _isLoading = false; // وضعیت بارگذاری اطلاعات
  bool get isLoading => _isLoading; // گتر عمومی برای وضعیت بارگذاری
  String? _errorMessage; // پیام خطا در صورت بروز مشکل
  String? get errorMessage => _errorMessage; // گتر عمومی برای پیام خطا

  // سازنده کنترلر
  OrderController(this._inventorySyncNotifier) { // دریافت اطلاع رسان در سازنده
    // واکشی داده های اولیه می تواند اینجا انجام شود یا توسط UI فراخوانی شود
    // fetchCustomers();
    // fetchAvailableProducts();
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

  // متد خصوصی برای به روزرسانی نقشه نام محصولات بر اساس شناسه
  Future<void> _updateProductIdToNameMap(List<Product> productsList) async {
    _productIdToNameMap = {for (var p in productsList) p.id!: p.name};
  }

  // --- متدهای مربوط به مشتریان ---

  // واکشی لیست مشتریان از پایگاه داده
  // قابلیت جستجو بر اساس نام مشتری (query)
  Future<void> fetchCustomers({String? query}) async {
    _setLoading(true); _setError(null);
    try {
      _customers = await _dbService.getCustomers(query: query); // دریافت مشتریان از سرویس پایگاه داده
    } catch (e) {
      _setError('بارگیری لیست مشتریان با شکست مواجه شد: ${e.toString()}');
      _customers = []; // خالی کردن لیست در صورت خطا
    }
    _setLoading(false);
  }

  // افزودن یک مشتری جدید
  Future<bool> addCustomer(Customer customer) async {
    _setLoading(true); _setError(null);
    try {
      await _dbService.insertCustomer(customer); // درج مشتری در پایگاه داده
      await fetchCustomers(); // واکشی مجدد لیست مشتریان برای به روزرسانی
      _setLoading(false); return true; // عملیات موفقیت آمیز بود
    } catch (e) {
      _setError('افزودن مشتری با شکست مواجه شد: ${e.toString()}');
      _setLoading(false); return false; // عملیات ناموفق بود
    }
  }

  // به روزرسانی اطلاعات یک مشتری موجود
  Future<bool> updateCustomer(Customer customer) async {
    _setLoading(true); _setError(null);
    try {
      await _dbService.updateCustomer(customer); // به روزرسانی مشتری در پایگاه داده
      await fetchCustomers(); // واکشی مجدد لیست مشتریان
      // اگر مشتری به روز شده همان مشتری انتخاب شده فعلی است، اطلاعات آن را نیز به روز کن
      if (_selectedCustomer?.id == customer.id) _selectedCustomer = customer;
      _setLoading(false); return true;
    } catch (e) {
      _setError('به روزرسانی مشتری با شکست مواجه شد: ${e.toString()}');
      _setLoading(false); return false;
    }
  }

  // حذف یک مشتری بر اساس شناسه
  Future<bool> deleteCustomer(int id) async {
    _setLoading(true); _setError(null);
    try {
      await _dbService.deleteCustomer(id); // حذف مشتری از پایگاه داده
      await fetchCustomers(); // واکشی مجدد لیست مشتریان
      if (_selectedCustomer?.id == id) _selectedCustomer = null; // اگر مشتری حذف شده انتخاب شده بود، آن را از انتخاب خارج کن
      // همچنین سفارشات فروش مرتبط با این مشتری را از لیست محلی حذف کن یا اجازه بده پایگاه داده محدودیت را اعمال کند
      // این کار از نمایش سفارشات بدون مشتری در UI جلوگیری می کند، اما باید با رفتار پایگاه داده (ON DELETE RESTRICT) هماهنگ باشد
      _salesOrders.removeWhere((order) => order.customerId == id);
      notifyListeners(); // برای اعمال تغییر در _salesOrders
      _setLoading(false); return true;
    } catch (e) {
      // معمولا به این دلیل است که مشتری سفارشات فروش موجود دارد
      _setError('حذف مشتری با شکست مواجه شد (ممکن است سفارشات فعالی داشته باشد): ${e.toString()}');
      _setLoading(false); return false;
    }
  }

  // انتخاب یک مشتری
  void selectCustomer(Customer? customer){
    _selectedCustomer = customer;
    notifyListeners(); // اطلاع رسانی برای به روزرسانی UI
  }

  // --- متدهای مربوط به لیست محصولات برای آیتم های سفارش ---

  // واکشی لیست محصولات موجود برای انتخاب در آیتم های سفارش
  // این محصولات از جدول محصولات (parts module) خوانده می شوند
  Future<void> fetchAvailableProducts() async {
    // این لیست می تواند از PartController نیز دریافت شود اگر آن کنترلر محصولات را مدیریت کند،
    // اما واکشی مستقیم در اینجا نیز برای سادگی فعلی مناسب است.
    _setLoading(true); _setError(null);
    try {
      _availableProducts = await _dbService.getProducts(); // دریافت همه محصولات
      await _updateProductIdToNameMap(_availableProducts); // به روزرسانی نقشه شناسه به نام محصول
    } catch (e) {
      _setError('بارگیری لیست محصولات موجود با شکست مواجه شد: ${e.toString()}');
      _availableProducts = [];
    }
    _setLoading(false);
  }

  // --- متدهای مربوط به سفارشات فروش ---

  // واکشی لیست سفارشات فروش از پایگاه داده
  // قابلیت فیلتر بر اساس وضعیت سفارش (status) و شناسه مشتری (customerId)
  Future<void> fetchSalesOrders({String? status, int? customerId}) async {
    _setLoading(true); _setError(null);
    try {
      _salesOrders = await _dbService.getSalesOrders(status: status, customerId: customerId);
      // اطمینان از اینکه نام محصولات برای نمایش در دسترس است
      if(_availableProducts.isEmpty && _salesOrders.isNotEmpty) {
          // اگر لیست محصولات موجود خالی است و سفارشاتی وجود دارد (که ممکن است نیاز به نمایش نام محصول داشته باشند)
          // محصولات موجود را واکشی کن
          await fetchAvailableProducts();
      }
    } catch (e) {
      _setError('بارگیری لیست سفارشات فروش با شکست مواجه شد: ${e.toString()}');
      _salesOrders = []; // خالی کردن لیست در صورت خطا
    }
    _setLoading(false);
  }

  // دریافت جزئیات کامل یک سفارش فروش بر اساس شناسه آن (شامل آیتم ها و پرداخت ها)
  Future<SalesOrder?> getFullSalesOrderDetails(int orderId) async {
    _setLoading(true); _setError(null);
    try {
      final order = await _dbService.getSalesOrderById(orderId); // این متد از سرویس، آیتم ها و پرداخت ها را نیز واکشی می کند
      // اگر سفارش دریافت شد و لیست محصولات موجود هنوز خالی است، آنها را واکشی کن
      if (order != null && _availableProducts.isEmpty) {
          await fetchAvailableProducts();
      }
      _setLoading(false);
      return order;
    } catch (e) {
      _setError('بارگیری جزئیات سفارش با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  // افزودن یک سفارش فروش جدید
  Future<bool> addSalesOrder(SalesOrder order) async {
    _setLoading(true); _setError(null);
    try {
      // فرض بر این است که آیتم ها از قبل بخشی از شیء order هستند که به این متد پاس داده می شود
      order.calculateTotalAmount(); // محاسبه مبلغ کل سفارش بر اساس آیتم های آن
      await _dbService.insertSalesOrder(order); // درج سفارش در پایگاه داده
      await fetchSalesOrders(); // واکشی مجدد لیست سفارشات برای به روزرسانی
      _setLoading(false); return true; // عملیات موفقیت آمیز بود
    } catch (e) {
      _setError('افزودن سفارش فروش با شکست مواجه شد: ${e.toString()}');
      _setLoading(false); return false; // عملیات ناموفق بود
    }
  }

  // به روزرسانی یک سفارش فروش موجود
  Future<bool> updateSalesOrder(SalesOrder order) async {
    _setLoading(true); _setError(null);
    try {
      order.calculateTotalAmount(); // محاسبه مجدد مبلغ کل سفارش
      await _dbService.updateSalesOrder(order); // به روزرسانی سفارش در پایگاه داده
      await fetchSalesOrders(); // واکشی مجدد لیست سفارشات
      // اگر سفارش به روز شده همان سفارش انتخاب شده فعلی است، اطلاعات آن را نیز به روز کن
      if (_selectedSalesOrder?.id == order.id) {
        _selectedSalesOrder = await _dbService.getSalesOrderById(order.id!); // واکشی مجدد برای دریافت آیتم ها و پرداخت های به روز شده
      }
      _setLoading(false); return true;
    } catch (e) {
      _setError('به روزرسانی سفارش فروش با شکست مواجه شد: ${e.toString()}');
      _setLoading(false); return false;
    }
  }

  // به روزرسانی وضعیت یک سفارش فروش
  Future<bool> updateSalesOrderStatus(int orderId, String newStatus) async {
    _setLoading(true); _setError(null);
    try {
      // اگر وضعیت جدید "Completed" است، باید از طریق متد completeSelectedSalesOrder انجام شود
      // تا موجودی انبار نیز به درستی به روز شود.
      if (newStatus == "Completed") {
          // فراخوانی متد مخصوص تکمیل سفارش که موجودی را نیز مدیریت می کند
          // پارامتر دوم (calledFromStatusUpdate) برای جلوگیری از حلقه بی نهایت یا خطای "already completed" است
          return await completeSelectedSalesOrder(orderId, calledFromStatusUpdate: true);
      } else {
        // برای سایر تغییرات وضعیت، فقط وضعیت را در پایگاه داده به روز کن
        await _dbService.updateSalesOrderStatus(orderId, newStatus);
        // و اطلاعات سفارش را در لیست محلی و در صورت انتخاب بودن، به روز کن
        final updatedOrder = await _dbService.getSalesOrderById(orderId);
        if (updatedOrder != null) {
          int index = _salesOrders.indexWhere((o) => o.id == orderId);
          if (index != -1) _salesOrders[index] = updatedOrder;
          if (_selectedSalesOrder?.id == orderId) _selectedSalesOrder = updatedOrder;
        }
      }
      _setLoading(false); return true;
    } catch (e) {
      _setError('به روزرسانی وضعیت سفارش با شکست مواجه شد: ${e.toString()}');
      _setLoading(false); return false;
    }
  }

  // حذف یک سفارش فروش بر اساس شناسه
  Future<bool> deleteSalesOrder(int id) async {
    _setLoading(true); _setError(null);
    try {
      await _dbService.deleteSalesOrder(id); // حذف سفارش از پایگاه داده (آیتم ها و پرداخت ها با CASCADE حذف می شوند)
      await fetchSalesOrders(); // واکشی مجدد لیست سفارشات
      // اگر سفارش حذف شده، سفارش انتخاب شده فعلی بود، آن را از انتخاب خارج کن
      if (_selectedSalesOrder?.id == id) _selectedSalesOrder = null;
      _setLoading(false); return true;
    } catch (e) {
      _setError('حذف سفارش فروش با شکست مواجه شد: ${e.toString()}');
      _setLoading(false); return false;
    }
  }

  // انتخاب یک سفارش فروش و واکشی جزئیات کامل آن
  Future<void> selectSalesOrder(int orderId) async {
    _setLoading(true); _setError(null);
    _itemShortages = {}; // پاک کردن اطلاعات کمبود آیتم های قبلی
    try {
      // واکشی سفارش به همراه آیتم ها و پرداخت های آن
      _selectedSalesOrder = await _dbService.getSalesOrderById(orderId);
      if (_selectedSalesOrder != null) {
        // اگر لیست محصولات موجود خالی است، آن را واکشی کن (برای نمایش نام محصولات)
        if (_availableProducts.isEmpty) await fetchAvailableProducts();
        // به صورت اختیاری، می توان بلافاصله موجودی آیتم های سفارش انتخاب شده را بررسی کرد
        // await checkStockForSelectedOrder();
      }
    } catch (e) {
      _setError('بارگیری سفارش انتخاب شده با شکست مواجه شد: ${e.toString()}');
      _selectedSalesOrder = null;
    }
    _setLoading(false); // این متد notifyListeners() را در داخل خود فراخوانی می کند
  }

  // --- متدهای مربوط به پرداخت ها ---

  // افزودن یک پرداخت جدید برای سفارش فروش انتخاب شده فعلی
  Future<bool> addPayment(Payment payment) async {
    // بررسی اینکه آیا سفارشی انتخاب شده و شناسه سفارش پرداخت با سفارش انتخاب شده مطابقت دارد
    if (_selectedSalesOrder == null || payment.orderId != _selectedSalesOrder!.id) {
      _setError("هیچ سفارشی انتخاب نشده یا شناسه سفارش پرداخت مطابقت ندارد.");
      return false;
    }
    _setLoading(true); _setError(null);
    try {
      await _dbService.insertPayment(payment); // درج پرداخت در پایگاه داده
      // واکشی مجدد اطلاعات سفارش انتخاب شده برای به روزرسانی لیست پرداخت های آن
      _selectedSalesOrder = await _dbService.getSalesOrderById(_selectedSalesOrder!.id!);
      // همچنین، سفارش را در لیست کلی سفارشات نیز به روز کن
      // این کار باعث می شود اگر UI اطلاعاتی مانند مبلغ پرداخت شده را مستقیما از لیست کلی نمایش می دهد، به روز شود
      if (_selectedSalesOrder != null) {
        int index = _salesOrders.indexWhere((o) => o.id == _selectedSalesOrder!.id);
        if(index != -1) _salesOrders[index] = _selectedSalesOrder!;
      }
      _setLoading(false); return true; // عملیات موفقیت آمیز بود
    } catch (e) {
      _setError('افزودن پرداخت با شکست مواجه شد: ${e.toString()}');
      _setLoading(false); return false; // عملیات ناموفق بود
    }
  }

  // حذف یک پرداخت بر اساس شناسه آن
  Future<bool> deletePayment(int paymentId) async {
     if (_selectedSalesOrder == null ) { // بررسی اینکه آیا سفارشی انتخاب شده است
      _setError("هیچ سفارشی انتخاب نشده است.");
      return false;
    }
    _setLoading(true); _setError(null);
    try {
      await _dbService.deletePayment(paymentId); // حذف پرداخت از پایگاه داده
      // واکشی مجدد اطلاعات سفارش انتخاب شده برای به روزرسانی لیست پرداخت های آن
      _selectedSalesOrder = await _dbService.getSalesOrderById(_selectedSalesOrder!.id!);
      // به روزرسانی سفارش در لیست کلی
      if (_selectedSalesOrder != null) {
        int index = _salesOrders.indexWhere((o) => o.id == _selectedSalesOrder!.id);
        if(index != -1) _salesOrders[index] = _selectedSalesOrder!;
      }
      _setLoading(false); return true;
    } catch (e) {
      _setError('حذف پرداخت با شکست مواجه شد: ${e.toString()}');
      _setLoading(false); return false;
    }
  }

  // --- متدهای مربوط به تکمیل سفارش و موجودی انبار ---

  // تکمیل سفارش فروش انتخاب شده و به روزرسانی موجودی انبار
  // orderId: شناسه سفارشی که باید تکمیل شود
  // calledFromStatusUpdate: یک فلگ داخلی برای جلوگیری از فراخوانی های تودرتو یا خطای "already completed" وقتی از متد updateSalesOrderStatus فراخوانی می شود
  Future<bool> completeSelectedSalesOrder(int orderId, {bool calledFromStatusUpdate = false}) async {
    SalesOrder? orderToComplete = _selectedSalesOrder;
    // اگر سفارش انتخاب شده فعلی با orderId مطابقت ندارد یا null است، آن را از پایگاه داده واکشی کن
    if (orderToComplete == null || orderToComplete.id != orderId) {
        orderToComplete = await _dbService.getSalesOrderById(orderId);
    }

    if (orderToComplete == null) {
      _setError('سفارش برای تکمیل یافت نشد.'); return false;
    }
    // اگر متد از طریق updateSalesOrderStatus فراخوانی شده و وضعیت از قبل تکمیل شده، عملیات موفقیت آمیز تلقی می شود
    if (orderToComplete.status == 'Completed' && calledFromStatusUpdate) {
        _setLoading(false); // اطمینان از اینکه وضعیت بارگذاری false است
        return true;
    }
    // اگر مستقیما فراخوانی شده و از قبل تکمیل شده، خطا بده
     if (orderToComplete.status == 'Completed' && !calledFromStatusUpdate) {
      _setError('این سفارش قبلا تکمیل شده است.');
      return false;
    }

    _setLoading(true); _setError(null);
    try {
      // فراخوانی متد سرویس پایگاه داده که وضعیت سفارش را تغییر داده و موجودی را به روز می کند
      await _dbService.completeSalesOrderAndUpdateInventory(orderId);
      // واکشی مجدد اطلاعات سفارش انتخاب شده و به روزرسانی لیست کلی سفارشات
      _selectedSalesOrder = await _dbService.getSalesOrderById(orderId);
      if (_selectedSalesOrder != null) {
        int index = _salesOrders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _salesOrders[index] = _selectedSalesOrder!;
        }
      } else {
         // اگر سفارش به روز شده به دلایلی null بازگشت (مثلا همزمان حذف شده)، کل لیست را رفرش کن
         await fetchSalesOrders();
      }
      _inventorySyncNotifier.notifyInventoryChanged(); // اطلاع رسانی به InventoryController برای به روزرسانی نماهای موجودی
      _setLoading(false); return true; // عملیات موفقیت آمیز بود
    } catch (e) {
      _setError('تکمیل سفارش فروش با شکست مواجه شد: ${e.toString()}');
      _setLoading(false); return false; // عملیات ناموفق بود
    }
  }

  // --- بررسی موجودی برای سفارش ---

  // بررسی موجودی انبار برای تمامی آیتم های سفارش انتخاب شده فعلی
  // نتایج کمبود در _itemShortages ذخیره می شود
  Future<void> checkStockForSelectedOrder() async {
    if (_selectedSalesOrder == null) { // اگر سفارشی انتخاب نشده است
      _itemShortages = {}; // لیست کمبودها را خالی کن
      notifyListeners();
      return;
    }
    _isCheckingStock = true; // شروع وضعیت بررسی موجودی
    _itemShortages = {}; // پاک کردن کمبودهای قبلی
    notifyListeners(); // اطلاع به UI برای نمایش نشانگر بارگذاری یا وضعیت بررسی

    try {
      for (var orderItem in _selectedSalesOrder!.items) { // برای هر آیتم در سفارش انتخاب شده
        final product = await _dbService.getProductById(orderItem.productId); // دریافت اطلاعات محصول آیتم
        if (product == null) continue; // اگر محصول پیدا نشد، برو به آیتم بعدی

        final productParts = await _dbService.getPartsForProduct(product.id!); // دریافت قطعات تشکیل دهنده محصول
        if (productParts.isEmpty) { // اگر محصول قطعه تشکیل دهنده ندارد (یعنی خودش یک آیتم موجودی مستقیم است)
            final inventoryItem = await _dbService.getInventoryItemByName(product.name); // موجودی خود محصول را بگیر
            final currentStock = inventoryItem?.quantity ?? 0; // اگر موجودی نداشت، صفر در نظر بگیر
            final requiredForThisOrderItem = orderItem.quantity; // مقدار مورد نیاز برای این آیتم سفارش
             if (currentStock < requiredForThisOrderItem) { // اگر موجودی کمتر از نیاز است
                // مقدار کمبود را به لیست کمبودها اضافه کن
                _itemShortages[product.name] = (_itemShortages[product.name] ?? 0) + (requiredForThisOrderItem - currentStock);
            }
        } else { // اگر محصول یک مجموعه مونتاژی است و از قطعات دیگر تشکیل شده
            for (var productPartLink in productParts) { // برای هر قطعه تشکیل دهنده محصول
              final part = await _dbService.getPartById(productPartLink.partId); // اطلاعات قطعه جزء را بگیر
              if (part == null) continue; // اگر قطعه جزء پیدا نشد، برو بعدی

              final inventoryItem = await _dbService.getInventoryItemByName(part.name); // موجودی قطعه جزء را بگیر
              final currentStock = inventoryItem?.quantity ?? 0;
              // مقدار مورد نیاز از این قطعه خاص برای یک واحد محصول، ضربدر تعداد محصول سفارش داده شده
              final requiredForThisOrderItem = productPartLink.quantity * orderItem.quantity;

              if (currentStock < requiredForThisOrderItem) { // اگر موجودی قطعه جزء کمتر از نیاز است
                _itemShortages[part.name] = (_itemShortages[part.name] ?? 0) + (requiredForThisOrderItem - currentStock);
              }
            }
        }
      }
    } catch (e) {
      // تنظیم یک خطای عمومی یا خطای مخصوص بررسی موجودی
      _setError("خطا در بررسی موجودی: ${e.toString()}");
    }
    _isCheckingStock = false; // پایان وضعیت بررسی موجودی
    notifyListeners(); // اطلاع به UI برای نمایش نتایج کمبود یا پنهان کردن نشانگر بارگذاری
  }
} // انتهای کلاس OrderController
