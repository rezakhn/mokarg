import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Alias to avoid conflict // استفاده از p برای جلوگیری از تداخل نام

// Models (ensure all model imports from previous steps are here) // مدل ها (اطمینان حاصل کنید که تمام ایمپورت های مدل اینجا هستند)
import '../modules/employees/models/employee.dart'; // مدل کارمند
import '../modules/purchases/models/supplier.dart'; // مدل تامین کننده
import '../modules/purchases/models/purchase_invoice.dart'; // مدل فاکتور خرید
import '../modules/inventory/models/inventory_item.dart'; // مدل آیتم موجودی
import '../modules/parts/models/part.dart'; // مدل قطعه
import '../modules/parts/models/part_composition.dart'; // مدل ترکیب قطعه
import '../modules/parts/models/product.dart'; // مدل محصول
import '../modules/parts/models/product_part.dart'; // مدل قطعه محصول
import '../modules/parts/models/assembly_order.dart'; // مدل سفارش مونتاژ
import '../modules/orders/models/customer.dart'; // مدل مشتری
import '../modules/orders/models/sales_order.dart'; // مدل سفارش فروش
import '../modules/orders/models/order_item.dart'; // مدل آیتم سفارش
import '../modules/orders/models/payment.dart'; // مدل پرداخت
import '../modules/backup/models/backup_info.dart'; // مدل اطلاعات پشتیبان (اضافه شده)

// کلاس سرویس پایگاه داده برای مدیریت تمام عملیات مربوط به پایگاه داده
class DatabaseService {
  static const String _dbName = "workshop_management.db"; // نام پایگاه داده
  Database? _database; // نمونه پایگاه داده

  // Getter برای دسترسی به پایگاه داده، در صورت عدم وجود آن را مقداردهی اولیه می کند
  Future<Database> get database async {
    if (_database != null) return _database!; // اگر نمونه وجود داشت، آن را برگردان
    _database = await _initDB(); // در غیر این صورت، پایگاه داده را مقداردهی اولیه کن
    return _database!;
  }

