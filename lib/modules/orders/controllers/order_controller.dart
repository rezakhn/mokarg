import 'package:flutter/foundation.dart'; // برای استفاده از ChangeNotifier
import '../../../core/database_service.dart'; // سرویس پایگاه داده
import '../models/customer.dart'; // مدل مشتری
import '../models/sales_order.dart'; // مدل سفارش فروش
import '../models/order_item.dart'; // مدل آیتم سفارش
import '../models/payment.dart'; // مدل پرداخت
import '../../parts/models/product.dart'; // برای واکشی لیست محصولات جهت استفاده در سفارشات
import '../../parts/models/part.dart';    // برای بررسی جزئیات قطعات تشکیل دهنده (در بررسی موجودی)
import '../../inventory/models/inventory_item.dart'; // برای بررسی موجودی انبار

// کنترلر برای مدیریت داده ها و منطق مربوط به مشتریان، سفارشات فروش و پرداخت ها
class OrderController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService(); // نمونه ای از سرویس پایگاه داده

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
  OrderController() {
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
  // ... (بقیه متدها در مراحل بعدی کامنت گذاری خواهند شد) ...
  // --- Payment Methods ---
  Future<bool> addPayment(Payment payment) async {
    if (_selectedSalesOrder == null || payment.orderId != _selectedSalesOrder!.id) {
      _setError("No order selected or payment order ID mismatch.");
      return false;
    }
    _setLoading(true); _setError(null);
    try {
      await _dbService.insertPayment(payment);
      // Refresh selected order to include new payment
      _selectedSalesOrder = await _dbService.getSalesOrderById(_selectedSalesOrder!.id!);
      // Also update the order in the main list
      int index = _salesOrders.indexWhere((o) => o.id == _selectedSalesOrder!.id);
      if(index != -1) _salesOrders[index] = _selectedSalesOrder!;

      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to add payment: ${e.toString()}'); _setLoading(false); return false;
    }
  }

  Future<bool> deletePayment(int paymentId) async {
     if (_selectedSalesOrder == null ) {
      _setError("No order selected.");
      return false;
    }
    _setLoading(true); _setError(null);
    try {
      await _dbService.deletePayment(paymentId);
      _selectedSalesOrder = await _dbService.getSalesOrderById(_selectedSalesOrder!.id!);
      int index = _salesOrders.indexWhere((o) => o.id == _selectedSalesOrder!.id);
      if(index != -1) _salesOrders[index] = _selectedSalesOrder!;
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to delete payment: ${e.toString()}'); _setLoading(false); return false;
    }
  }


  // --- Order Completion & Inventory ---
  Future<bool> completeSelectedSalesOrder(int orderId, bool calledFromStatusUpdate) async {
    SalesOrder? orderToComplete = _selectedSalesOrder;
    if (orderToComplete == null || orderToComplete.id != orderId) {
        orderToComplete = await _dbService.getSalesOrderById(orderId);
    }

    if (orderToComplete == null) {
      _setError('Order not found for completion.'); return false;
    }
    if (orderToComplete.status == 'Completed' && calledFromStatusUpdate) { // Already handled by status update
        _setLoading(false); // Ensure loading is false if we short-circuit
        return true;
    }
     if (orderToComplete.status == 'Completed' && !calledFromStatusUpdate) {
      _setError('Order is already completed.');
      return false;
    }


    _setLoading(true); _setError(null);
    try {
      await _dbService.completeSalesOrderAndUpdateInventory(orderId);
      // Refresh selected order and list
      _selectedSalesOrder = await _dbService.getSalesOrderById(orderId);
      int index = _salesOrders.indexWhere((o) => o.id == orderId);
      if (index != -1 && _selectedSalesOrder != null) {
        _salesOrders[index] = _selectedSalesOrder!;
      } else if (_selectedSalesOrder == null) { // If it became null for some reason
        await fetchSalesOrders(); // Full refresh
      }
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to complete sales order: ${e.toString()}'); _setLoading(false); return false;
    }
  }

  // --- Stock Check for Order ---
  Future<void> checkStockForSelectedOrder() async {
    if (_selectedSalesOrder == null) {
      _itemShortages = {};
      notifyListeners();
      return;
    }
    _isCheckingStock = true;
    _itemShortages = {};
    notifyListeners();

    try {
      for (var orderItem in _selectedSalesOrder!.items) {
        final product = await _dbService.getProductById(orderItem.productId);
        if (product == null) continue;

        final productParts = await _dbService.getPartsForProduct(product.id!);
        if (productParts.isEmpty) { // Product is directly inventoried
            final inventoryItem = await _dbService.getInventoryItemByName(product.name);
            final currentStock = inventoryItem?.quantity ?? 0;
            final requiredForThisOrderItem = orderItem.quantity;
             if (currentStock < requiredForThisOrderItem) {
                _itemShortages[product.name] = (_itemShortages[product.name] ?? 0) + (requiredForThisOrderItem - currentStock);
            }
        } else { // Product is an assembly, check components
            for (var productPartLink in productParts) {
              final part = await _dbService.getPartById(productPartLink.partId);
              if (part == null) continue;

              final inventoryItem = await _dbService.getInventoryItemByName(part.name);
              final currentStock = inventoryItem?.quantity ?? 0;
              // Required quantity of this specific part for one unit of the product, times how many products are ordered
              final requiredForThisOrderItem = productPartLink.quantity * orderItem.quantity;

              if (currentStock < requiredForThisOrderItem) {
                _itemShortages[part.name] = (_itemShortages[part.name] ?? 0) + (requiredForThisOrderItem - currentStock);
              }
            }
        }
      }
    } catch (e) {
      // Set a general error or specific stock check error
      _setError("Error checking stock: ${e.toString()}");
    }
    _isCheckingStock = false;
    notifyListeners();
  }
}
