import 'package:flutter/foundation.dart'; // برای استفاده از ChangeNotifier
import '../../../core/database_service.dart'; // سرویس پایگاه داده
import '../models/part.dart'; // مدل قطعه
import '../models/part_composition.dart'; // مدل ترکیب قطعه
import '../models/product.dart'; // مدل محصول
import '../models/product_part.dart'; // مدل قطعه محصول
import '../models/assembly_order.dart'; // مدل سفارش مونتاژ
import '../../inventory/models/inventory_item.dart'; // برای بررسی موجودی انبار
import '../../../core/notifiers/inventory_sync_notifier.dart'; // Import InventorySyncNotifier

// کنترلر برای مدیریت داده ها و منطق مربوط به قطعات، محصولات و سفارشات مونتاژ
class PartController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService(); // نمونه ای از سرویس پایگاه داده
  final InventorySyncNotifier _inventorySyncNotifier; // Add InventorySyncNotifier field

  // --- State مربوط به قطعات ---
  List<Part> _parts = []; // لیست خصوصی همه قطعات
  List<Part> get parts => _parts; // گتر عمومی برای همه قطعات

  List<Part> _rawMaterials = []; // لیست فیلتر شده برای مواد خام/اجزاء اولیه
  List<Part> get rawMaterials => _rawMaterials; // گتر عمومی برای مواد خام

  List<Part> _assemblies = []; // لیست فیلتر شده برای مجموعه های مونتاژی
  List<Part> get assemblies => _assemblies; // گتر عمومی برای مجموعه های مونتاژی

  Part? _selectedPart; // قطعه انتخاب شده فعلی
  Part? get selectedPart => _selectedPart; // گتر عمومی برای قطعه انتخاب شده

  List<PartComposition> _selectedPartComposition = []; // لیست اجزای تشکیل دهنده قطعه مونتاژی انتخاب شده
  List<PartComposition> get selectedPartComposition => _selectedPartComposition; // گتر عمومی

  // نقشه برای نگهداری نام قطعات بر اساس شناسه آنها (برای نمایش نام اجزاء در لیست ترکیب)
  Map<int, String> _partIdToNameMap = {};
  Map<int, String> get partIdToNameMap => _partIdToNameMap;


  // --- State مربوط به محصولات ---
  List<Product> _products = []; // لیست خصوصی محصولات
  List<Product> get products => _products; // گتر عمومی برای محصولات

  Product? _selectedProduct; // محصول انتخاب شده فعلی
  Product? get selectedProduct => _selectedProduct; // گتر عمومی برای محصول انتخاب شده

  List<ProductPart> _selectedProductParts = []; // لیست قطعات تشکیل دهنده محصول انتخاب شده
  List<ProductPart> get selectedProductParts => _selectedProductParts; // گتر عمومی


  // --- State مربوط به سفارشات مونتاژ ---
  List<AssemblyOrder> _assemblyOrders = []; // لیست خصوصی سفارشات مونتاژ
  List<AssemblyOrder> get assemblyOrders => _assemblyOrders; // گتر عمومی برای سفارشات مونتاژ

  AssemblyOrder? _selectedAssemblyOrder; // سفارش مونتاژ انتخاب شده فعلی
  AssemblyOrder? get selectedAssemblyOrder => _selectedAssemblyOrder; // گتر عمومی

  // لیست برای نگهداری موجودی انبار اجزای مورد نیاز برای یک سفارش مونتاژ انتخاب شده
  List<InventoryItem> _requiredComponentsStock = [];
  List<InventoryItem> get requiredComponentsStock => _requiredComponentsStock;


  // --- State مشترک ---
  bool _isLoading = false; // وضعیت بارگذاری اطلاعات
  bool get isLoading => _isLoading; // گتر عمومی برای وضعیت بارگذاری

  String? _errorMessage; // پیام خطا در صورت بروز مشکل
  String? get errorMessage => _errorMessage; // گتر عمومی برای پیام خطا

  // سازنده کنترلر
  PartController(this._inventorySyncNotifier) { // Modify constructor
    // واکشی داده های اولیه می تواند اینجا انجام شود یا توسط UI فراخوانی شود
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

  // متد خصوصی برای به روزرسانی نقشه نام قطعات بر اساس شناسه
  // این نقشه برای نمایش نام قطعات در لیست های ترکیب استفاده می شود
  Future<void> _updatePartIdToNameMap(List<Part> partsList) async {
    _partIdToNameMap = {for (var p in partsList) p.id!: p.name};
    // notifyListeners(); // معمولا نیازی به این نیست چون این متد داخلی است و در ادامه fetchParts فراخوانی می شود
  }

  // --- متدهای مربوط به قطعات ---

  // واکشی لیست همه قطعات از پایگاه داده
  // قابلیت جستجو بر اساس نام قطعه (query)
  // همچنین لیست های مواد خام (_rawMaterials) و مجموعه های مونتاژی (_assemblies) را به روز می کند
  // و نقشه _partIdToNameMap را نیز برای استفاده های بعدی به روز می کند
  Future<void> fetchParts({String? query}) async {
    _setLoading(true);
    _setError(null);
    try {
      _parts = await _dbService.getParts(query: query); // دریافت همه قطعات
      _rawMaterials = _parts.where((p) => !p.isAssembly).toList(); // فیلتر مواد خام
      _assemblies = _parts.where((p) => p.isAssembly).toList(); // فیلتر مجموعه های مونتاژی
      await _updatePartIdToNameMap(_parts); // به روزرسانی نقشه شناسه به نام
    } catch (e) {
      _setError('بارگیری لیست قطعات با شکست مواجه شد: ${e.toString()}');
      _parts = []; _rawMaterials = []; _assemblies = []; // خالی کردن لیست ها در صورت خطا
    }
    _setLoading(false);
  }

  // دریافت یک قطعه خاص بر اساس شناسه آن
  // این متد بیشتر برای استفاده داخلی است یا در صورتی که نیاز به واکشی مستقیم باشد
  Future<Part?> getPartById(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      final part = await _dbService.getPartById(id);
      _setLoading(false);
      return part;
    } catch (e) {
      _setError('دریافت اطلاعات قطعه با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  // افزودن یک قطعه جدید
  Future<bool> addPart(Part part) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertPart(part); // درج قطعه در پایگاه داده
      await fetchParts(); // واکشی مجدد لیست قطعات برای به روزرسانی
      _setLoading(false);
      return true; // عملیات موفقیت آمیز بود
    } catch (e) {
      // معمولا به دلیل تکراری بودن نام قطعه رخ می دهد (unique constraint)
      _setError('افزودن قطعه با شکست مواجه شد (ممکن است نام تکراری باشد): ${e.toString()}');
      _setLoading(false);
      return false; // عملیات ناموفق بود
    }
  }

  // به روزرسانی اطلاعات یک قطعه موجود
  // اگر قطعه مونتاژی باشد و لیست اجزاء (componentsToSet) نیز ارائه شده باشد، اجزاء آن نیز به روز می شوند
  Future<bool> updatePart(Part part, {List<PartComposition>? componentsToSet}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updatePart(part); // به روزرسانی قطعه اصلی
      // اگر قطعه مونتاژی است و لیست اجزاء جدید مشخص شده، آنها را تنظیم کن
      if (part.isAssembly && componentsToSet != null) {
        await _dbService.setAssemblyComponents(part.id!, componentsToSet);
      }
      await fetchParts(); // واکشی مجدد لیست قطعات
      // اگر قطعه به روز شده همان قطعه انتخاب شده فعلی است، آن را مجددا انتخاب کن تا اجزایش نیز به روز شوند
      if (_selectedPart?.id == part.id) {
        await selectPart(part.id!);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('به روزرسانی قطعه با شکست مواجه شد (ممکن است نام تکراری باشد): ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // حذف یک قطعه بر اساس شناسه
  Future<bool> deletePart(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deletePart(id); // حذف قطعه از پایگاه داده
      await fetchParts(); // واکشی مجدد لیست قطعات
      // اگر قطعه حذف شده، قطعه انتخاب شده فعلی بود، آن را از انتخاب خارج کن
      if (_selectedPart?.id == id) {
        _selectedPart = null;
        _selectedPartComposition = []; // لیست اجزاء آن را نیز خالی کن
      }
      _setLoading(false);
      return true;
    } catch (e) {
      // معمولا به این دلیل است که قطعه در جای دیگری استفاده شده (مثلا در ترکیب محصول یا سفارش مونتاژ)
      _setError('حذف قطعه با شکست مواجه شد (ممکن است در حال استفاده باشد): ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // انتخاب یک قطعه و در صورت مونتاژی بودن، واکشی اجزای تشکیل دهنده آن
  Future<void> selectPart(int partId) async {
    // یافتن قطعه از لیست موجود یا null در صورت عدم وجود
    _selectedPart = _parts.firstWhere((p) => p.id == partId, orElse: () => null as Part?);
    if (_selectedPart != null && _selectedPart!.isAssembly) {
      // اگر قطعه انتخاب شده مونتاژی است، اجزای آن را واکشی کن
      await fetchComponentsForSelectedAssembly();
    } else {
      // در غیر این صورت (قطعه خام یا null)، لیست اجزاء را خالی کن
      _selectedPartComposition = [];
    }
    notifyListeners(); // اطلاع رسانی برای به روزرسانی UI
  }

  // واکشی اجزای تشکیل دهنده برای قطعه مونتاژی انتخاب شده فعلی (_selectedPart)
  Future<void> fetchComponentsForSelectedAssembly() async {
    if (_selectedPart == null || !_selectedPart!.isAssembly) {
      _selectedPartComposition = []; // اگر قطعه ای انتخاب نشده یا مونتاژی نیست، لیست اجزاء خالی است
      notifyListeners();
      return;
    }
    _setLoading(true);
    _setError(null);
    try {
      _selectedPartComposition = await _dbService.getComponentsForAssembly(_selectedPart!.id!);
    } catch (e) {
      _setError('بارگیری اجزای تشکیل دهنده با شکست مواجه شد: ${e.toString()}');
      _selectedPartComposition = []; // خالی کردن لیست در صورت خطا
    }
    _setLoading(false); // با notifyListeners در داخل _setLoading
  }

  // تنظیم (بازنویسی) اجزای تشکیل دهنده برای قطعه مونتاژی انتخاب شده فعلی
  Future<bool> setComponentsForSelectedAssembly(List<PartComposition> components) async {
    if (_selectedPart == null || !_selectedPart!.isAssembly) {
      _setError("هیچ مجموعه مونتاژی انتخاب نشده یا قطعه انتخاب شده مونتاژی نیست.");
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.setAssemblyComponents(_selectedPart!.id!, components); // تنظیم اجزاء در پایگاه داده
      await fetchComponentsForSelectedAssembly(); // واکشی مجدد برای به روزرسانی لیست محلی
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('تنظیم اجزای تشکیل دهنده با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // --- متدهای مربوط به محصولات ---

  // واکشی لیست همه محصولات از پایگاه داده
  // قابلیت جستجو بر اساس نام محصول (query)
  Future<void> fetchProducts({String? query}) async {
    _setLoading(true);
    _setError(null);
    try {
      _products = await _dbService.getProducts(query: query); // دریافت محصولات از سرویس پایگاه داده
    } catch (e) {
      _setError('بارگیری لیست محصولات با شکست مواجه شد: ${e.toString()}');
      _products = []; // خالی کردن لیست در صورت خطا
    }
    _setLoading(false);
  }

  // افزودن یک محصول جدید
  Future<bool> addProduct(Product product) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertProduct(product); // درج محصول در پایگاه داده
      await fetchProducts(); // واکشی مجدد لیست محصولات برای به روزرسانی
      _setLoading(false);
      return true; // عملیات موفقیت آمیز بود
    } catch (e) {
      // معمولا به دلیل تکراری بودن نام محصول رخ می دهد
      _setError('افزودن محصول با شکست مواجه شد (ممکن است نام تکراری باشد): ${e.toString()}');
      _setLoading(false);
      return false; // عملیات ناموفق بود
    }
  }

  // به روزرسانی اطلاعات یک محصول موجود
  // اگر لیست قطعات (partsToSet) نیز ارائه شده باشد، قطعات تشکیل دهنده محصول نیز به روز می شوند
  Future<bool> updateProduct(Product product, {List<ProductPart>? partsToSet}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateProduct(product); // به روزرسانی محصول اصلی
      // اگر لیست قطعات جدید مشخص شده، آنها را تنظیم کن
      if (partsToSet != null) {
        await _dbService.setProductParts(product.id!, partsToSet);
      }
      await fetchProducts(); // واکشی مجدد لیست محصولات
      // اگر محصول به روز شده همان محصول انتخاب شده فعلی است، آن را مجددا انتخاب کن تا قطعاتش نیز به روز شوند
      if (_selectedProduct?.id == product.id) {
        await selectProduct(product.id!);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('به روزرسانی محصول با شکست مواجه شد (ممکن است نام تکراری باشد): ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // حذف یک محصول بر اساس شناسه
  Future<bool> deleteProduct(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteProduct(id); // حذف محصول از پایگاه داده
      await fetchProducts(); // واکشی مجدد لیست محصولات
      // اگر محصول حذف شده، محصول انتخاب شده فعلی بود، آن را از انتخاب خارج کن
      if (_selectedProduct?.id == id) {
        _selectedProduct = null;
        _selectedProductParts = []; // لیست قطعات آن را نیز خالی کن
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('حذف محصول با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // انتخاب یک محصول و واکشی قطعات تشکیل دهنده آن
  Future<void> selectProduct(int productId) async {
    _selectedProduct = _products.firstWhere((p) => p.id == productId, orElse: () => null as Product?);
    if (_selectedProduct != null) {
      // اگر محصولی انتخاب شده، قطعات تشکیل دهنده آن را واکشی کن
      await fetchPartsForSelectedProduct();
    } else {
      _selectedProductParts = []; // در غیر این صورت، لیست قطعات را خالی کن
    }
    notifyListeners(); // اطلاع رسانی برای به روزرسانی UI
  }

  // واکشی قطعات تشکیل دهنده برای محصول انتخاب شده فعلی (_selectedProduct)
  Future<void> fetchPartsForSelectedProduct() async {
    if (_selectedProduct == null) {
      _selectedProductParts = []; // اگر محصولی انتخاب نشده، لیست قطعات خالی است
      notifyListeners();
      return;
    }
    _setLoading(true);
    _setError(null);
    try {
      _selectedProductParts = await _dbService.getPartsForProduct(_selectedProduct!.id!);
    } catch (e) {
      _setError('بارگیری قطعات محصول با شکست مواجه شد: ${e.toString()}');
      _selectedProductParts = []; // خالی کردن لیست در صورت خطا
    }
    _setLoading(false); // با notifyListeners در داخل _setLoading
  }

  // تنظیم (بازنویسی) قطعات تشکیل دهنده برای محصول انتخاب شده فعلی
  Future<bool> setPartsForSelectedProduct(List<ProductPart> productParts) async {
    if (_selectedProduct == null) {
      _setError("هیچ محصولی انتخاب نشده است.");
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.setProductParts(_selectedProduct!.id!, productParts); // تنظیم قطعات در پایگاه داده
      await fetchPartsForSelectedProduct(); // واکشی مجدد برای به روزرسانی لیست محلی
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('تنظیم قطعات محصول با شکست مواجه شد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  // ... (بقیه متدها در مراحل بعدی کامنت گذاری خواهند شد) ...
  // --- Assembly Order Methods ---
  Future<void> fetchAssemblyOrders({String? status}) async {
    _setLoading(true);
    _setError(null);
    try {
      _assemblyOrders = await _dbService.getAssemblyOrders(status: status);
       // Fetch all parts to ensure partIdToNameMap is populated for displaying assembly names
      if (_parts.isEmpty) await fetchParts();
    } catch (e) {
      _setError('Failed to load assembly orders: ${e.toString()}');
      _assemblyOrders = [];
    }
    _setLoading(false);
  }

  Future<AssemblyOrder?> getAssemblyOrderById(int id) async {
     _setLoading(true);
    _setError(null);
    try {
      final order = await _dbService.getAssemblyOrderById(id);
      _setLoading(false);
      return order;
    } catch (e) {
      _setError('Failed to get assembly order: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> addAssemblyOrder(AssemblyOrder order) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertAssemblyOrder(order);
      await fetchAssemblyOrders(); // Refresh
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add assembly order: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteAssemblyOrder(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteAssemblyOrder(id);
      await fetchAssemblyOrders(); // Refresh
      if (_selectedAssemblyOrder?.id == id) _selectedAssemblyOrder = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete assembly order: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> selectAssemblyOrder(int orderId) async {
    _selectedAssemblyOrder = _assemblyOrders.firstWhere((o) => o.id == orderId, orElse: () => null as AssemblyOrder?);
    if (_selectedAssemblyOrder != null) {
        await fetchRequiredComponentsForSelectedOrder();
    } else {
        _requiredComponentsStock = [];
    }
    notifyListeners();
  }

  Future<void> fetchRequiredComponentsForSelectedOrder() async {
    if (_selectedAssemblyOrder == null) {
        _requiredComponentsStock = [];
        notifyListeners();
        return;
    }
    _setLoading(true);
    _setError(null);
    try {
        final List<PartComposition> components = await _dbService.getComponentsForAssembly(_selectedAssemblyOrder!.partId);
        List<InventoryItem> stock = [];
        for (var comp in components) {
            final partDetails = await _dbService.getPartById(comp.componentPartId);
            if (partDetails != null) {
                final inventoryItem = await _dbService.getInventoryItemByName(partDetails.name);
                stock.add(inventoryItem ?? InventoryItem(itemName: partDetails.name, quantity: 0, threshold: 0));
            }
        }
        _requiredComponentsStock = stock;
    } catch (e) {
        _setError('Failed to load component stock: ${e.toString()}');
        _requiredComponentsStock = [];
    }
    _setLoading(false);
  }


  Future<bool> completeSelectedAssemblyOrder() async {
    if (_selectedAssemblyOrder == null) {
      _setError('No assembly order selected.');
      return false;
    }
    if (_selectedAssemblyOrder!.status == 'Completed') {
      _setError('Order is already completed.');
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.completeAssemblyOrder(_selectedAssemblyOrder!.id!);
      // Refresh the specific order and the list
      final updatedOrder = await _dbService.getAssemblyOrderById(_selectedAssemblyOrder!.id!);
      if (updatedOrder != null) {
        int index = _assemblyOrders.indexWhere((o) => o.id == updatedOrder.id);
        if (index != -1) _assemblyOrders[index] = updatedOrder;
        _selectedAssemblyOrder = updatedOrder;
      } else {
         await fetchAssemblyOrders(); // Full refresh if single fetch fails
      }
      _inventorySyncNotifier.notifyInventoryChanged(); // Notify inventory change
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to complete assembly order: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}