  // متد خصوصی برای مقداردهی اولیه پایگاه داده
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath(); // دریافت مسیر پایگاه داده ها
    final path = p.join(dbPath, _dbName); // ایجاد مسیر کامل برای پایگاه داده فعلی
    // باز کردن پایگاه داده
    return await openDatabase(
      path,
      version: 1, // نسخه پایگاه داده
      onCreate: _createDB, // تابعی که هنگام ایجاد پایگاه داده برای اولین بار فراخوانی می شود
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON'); // فعال سازی کلیدهای خارجی
      },
    );
  }

  // متد خصوصی برای ایجاد جداول پایگاه داده
  Future<void> _createDB(Database db, int version) async {
    // جدول کارمندان
    await db.execute("CREATE TABLE employees(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, pay_type TEXT NOT NULL CHECK(pay_type IN ('daily', 'hourly')), daily_rate REAL, hourly_rate REAL, overtime_rate REAL NOT NULL)");
    // جدول گزارش کار کارمندان
    await db.execute("CREATE TABLE work_logs(id INTEGER PRIMARY KEY AUTOINCREMENT, employee_id INTEGER NOT NULL, date TEXT NOT NULL, hours_worked REAL, worked_day INTEGER, overtime_hours REAL, FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE)");
    // جدول تامین کنندگان
    await db.execute("CREATE TABLE suppliers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, contact_info TEXT)");
    // جدول فاکتورهای خرید
    await db.execute("CREATE TABLE purchase_invoices(id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER NOT NULL, date TEXT NOT NULL, total_amount REAL NOT NULL, FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE RESTRICT)");
    // جدول آیتم های فاکتور خرید
    await db.execute("CREATE TABLE purchase_items(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_id INTEGER NOT NULL, item_name TEXT NOT NULL, quantity REAL NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (invoice_id) REFERENCES purchase_invoices (id) ON DELETE CASCADE)");
    // جدول موجودی کالا
    await db.execute("CREATE TABLE inventory(item_name TEXT PRIMARY KEY, quantity REAL NOT NULL DEFAULT 0, threshold REAL NOT NULL DEFAULT 0)");
    // جدول قطعات
    await db.execute("CREATE TABLE parts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, is_assembly INTEGER NOT NULL DEFAULT 0 CHECK(is_assembly IN (0,1)))"); // is_assembly: 1 برای مونتاژی, 0 برای غیر مونتاژی
    // جدول ترکیب قطعات (برای قطعات مونتاژی)
    await db.execute("CREATE TABLE part_compositions(id INTEGER PRIMARY KEY AUTOINCREMENT, assembly_id INTEGER NOT NULL, component_part_id INTEGER NOT NULL, quantity REAL NOT NULL, FOREIGN KEY (assembly_id) REFERENCES parts (id) ON DELETE CASCADE, FOREIGN KEY (component_part_id) REFERENCES parts (id) ON DELETE RESTRICT)");
    // جدول محصولات
    await db.execute("CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)");
    // جدول قطعات محصول (برای تعریف قطعات تشکیل دهنده یک محصول)
    await db.execute("CREATE TABLE product_parts(id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, part_id INTEGER NOT NULL, quantity REAL NOT NULL, FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE, FOREIGN KEY (part_id) REFERENCES parts (id) ON DELETE RESTRICT)");
    // جدول سفارشات مونتاژ
    await db.execute("CREATE TABLE assembly_orders(id INTEGER PRIMARY KEY AUTOINCREMENT, part_id INTEGER NOT NULL, quantity_to_produce REAL NOT NULL, date TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'Pending', FOREIGN KEY (part_id) REFERENCES parts (id) ON DELETE RESTRICT)");
    // جدول مشتریان
    await db.execute("CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, contact_info TEXT)");
    // جدول سفارشات فروش
    await db.execute("CREATE TABLE sales_orders(id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER NOT NULL, order_date TEXT NOT NULL, delivery_date TEXT, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'Pending', FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT)");
    // جدول آیتم های سفارش فروش
    await db.execute("CREATE TABLE order_items(id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity REAL NOT NULL, price_at_sale REAL NOT NULL, FOREIGN KEY (order_id) REFERENCES sales_orders (id) ON DELETE CASCADE, FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT)");
    // جدول پرداخت ها
    await db.execute("CREATE TABLE payments(id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, amount REAL NOT NULL, payment_date TEXT NOT NULL, payment_method TEXT, FOREIGN KEY (order_id) REFERENCES sales_orders (id) ON DELETE CASCADE)");
    // جدول اطلاعات پشتیبان گیری
    await db.execute('''
      CREATE TABLE backups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        backup_date TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER,
        status TEXT,
        notes TEXT
      )
    ''');
  }

  // --- Employee CRUD --- // عملیات CRUD مربوط به کارمندان

  // افزودن یک کارمند جدید به پایگاه داده
  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return await db.insert('employees', employee.toMap());
  }

  // دریافت لیست تمام کارمندان، با قابلیت جستجو بر اساس نام
  Future<List<Employee>> getEmployees({String? query}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.isNotEmpty) {
      // اگر عبارت جستجو وجود داشت، کارمندان مطابق با آن فیلتر می شوند
      maps = await db.query('employees', where: 'name LIKE ?', whereArgs: ['%$query%']);
    } else {
      // در غیر این صورت، تمام کارمندان بازیابی می شوند
      maps = await db.query('employees');
    }
    // تبدیل لیست نقشه ها به لیست اشیاء کارمند
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  // دریافت یک کارمند خاص بر اساس شناسه
  Future<Employee?> getEmployeeById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('employees', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Employee.fromMap(maps.first); // اگر کارمند پیدا شد، آن را برگردان
    }
    return null; // در غیر این صورت null برگردان
  }

  // به روزرسانی اطلاعات یک کارمند موجود
  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update('employees', employee.toMap(), where: 'id = ?', whereArgs: [employee.id]);
  }

  // حذف یک کارمند بر اساس شناسه، همچنین تمام گزارش های کار مربوط به او نیز حذف می شوند
  Future<int> deleteEmployee(int id) async {
    final db = await database;
    // ابتدا گزارش های کار مربوط به این کارمند حذف می شوند
    await db.delete('work_logs', where: 'employee_id = ?', whereArgs: [id]);
    // سپس خود کارمند حذف می شود
    return await db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  // --- WorkLog CRUD --- // عملیات CRUD مربوط به گزارش کار

  // افزودن یک گزارش کار جدید
  Future<int> insertWorkLog(WorkLog workLog) async {
    final db = await database;
    return await db.insert('work_logs', workLog.toMap());
  }

  // دریافت لیست گزارش های کار برای یک کارمند خاص، با قابلیت فیلتر بر اساس تاریخ شروع و پایان
  Future<List<WorkLog>> getWorkLogsForEmployee(int employeeId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String whereClause = 'employee_id = ?'; // شرط اصلی: شناسه کارمند
    List<dynamic> whereArgs = [employeeId];

    // اگر تاریخ شروع و پایان هر دو مشخص شده باشند
    if (startDate != null && endDate != null) {
      whereClause += ' AND date BETWEEN ? AND ?'; // اضافه کردن شرط بازه تاریخی
      whereArgs.add(startDate.toIso8601String().substring(0,10)); // فرمت YYYY-MM-DD
      whereArgs.add(endDate.toIso8601String().substring(0,10));
    } else if (startDate != null) { // اگر فقط تاریخ شروع مشخص شده باشد
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String().substring(0,10));
    } else if (endDate != null) { // اگر فقط تاریخ پایان مشخص شده باشد
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String().substring(0,10));
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'work_logs',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC' // مرتب سازی بر اساس تاریخ به صورت نزولی
    );
    // تبدیل لیست نقشه ها به لیست اشیاء گزارش کار
    return List.generate(maps.length, (i) => WorkLog.fromMap(maps[i]));
  }

  // دریافت یک گزارش کار خاص بر اساس شناسه
  Future<WorkLog?> getWorkLogById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('work_logs', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return WorkLog.fromMap(maps.first);
    }
    return null;
  }

  // به روزرسانی اطلاعات یک گزارش کار موجود
  Future<int> updateWorkLog(WorkLog workLog) async {
    final db = await database;
    return await db.update('work_logs', workLog.toMap(), where: 'id = ?', whereArgs: [workLog.id]);
  }

  // حذف یک گزارش کار بر اساس شناسه
  Future<int> deleteWorkLog(int id) async {
    final db = await database;
    return await db.delete('work_logs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Supplier CRUD --- // عملیات CRUD مربوط به تامین کنندگان

  // افزودن یک تامین کننده جدید
  // از ConflictAlgorithm.fail برای جلوگیری از افزودن تامین کننده با نام تکراری استفاده می شود
  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    try {
      return await db.insert('suppliers', supplier.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) {
      print('Error inserting supplier: $e'); // چاپ خطا در کنسول
      rethrow; // ارسال مجدد خطا برای مدیریت در لایه بالاتر
    }
  }

  // دریافت لیست تمام تامین کنندگان، با قابلیت جستجو بر اساس نام
  Future<List<Supplier>> getSuppliers({String? query}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.isNotEmpty) {
      maps = await db.query('suppliers', where: 'name LIKE ?', whereArgs: ['%$query%'], orderBy: 'name ASC');
    } else {
      maps = await db.query('suppliers', orderBy: 'name ASC'); // مرتب سازی بر اساس نام به صورت صعودی
    }
    return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
  }

  // دریافت یک تامین کننده خاص بر اساس شناسه
  Future<Supplier?> getSupplierById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Supplier.fromMap(maps.first);
    }
    return null;
  }

  // به روزرسانی اطلاعات یک تامین کننده موجود
  // از ConflictAlgorithm.fail برای جلوگیری از تغییر نام تامین کننده به نامی که قبلا وجود داشته است استفاده می شود
  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    try {
      return await db.update('suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id], conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) {
      print('Error updating supplier: $e');
      rethrow;
    }
  }

  // حذف یک تامین کننده بر اساس شناسه
  // اگر تامین کننده دارای فاکتورهای خرید مرتبط باشد، به دلیل محدودیت کلید خارجی (ON DELETE RESTRICT) حذف انجام نمی شود
  Future<int> deleteSupplier(int id) async {
    final db = await database;
    try {
      return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting supplier: $e'); // معمولا خطای محدودیت کلید خارجی
      rethrow;
    }
  }

  // --- Inventory CRUD --- // عملیات CRUD مربوط به موجودی کالا

  // دریافت یک آیتم موجودی بر اساس نام آن، می تواند در یک تراکنش (txn) نیز اجرا شود
  Future<InventoryItem?> getInventoryItemByName(String itemName, {DatabaseExecutor? txn}) async {
    final db = txn ?? await database; // اگر تراکنش وجود داشت از آن استفاده کن، در غیر این صورت از پایگاه داده اصلی
    List<Map<String, dynamic>> maps = await db.query('inventory', where: 'item_name = ?', whereArgs: [itemName]);
    if (maps.isNotEmpty) {
      return InventoryItem.fromMap(maps.first);
    }
    return null;
  }

  // دریافت لیست تمام آیتم های موجودی، با قابلیت جستجو بر اساس نام
  Future<List<InventoryItem>> getAllInventoryItems({String? query}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.isNotEmpty) {
      maps = await db.query('inventory', where: 'item_name LIKE ?', whereArgs: ['%$query%'], orderBy: 'item_name ASC');
    } else {
      maps = await db.query('inventory', orderBy: 'item_name ASC');
    }
    return List.generate(maps.length, (i) => InventoryItem.fromMap(maps[i]));
  }

  // به روزرسانی حد آستانه (نقطه سفارش) یک آیتم موجودی
  Future<int> updateInventoryItemThreshold(String itemName, double newThreshold) async {
    final db = await database;
    final item = await getInventoryItemByName(itemName); // ابتدا بررسی وجود آیتم
    if (item == null) {
      print("Item not found in inventory to update threshold: $itemName");
      return 0; // آیتم پیدا نشد
    }
    return await db.update('inventory', {'threshold': newThreshold}, where: 'item_name = ?', whereArgs: [itemName]);
  }

  // تنظیم دستی مقدار موجودی یک آیتم (مقدار مطلق جدید)
  // اگر آیتم وجود نداشته باشد، ایجاد می شود
  Future<void> manuallyAdjustInventoryItemQuantity(String itemName, double newAbsoluteQuantity, {double? newThreshold}) async {
    final db = await database;
    Map<String, dynamic> values = {'quantity': newAbsoluteQuantity};
    if (newThreshold != null) {
      values['threshold'] = newThreshold;
    }
    final item = await getInventoryItemByName(itemName);
    if (item != null) { // اگر آیتم وجود دارد، به روزرسانی کن
      await db.update('inventory', values, where: 'item_name = ?', whereArgs: [itemName]);
    } else { // اگر آیتم وجود ندارد، ایجاد کن
      values['item_name'] = itemName;
      values.putIfAbsent('threshold', () => 0.0); // مقدار پیش فرض برای حد آستانه اگر مشخص نشده باشد
      await db.insert('inventory', values);
    }
  }

  // متد داخلی برای به روزرسانی مقدار موجودی یک آیتم (افزایش یا کاهش)
  // این متد باید در یک تراکنش (txn) فراخوانی شود
  // اگر آیتم وجود نداشته باشد، ایجاد می شود
  Future<void> _updateInventoryItemQuantityInternal(String itemName, double quantityChange, {required DatabaseExecutor txn, double? threshold}) async {
    final currentItem = await getInventoryItemByName(itemName, txn: txn);
    if (currentItem != null) { // اگر آیتم وجود دارد
      final newQuantity = currentItem.quantity + quantityChange; // محاسبه مقدار جدید
      Map<String, dynamic> updateValues = {'quantity': newQuantity};
      if (threshold != null) updateValues['threshold'] = threshold;
      await txn.update('inventory', updateValues, where: 'item_name = ?', whereArgs: [itemName]);
    } else { // اگر آیتم وجود ندارد، با مقدار تغییر داده شده ایجاد کن
      await txn.insert('inventory', {'item_name': itemName, 'quantity': quantityChange, 'threshold': threshold ?? 0.0});
    }
  }

  // --- PurchaseInvoice CRUD --- // عملیات CRUD مربوط به فاکتور خرید

  // افزودن یک فاکتور خرید جدید به همراه آیتم های آن
  // این عملیات در یک تراکنش انجام می شود تا از صحت داده ها اطمینان حاصل شود
  // موجودی کالاها نیز بر اساس آیتم های فاکتور به روز می شود
  Future<int> insertPurchaseInvoice(PurchaseInvoice invoice) async {
    final db = await database;
    return await db.transaction((txn) async {
      invoice.calculateTotalAmount(); // محاسبه مبلغ کل فاکتور
      // افزودن فاکتور اصلی و دریافت شناسه آن
      // ConflictAlgorithm.replace ممکن است نیاز به بازبینی داشته باشد، معمولا برای insert باید fail باشد یا شناسه از قبل چک شود
      int invoiceId = await txn.insert('purchase_invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (var item in invoice.items) {
        var itemMap = item.toMap();
        itemMap['invoice_id'] = invoiceId; // تنظیم شناسه فاکتور برای هر آیتم
        await txn.insert('purchase_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);
        // به روزرسانی موجودی کالا برای هر آیتم خریداری شده
        await _updateInventoryItemQuantityInternal(item.itemName, item.quantity, txn: txn);
      }
      return invoiceId; // برگرداندن شناسه فاکتور ایجاد شده
    });
  }

  // متد داخلی برای دریافت آیتم های یک فاکتور خرید خاص
  Future<List<PurchaseItem>> _getPurchaseItemsForInvoice(int invoiceId, {DatabaseExecutor? txn}) async {
    final db = txn ?? await database;
    final List<Map<String, dynamic>> maps = await db.query('purchase_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
    return List.generate(maps.length, (i) => PurchaseItem.fromMap(maps[i]));
  }

  // دریافت لیست فاکتورهای خرید، با قابلیت فیلتر بر اساس تاریخ و تامین کننده
  Future<List<PurchaseInvoice>> getPurchaseInvoices({DateTime? startDate, DateTime? endDate, int? supplierId}) async {
    final db = await database;
    String whereFinalClause = ""; // شرط نهایی
    List<dynamic> whereArgsFinal = []; // آرگومان های شرط نهایی

    if (supplierId != null) {
      whereFinalClause += (whereFinalClause.isNotEmpty ? " AND " : "") + "supplier_id = ?";
      whereArgsFinal.add(supplierId);
    }
    if (startDate != null && endDate != null) {
      whereFinalClause += (whereFinalClause.isNotEmpty ? " AND " : "") + "date BETWEEN ? AND ?";
      whereArgsFinal.add(startDate.toIso8601String().substring(0,10));
      whereArgsFinal.add(endDate.toIso8601String().substring(0,10));
    } else if (startDate != null) {
      whereFinalClause += (whereFinalClause.isNotEmpty ? " AND " : "") + "date >= ?";
      whereArgsFinal.add(startDate.toIso8601String().substring(0,10));
    } else if (endDate != null) {
      whereFinalClause += (whereFinalClause.isNotEmpty ? " AND " : "") + "date <= ?";
      whereArgsFinal.add(endDate.toIso8601String().substring(0,10));
    }

    final List<Map<String, dynamic>> invoiceMaps = await db.query(
      'purchase_invoices',
      where: whereFinalClause.isNotEmpty ? whereFinalClause : null,
      whereArgs: whereArgsFinal.isNotEmpty ? whereArgsFinal : null,
      orderBy: 'date DESC' // مرتب سازی بر اساس تاریخ به صورت نزولی
    );

    List<PurchaseInvoice> invoices = [];
    for (var map in invoiceMaps) {
      // برای هر فاکتور، آیتم های مربوط به آن نیز بازیابی می شوند
      List<PurchaseItem> items = await _getPurchaseItemsForInvoice(map['id'] as int);
      invoices.add(PurchaseInvoice.fromMap(map, items));
    }
    return invoices;
  }

  // دریافت یک فاکتور خرید خاص بر اساس شناسه، به همراه آیتم های آن
  Future<PurchaseInvoice?> getPurchaseInvoiceById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('purchase_invoices', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      List<PurchaseItem> items = await _getPurchaseItemsForInvoice(id);
      return PurchaseInvoice.fromMap(maps.first, items);
    }
    return null;
  }

  // به روزرسانی یک فاکتور خرید موجود
  // این عملیات در یک تراکنش انجام می شود
  // ابتدا تاثیر آیتم های قدیمی بر موجودی کالا خنثی می شود، سپس آیتم های جدید اعمال می شوند
  Future<int> updatePurchaseInvoice(PurchaseInvoice invoice) async {
    final db = await database;
    return await db.transaction((txn) async {
      invoice.calculateTotalAmount(); // محاسبه مجدد مبلغ کل
      // دریافت آیتم های قدیمی فاکتور برای خنثی سازی تاثیر آنها بر موجودی
      List<PurchaseItem> oldItems = await _getPurchaseItemsForInvoice(invoice.id!, txn: txn);
      for (var oldItem in oldItems) {
        await _updateInventoryItemQuantityInternal(oldItem.itemName, -oldItem.quantity, txn: txn); // کاهش موجودی
      }

      // به روزرسانی فاکتور اصلی
      int count = await txn.update('purchase_invoices', invoice.toMap(), where: 'id = ?', whereArgs: [invoice.id], conflictAlgorithm: ConflictAlgorithm.replace);
      // حذف آیتم های قدیمی فاکتور
      await txn.delete('purchase_items', where: 'invoice_id = ?', whereArgs: [invoice.id]);
      // افزودن آیتم های جدید فاکتور و به روزرسانی موجودی
      for (var item in invoice.items) {
        var itemMap = item.toMap();
        itemMap['invoice_id'] = invoice.id;
        await txn.insert('purchase_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);
        await _updateInventoryItemQuantityInternal(item.itemName, item.quantity, txn: txn); // افزایش موجودی
      }
      return count; // تعداد رکوردهای به روز شده در جدول فاکتورهای اصلی (باید 1 باشد)
    });
  }

  // حذف یک فاکتور خرید بر اساس شناسه
  // این عملیات در یک تراکنش انجام می شود
  // تاثیر آیتم های فاکتور بر موجودی کالا نیز خنثی می شود
  Future<int> deletePurchaseInvoice(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      // دریافت آیتم های فاکتور برای خنثی سازی تاثیر آنها بر موجودی
      List<PurchaseItem> itemsToDelete = await _getPurchaseItemsForInvoice(id, txn: txn);
      for (var item in itemsToDelete) {
        await _updateInventoryItemQuantityInternal(item.itemName, -item.quantity, txn: txn); // کاهش موجودی
      }
      // حذف فاکتور (آیتم های آن به دلیل ON DELETE CASCADE خودکار حذف می شوند)
      return await txn.delete('purchase_invoices', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- Part CRUD --- // عملیات CRUD مربوط به قطعات

  // افزودن یک قطعه جدید
  // از ConflictAlgorithm.fail برای جلوگیری از افزودن قطعه با نام تکراری استفاده می شود
  Future<int> insertPart(Part part) async {
    final db = await database;
    try {
      return await db.insert('parts', part.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) {
      print('Error inserting part: $e');
      rethrow;
    }
  }

  // دریافت لیست قطعات، با قابلیت فیلتر بر اساس نام و اینکه آیا قطعه مونتاژی است یا خیر
  Future<List<Part>> getParts({String? query, bool? isAssembly}) async {
    final db = await database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClause = 'name LIKE ?';
      whereArgs.add('%$query%');
    }
    if (isAssembly != null) {
      whereClause = (whereClause == null ? '' : '$whereClause AND ') + 'is_assembly = ?';
      whereArgs.add(isAssembly ? 1 : 0); // 1 برای مونتاژی, 0 برای غیر مونتاژی
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'parts',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC' // مرتب سازی بر اساس نام
    );
    return List.generate(maps.length, (i) => Part.fromMap(maps[i]));
  }

  // دریافت یک قطعه خاص بر اساس شناسه، می تواند در یک تراکنش (txn) نیز اجرا شود
  Future<Part?> getPartById(int id, {DatabaseExecutor? txn}) async {
    final db = txn ?? await database;
    final List<Map<String, dynamic>> maps = await db.query('parts', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Part.fromMap(maps.first);
    }
    return null;
  }

  // به روزرسانی اطلاعات یک قطعه موجود
  // از ConflictAlgorithm.fail برای جلوگیری از تغییر نام قطعه به نامی که قبلا وجود داشته است استفاده می شود
  Future<int> updatePart(Part part) async {
    final db = await database;
    try {
      return await db.update('parts', part.toMap(), where: 'id = ?', whereArgs: [part.id], conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) {
      print('Error updating part: $e');
      rethrow;
    }
  }

  // حذف یک قطعه بر اساس شناسه
  // اگر قطعه در ترکیب قطعات دیگر یا در محصولات استفاده شده باشد، ممکن است با خطای محدودیت کلید خارجی مواجه شود
  Future<int> deletePart(int id) async {
    final db = await database;
    // توجه: حذف یک قطعه ممکن است نیاز به بررسی های اضافی داشته باشد (مثلا اگر در part_compositions یا product_parts استفاده شده باشد)
    // بسته به تنظیمات ON DELETE، ممکن است حذف مجاز نباشد یا رکوردهای وابسته نیز حذف شوند.
    return await db.delete('parts', where: 'id = ?', whereArgs: [id]);
  }

  // --- PartComposition (Assembly Components) CRUD --- // عملیات CRUD مربوط به اجزای تشکیل دهنده قطعات مونتاژی

  // دریافت لیست اجزای تشکیل دهنده یک قطعه مونتاژی (assembly)
  Future<List<PartComposition>> getComponentsForAssembly(int assemblyId, {DatabaseExecutor? txn}) async {
    final db = txn ?? await database;
    final List<Map<String, dynamic>> maps = await db.query('part_compositions', where: 'assembly_id = ?', whereArgs: [assemblyId]);
    return List.generate(maps.length, (i) => PartComposition.fromMap(maps[i]));
  }

  // افزودن یک جزء به یک قطعه مونتاژی
  Future<int> addComponentToAssembly(PartComposition composition) async {
    final db = await database;
    // بررسی اینکه شناسه مونتاژ به یک قطعه مونتاژی اشاره دارد
    final assemblyPart = await getPartById(composition.assemblyId);
    if (assemblyPart == null || !assemblyPart.isAssembly) {
      throw Exception('Assembly ID does not refer to an assembly part.'); // شناسه مونتاژ به یک قطعه مونتاژی اشاره ندارد
    }
    // بررسی وجود قطعه جزء
    final componentPart = await getPartById(composition.componentPartId);
    if (componentPart == null) {
      throw Exception('Component Part ID does not exist.'); // شناسه قطعه جزء وجود ندارد
    }
    return await db.insert('part_compositions', composition.toMap());
  }

  // تنظیم (بازنویسی) کامل اجزای تشکیل دهنده یک قطعه مونتاژی
  // این عملیات در یک تراکنش انجام می شود
  Future<void> setAssemblyComponents(int assemblyId, List<PartComposition> components) async {
    final db = await database;
    await db.transaction((txn) async {
      // حذف تمام اجزای قبلی این قطعه مونتاژی
      await txn.delete('part_compositions', where: 'assembly_id = ?', whereArgs: [assemblyId]);
      // افزودن اجزای جدید
      for (var comp in components) {
        if (comp.assemblyId != assemblyId) {
          throw Exception('Component assemblyId mismatch.'); // عدم تطابق شناسه مونتاژ در جزء
        }
        final componentPart = await getPartById(comp.componentPartId, txn: txn);
        if (componentPart == null) {
          throw Exception('Component Part ID ${comp.componentPartId} does not exist.'); // شناسه قطعه جزء وجود ندارد
        }
        await txn.insert('part_compositions', comp.toMap());
      }
    });
  }

  // حذف یک جزء از یک قطعه مونتاژی بر اساس شناسه ترکیب
  Future<int> removeComponentFromAssembly(int compositionId) async {
    final db = await database;
    return await db.delete('part_compositions', where: 'id = ?', whereArgs: [compositionId]);
  }

  // --- Product CRUD --- // عملیات CRUD مربوط به محصولات

  // افزودن یک محصول جدید
  // از ConflictAlgorithm.fail برای جلوگیری از افزودن محصول با نام تکراری استفاده می شود
  Future<int> insertProduct(Product product) async {
    final db = await database;
    try {
      return await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) {
      print('Error inserting product: $e');
      rethrow;
    }
  }

  // دریافت لیست محصولات، با قابلیت جستجو بر اساس نام
  Future<List<Product>> getProducts({String? query}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: query != null ? 'name LIKE ?' : null,
      whereArgs: query != null ? ['%$query%'] : null,
      orderBy: 'name ASC'
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // دریافت یک محصول خاص بر اساس شناسه، می تواند در یک تراکنش (txn) نیز اجرا شود
  Future<Product?> getProductById(int id, {DatabaseExecutor? txn}) async {
    final db = txn ?? await database;
    final List<Map<String, dynamic>> maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // به روزرسانی اطلاعات یک محصول موجود
  // از ConflictAlgorithm.fail برای جلوگیری از تغییر نام محصول به نامی که قبلا وجود داشته است استفاده می شود
  Future<int> updateProduct(Product product) async {
    final db = await database;
    try {
      return await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id], conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // حذف یک محصول بر اساس شناسه
  // اگر محصول در سفارشات فروش استفاده شده باشد، ممکن است با خطای محدودیت کلید خارجی مواجه شود
  Future<int> deleteProduct(int id) async {
    final db = await database;
    // توجه: حذف یک محصول ممکن است نیاز به بررسی های اضافی داشته باشد (مثلا اگر در order_items استفاده شده باشد)
    // قطعات محصول (product_parts) به دلیل ON DELETE CASCADE خودکار حذف می شوند
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- ProductPart (Product Components) CRUD --- // عملیات CRUD مربوط به قطعات تشکیل دهنده محصولات

  // دریافت لیست قطعات تشکیل دهنده یک محصول خاص
  Future<List<ProductPart>> getPartsForProduct(int productId, {DatabaseExecutor? txn}) async {
    final db = txn ?? await database;
    final List<Map<String, dynamic>> maps = await db.query('product_parts', where: 'product_id = ?', whereArgs: [productId]);
    return List.generate(maps.length, (i) => ProductPart.fromMap(maps[i]));
  }

  // تنظیم (بازنویسی) کامل قطعات تشکیل دهنده یک محصول
  // این عملیات در یک تراکنش انجام می شود
  Future<void> setProductParts(int productId, List<ProductPart> productParts) async {
    final db = await database;
    await db.transaction((txn) async {
      // حذف تمام قطعات قبلی این محصول
      await txn.delete('product_parts', where: 'product_id = ?', whereArgs: [productId]);
      // افزودن قطعات جدید
      for (var pp in productParts) {
        if (pp.productId != productId) {
          throw Exception('ProductPart productId mismatch.'); // عدم تطابق شناسه محصول در قطعه محصول
        }
        final part = await getPartById(pp.partId, txn: txn); // بررسی وجود قطعه
        if (part == null) {
          throw Exception('Part ID ${pp.partId} for product does not exist.'); // شناسه قطعه برای محصول وجود ندارد
        }
        await txn.insert('product_parts', pp.toMap());
      }
    });
  }

  // --- AssemblyOrder CRUD --- // عملیات CRUD مربوط به سفارشات مونتاژ

  // افزودن یک سفارش مونتاژ جدید
  Future<int> insertAssemblyOrder(AssemblyOrder order) async {
    final db = await database;
    // بررسی اینکه شناسه قطعه به یک قطعه مونتاژی معتبر اشاره دارد
    final part = await getPartById(order.partId);
    if (part == null || !part.isAssembly) {
      throw Exception('Part ID for assembly order must be an assembly part.'); // شناسه قطعه برای سفارش مونتاژ باید یک قطعه مونتاژی باشد
    }
    return await db.insert('assembly_orders', order.toMap());
  }

  // دریافت لیست سفارشات مونتاژ، با قابلیت فیلتر بر اساس وضعیت
  Future<List<AssemblyOrder>> getAssemblyOrders({String? status}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assembly_orders',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'date DESC' // مرتب سازی بر اساس تاریخ به صورت نزولی
    );
    return List.generate(maps.length, (i) => AssemblyOrder.fromMap(maps[i]));
  }

  // دریافت یک سفارش مونتاژ خاص بر اساس شناسه
  Future<AssemblyOrder?> getAssemblyOrderById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('assembly_orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return AssemblyOrder.fromMap(maps.first);
    }
    return null;
  }

  // به روزرسانی وضعیت یک سفارش مونتاژ
  Future<int> updateAssemblyOrderStatus(int orderId, String status) async {
    final db = await database;
    return await db.update('assembly_orders', {'status': status}, where: 'id = ?', whereArgs: [orderId]);
  }

  // حذف یک سفارش مونتاژ بر اساس شناسه
  Future<int> deleteAssemblyOrder(int id) async {
    final db = await database;
    return await db.delete('assembly_orders', where: 'id = ?', whereArgs: [id]);
  }

  // تکمیل یک سفارش مونتاژ
  // این عملیات در یک تراکنش انجام می شود:
  // 1. وضعیت سفارش به 'Completed' تغییر می کند.
  // 2. موجودی قطعه مونتاژ شده افزایش می یابد.
  // 3. موجودی اجزای تشکیل دهنده آن کاهش می یابد.
  Future<void> completeAssemblyOrder(int assemblyOrderId) async {
    final db = await database;
    await db.transaction((txn) async {
      final orderMap = await txn.query('assembly_orders', where: 'id = ?', whereArgs: [assemblyOrderId]);
      if (orderMap.isEmpty) throw Exception('AssemblyOrder not found'); // سفارش مونتاژ پیدا نشد
      final order = AssemblyOrder.fromMap(orderMap.first);

      if (order.status == 'Completed') throw Exception('Order already completed'); // سفارش قبلا تکمیل شده است

      final assembledPart = await getPartById(order.partId, txn: txn);
      if (assembledPart == null) throw Exception('Assembled part not found'); // قطعه مونتاژی پیدا نشد

      // افزایش موجودی قطعه مونتاژ شده
      await _updateInventoryItemQuantityInternal(assembledPart.name, order.quantityToProduce, txn: txn);

      // کاهش موجودی اجزای تشکیل دهنده
      final components = await getComponentsForAssembly(order.partId, txn: txn);
      for (var composition in components) {
        final componentPart = await getPartById(composition.componentPartId, txn: txn);
        if (componentPart == null) throw Exception('Component part ${composition.componentPartId} not found'); // قطعه جزء پیدا نشد
        final quantityToConsume = composition.quantity * order.quantityToProduce; // مقدار مصرفی از هر جزء
        await _updateInventoryItemQuantityInternal(componentPart.name, -quantityToConsume, txn: txn); // کاهش موجودی جزء
      }
      // به روزرسانی وضعیت سفارش به 'Completed'
      await txn.update('assembly_orders', {'status': 'Completed'}, where: 'id = ?', whereArgs: [assemblyOrderId]);
    });
  }

  // --- Customer CRUD --- // عملیات CRUD مربوط به مشتریان

  // افزودن یک مشتری جدید
  // ConflictAlgorithm.replace: اگر مشتری با این شناسه وجود داشته باشد، جایگزین می شود (معمولا شناسه خودکار است و این اتفاق نمی افتد مگر اینکه شناسه دستی تنظیم شود)
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // دریافت لیست تمام مشتریان، با قابلیت جستجو بر اساس نام
  Future<List<Customer>> getCustomers({String? query}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.isNotEmpty) {
      maps = await db.query('customers', where: 'name LIKE ?', whereArgs: ['%$query%'], orderBy: 'name ASC');
    } else {
      maps = await db.query('customers', orderBy: 'name ASC');
    }
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  // دریافت یک مشتری خاص بر اساس شناسه
  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  // به روزرسانی اطلاعات یک مشتری موجود
  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id], conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // حذف یک مشتری بر اساس شناسه
  // اگر مشتری سفارشات فروش مرتبط داشته باشد، به دلیل ON DELETE RESTRICT حذف انجام نمی شود
  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // --- SalesOrder CRUD --- // عملیات CRUD مربوط به سفارشات فروش

  // افزودن یک سفارش فروش جدید به همراه آیتم های آن
  // این عملیات در یک تراکنش انجام می شود
  Future<int> insertSalesOrder(SalesOrder order) async {
    final db = await database;
    return await db.transaction((txn) async {
      order.calculateTotalAmount(); // محاسبه مبلغ کل سفارش
      int orderId = await txn.insert('sales_orders', order.toMap()); // افزودن سفارش اصلی
      for (var item in order.items) {
        var itemMap = item.toMap();
        itemMap['order_id'] = orderId; // تنظیم شناسه سفارش برای هر آیتم
        await txn.insert('order_items', itemMap); // افزودن آیتم سفارش
      }
      return orderId; // برگرداندن شناسه سفارش ایجاد شده
    });
  }

  // متد داخلی برای دریافت آیتم های یک سفارش فروش خاص
  Future<List<OrderItem>> _getOrderItemsForSalesOrder(int orderId, {DatabaseExecutor? txn}) async {
    final db = txn ?? await database;
    final List<Map<String, dynamic>> maps = await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    return List.generate(maps.length, (i) => OrderItem.fromMap(maps[i]));
  }

  // متد داخلی برای دریافت پرداخت های یک سفارش فروش خاص
  Future<List<Payment>> _getPaymentsForSalesOrder(int orderId, {DatabaseExecutor? txn}) async {
    final db = txn ?? await database;
    final List<Map<String, dynamic>> maps = await db.query('payments', where: 'order_id = ?', whereArgs: [orderId], orderBy: 'payment_date DESC');
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  // دریافت لیست سفارشات فروش، با قابلیت فیلتر بر اساس وضعیت و شناسه مشتری
  Future<List<SalesOrder>> getSalesOrders({String? status, int? customerId}) async {
    final db = await database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (status != null && status.isNotEmpty) {
      whereClause = 'status = ?';
      whereArgs.add(status);
    }
    if (customerId != null) {
      whereClause = (whereClause == null ? '' : '$whereClause AND ') + 'customer_id = ?';
      whereArgs.add(customerId);
    }

    final List<Map<String, dynamic>> orderMaps = await db.query(
      'sales_orders',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'order_date DESC' // مرتب سازی بر اساس تاریخ سفارش به صورت نزولی
    );

    List<SalesOrder> orders = [];
    for (var map in orderMaps) {
      final orderId = map['id'] as int;
      // برای هر سفارش، آیتم ها و پرداخت های آن نیز بازیابی می شوند
      List<OrderItem> items = await _getOrderItemsForSalesOrder(orderId);
      List<Payment> payments = await _getPaymentsForSalesOrder(orderId);
      orders.add(SalesOrder.fromMap(map, items: items, payments: payments));
    }
    return orders;
  }

  // دریافت یک سفارش فروش خاص بر اساس شناسه، به همراه آیتم ها و پرداخت های آن
  Future<SalesOrder?> getSalesOrderById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sales_orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      List<OrderItem> items = await _getOrderItemsForSalesOrder(id);
      List<Payment> payments = await _getPaymentsForSalesOrder(id);
      return SalesOrder.fromMap(maps.first, items: items, payments: payments);
    }
    return null;
  }

  // به روزرسانی یک سفارش فروش موجود
  // این عملیات در یک تراکنش انجام می شود: آیتم های قدیمی حذف و آیتم های جدید اضافه می شوند
  Future<int> updateSalesOrder(SalesOrder order) async {
    final db = await database;
    return await db.transaction((txn) async {
      order.calculateTotalAmount(); // محاسبه مجدد مبلغ کل
      // به روزرسانی سفارش اصلی
      int count = await txn.update('sales_orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
      // حذف آیتم های قدیمی سفارش
      await txn.delete('order_items', where: 'order_id = ?', whereArgs: [order.id]);
      // افزودن آیتم های جدید سفارش
      for (var item in order.items) {
        var itemMap = item.toMap();
        itemMap['order_id'] = order.id;
        await txn.insert('order_items', itemMap);
      }
      return count; // تعداد رکوردهای به روز شده در جدول سفارشات اصلی (باید 1 باشد)
    });
  }

  // به روزرسانی وضعیت یک سفارش فروش
  Future<int> updateSalesOrderStatus(int orderId, String status) async {
    final db = await database;
    return await db.update('sales_orders', {'status': status}, where: 'id = ?', whereArgs: [orderId]);
  }

  // حذف یک سفارش فروش بر اساس شناسه
  // آیتم ها و پرداخت های مرتبط به دلیل ON DELETE CASCADE خودکار حذف می شوند
  Future<int> deleteSalesOrder(int id) async {
    final db = await database;
    return await db.delete('sales_orders', where: 'id = ?', whereArgs: [id]);
  }

  // --- Payment CRUD --- // عملیات CRUD مربوط به پرداخت ها

  // افزودن یک پرداخت جدید
  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  // دریافت لیست پرداخت های یک سفارش خاص
  Future<List<Payment>> getPaymentsForOrder(int orderId) async {
    return _getPaymentsForSalesOrder(orderId); // از متد داخلی استفاده می کند
  }

  // حذف یک پرداخت بر اساس شناسه
  Future<int> deletePayment(int paymentId) async {
    final db = await database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
  }

  // --- Complex Operations & Reports --- // عملیات پیچیده و گزارش ها

  // تکمیل یک سفارش فروش و به روزرسانی موجودی کالا
  // این عملیات در یک تراکنش انجام می شود:
  // 1. وضعیت سفارش به 'Completed' تغییر می کند.
  // 2. موجودی محصولات (یا قطعات تشکیل دهنده آنها) کاهش می یابد.
  Future<void> completeSalesOrderAndUpdateInventory(int salesOrderId) async {
    final db = await database;
    await db.transaction((txn) async {
      final order = await getSalesOrderById(salesOrderId); // دریافت سفارش با استفاده از متد موجود که آیتم ها را نیز شامل می شود
      if (order == null) throw Exception('SalesOrder not found for completion.'); // سفارش پیدا نشد
      if (order.status == 'Completed') throw Exception('SalesOrder already completed.'); // سفارش قبلا تکمیل شده است

      for (var item in order.items) {
        final product = await getProductById(item.productId, txn: txn);
        if (product == null) throw Exception('Product with ID ${item.productId} not found.'); // محصول پیدا نشد

        final productParts = await getPartsForProduct(product.id!, txn: txn); // قطعات تشکیل دهنده محصول
        if (productParts.isEmpty) {
          // اگر محصول قطعه تشکیل دهنده ندارد (یعنی خودش یک آیتم موجودی است)
          await _updateInventoryItemQuantityInternal(product.name, -item.quantity, txn: txn); // کاهش موجودی خود محصول
        } else {
          // اگر محصول از قطعات دیگر تشکیل شده است
          for (var productPart in productParts) {
            final partToConsume = await getPartById(productPart.partId, txn: txn);
            if (partToConsume == null) throw Exception('Part with ID ${productPart.partId} for product ${product.name} not found.'); // قطعه تشکیل دهنده پیدا نشد
            final totalQuantityOfPartToConsume = productPart.quantity * item.quantity; // مقدار کل مصرفی از هر قطعه
            await _updateInventoryItemQuantityInternal(partToConsume.name, -totalQuantityOfPartToConsume, txn: txn); // کاهش موجودی قطعه
          }
        }
      }
      // به روزرسانی وضعیت سفارش به 'Completed'
      await txn.update('sales_orders', {'status': 'Completed'}, where: 'id = ?', whereArgs: [salesOrderId]);
    });
  }

  // دریافت مجموع فروش در یک بازه تاریخی مشخص (فقط سفارشات تکمیل شده)
  Future<double> getSalesTotalInDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final String startDateStr = start.toIso8601String().substring(0, 10);
    final String endDateStr = end.toIso8601String().substring(0, 10);
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT SUM(total_amount) as total FROM sales_orders WHERE status = 'Completed' AND order_date BETWEEN ? AND ?",
      [startDateStr, endDateStr],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // دریافت مجموع خرید در یک بازه تاریخی مشخص
  Future<double> getPurchaseTotalInDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final String startDateStr = start.toIso8601String().substring(0, 10);
    final String endDateStr = end.toIso8601String().substring(0, 10);
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT SUM(total_amount) as total FROM purchase_invoices WHERE date BETWEEN ? AND ?",
      [startDateStr, endDateStr],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // --- Backup History CRUD --- // عملیات CRUD مربوط به تاریخچه پشتیبان گیری

  // افزودن اطلاعات یک پشتیبان گیری جدید
  Future<int> insertBackupInfo(BackupInfo backupInfo) async {
    final db = await database;
    return await db.insert('backups', backupInfo.toMap());
  }

  // دریافت تاریخچه تمام پشتیبان گیری ها، مرتب شده بر اساس تاریخ به صورت نزولی
  Future<List<BackupInfo>> getBackupHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('backups', orderBy: 'backup_date DESC');
    return List.generate(maps.length, (i) {
      return BackupInfo.fromMap(maps[i]);
    });
  }

  // حذف یک رکورد اطلاعات پشتیبان گیری بر اساس شناسه
  Future<int> deleteBackupInfo(int id) async {
    final db = await database;
    return await db.delete('backups', where: 'id = ?', whereArgs: [id]);
  }

  // پاک کردن کامل تاریخچه پشتیبان گیری
  Future<void> clearBackupHistory() async {
    final db = await database;
    await db.delete('backups');
  }

  // بستن اتصال پایگاه داده
  Future<void> close() async {
    final db = await database;
    if (db.isOpen) { // اگر پایگاه داده باز است
      db.close(); // آن را ببند
    }
    _database = null; // نمونه پایگاه داده را null کن
  }
}
