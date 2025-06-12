import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Controllers // کنترلرها
import 'modules/employees/controllers/employee_controller.dart'; // کنترلر کارمندان
import 'modules/purchases/controllers/purchase_controller.dart'; // کنترلر خریدها
import 'modules/parts/controllers/part_controller.dart'; // کنترلر قطعات
import 'modules/orders/controllers/order_controller.dart'; // کنترلر سفارشات
import 'modules/inventory/controllers/inventory_controller.dart'; // کنترلر موجودی
import 'core/notifiers/inventory_sync_notifier.dart'; // اطلاع رسان همگام سازی موجودی
import 'modules/reports/controllers/report_controller.dart'; // کنترلر گزارشات
import 'modules/backup/controllers/backup_controller.dart'; // کنترلر پشتیبان گیری

// Entry Screen // صفحه ورودی
import 'modules/employees/views/employee_list_screen.dart'; // صفحه لیست کارمندان

// Custom Theme // تم سفارشی
import 'shared/themes/app_theme.dart'; // تم برنامه

// تابع اصلی برنامه
void main() async {
  // اطمینان از اینکه ویجت باندینگ مقداردهی اولیه شده است
  WidgetsFlutterBinding.ensureInitialized();

  // اجرای برنامه
  runApp(const MyApp());
}

// ویجت اصلی برنامه
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // استفاده از MultiProvider برای فراهم کردن کنترلرها و اطلاع رسان ها در سراسر برنامه
    return MultiProvider(
      providers: [
        // فراهم کننده کنترلر کارمندان و فراخوانی اولیه لیست کارمندان
        ChangeNotifierProvider(
          create: (_) => EmployeeController()..fetchEmployees(),
        ),
        // فراهم کننده کنترلر خریدها با تزریق اطلاع رسان همگام سازی موجودی
        ChangeNotifierProvider<PurchaseController>(
          create: (context) => PurchaseController(context.read<InventorySyncNotifier>()),
        ),
        // فراهم کننده کنترلر قطعات
        ChangeNotifierProvider<PartController>( // Updated PartController
          create: (context) => PartController(context.read<InventorySyncNotifier>()),
        ),
        // فراهم کننده کنترلر سفارشات
        ChangeNotifierProvider<OrderController>( // Updated OrderController
          create: (context) => OrderController(context.read<InventorySyncNotifier>()),
        ),
        // فراهم کننده اطلاع رسان همگام سازی موجودی
        ChangeNotifierProvider<InventorySyncNotifier>(
          create: (_) => InventorySyncNotifier(),
        ),
        // فراهم کننده کنترلر موجودی با تزریق اطلاع رسان همگام سازی موجودی
        ChangeNotifierProvider<InventoryController>(
          create: (context) => InventoryController(context.read<InventorySyncNotifier>()),
        ),
        // فراهم کننده کنترلر گزارشات
        ChangeNotifierProvider(
          create: (_) => ReportController(),
        ),
        // فراهم کننده کنترلر پشتیبان گیری
        ChangeNotifierProvider(
          create: (_) => BackupController(),
        ),
      ],
      child: MaterialApp(
        title: 'Workshop Management', // عنوان برنامه
        // اعمال تم روشن سفارشی
        theme: AppTheme.lightTheme,
        // تم تیره در صورت نیاز میتواند بعدا اضافه شود:
        // darkTheme: AppTheme.darkTheme,
        // themeMode: ThemeMode.system, // یا اجازه به کاربر برای انتخاب

        // صفحه اصلی برنامه
        home: const EmployeeListScreen(),
        // عدم نمایش بنر دیباگ
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
