import 'package:flutter/material.dart';

// ایمپورت تمام صفحات لیست/داشبورد برای ناوبری
import '../../modules/employees/views/employee_list_screen.dart'; // صفحه لیست کارمندان
import '../../modules/orders/views/customer_list_screen.dart'; // صفحه لیست مشتریان
import '../../modules/orders/views/sales_order_list_screen.dart'; // صفحه لیست سفارشات فروش
import '../../modules/purchases/views/supplier_list_screen.dart'; // صفحه لیست تامین کنندگان
import '../../modules/purchases/views/purchase_invoice_list_screen.dart'; // صفحه لیست فاکتورهای خرید
import '../../modules/inventory/views/inventory_list_screen.dart'; // صفحه لیست موجودی
import '../../modules/parts/views/part_list_screen.dart'; // صفحه لیست قطعات و مونتاژها
import '../../modules/reports/views/report_dashboard_screen.dart'; // داشبورد گزارشات
import '../../modules/backup/views/backup_settings_screen.dart'; // صفحه تنظیمات پشتیبان گیری و بازیابی

// ویجت منوی کشویی (Drawer) برنامه
class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  // لیست آیتم های ناوبری در منو
  // از یک کلاس کمکی داخلی (_NavigationItem) برای تعریف هر آیتم استفاده شده است
  static final List<_NavigationItem> _navItems = [
    // هر آیتم شامل آیکون، عنوان و ویجت صفحه مقصد است
    _NavigationItem(icon: Icons.people_alt_outlined, title: 'کارمندان', routeWidget: const EmployeeListScreen()), // صفحه اصلی فعلی
    _NavigationItem(icon: Icons.person_pin_circle_outlined, title: 'مشتریان', routeWidget: const CustomerListScreen()),
    _NavigationItem(icon: Icons.shopping_cart_checkout_outlined, title: 'سفارشات فروش', routeWidget: const SalesOrderListScreen()),
    const _NavigationItem(isDivider: true), // جداکننده
    _NavigationItem(icon: Icons.storefront_outlined, title: 'تامین کنندگان', routeWidget: const SupplierListScreen()),
    _NavigationItem(icon: Icons.receipt_long_outlined, title: 'فاکتورهای خرید', routeWidget: const PurchaseInvoiceListScreen()),
    const _NavigationItem(isDivider: true), // جداکننده
    _NavigationItem(icon: Icons.inventory_2_outlined, title: 'موجودی انبار', routeWidget: const InventoryListScreen()),
    _NavigationItem(icon: Icons.build_circle_outlined, title: 'قطعات و مونتاژها', routeWidget: const PartListScreen()),
    const _NavigationItem(isDivider: true), // جداکننده
    _NavigationItem(icon: Icons.assessment_outlined, title: 'گزارشات', routeWidget: const ReportDashboardScreen()),
    _NavigationItem(icon: Icons.settings_backup_restore_outlined, title: 'پشتیبان گیری و بازیابی', routeWidget: const BackupSettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // حذف پدینگ پیش فرض ListView
        children: <Widget>[
          // هدر منوی کشویی
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor, // استفاده از رنگ اصلی تم
            ),
            child: Text(
              'مدیریت کارگاه', // عنوان برنامه در هدر منو
              style: TextStyle(
                color: Colors.white, // رنگ متن سفید
                fontSize: 24, // اندازه فونت
              ),
            ),
          ),
          // ایجاد آیتم های منو از لیست _navItems
          ..._navItems.map((item) {
            if (item.isDivider) { // اگر آیتم جداکننده است
              return const Divider(); // یک جداکننده نمایش بده
            }
            // در غیر این صورت، یک ListTile برای آیتم ناوبری ایجاد کن
            return ListTile(
              leading: Icon(item.icon), // آیکون آیتم
              title: Text(item.title!), // عنوان آیتم
              onTap: () { // رویداد کلیک روی آیتم
                // ابتدا منو را ببند
                Navigator.pop(context);
                // سپس به صفحه جدید برو، و اگر صفحه فعلی یک نمای سطح بالا است، آن را جایگزین کن.
                // این کار از ایجاد یک پشته بزرگ از صفحات قبلی در هنگام ناوبری از منو جلوگیری می کند.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => item.routeWidget!),
                );
              },
            );
          }).toList(), // تبدیل map به لیست ویجت ها
        ],
      ),
    );
  }
}

// کلاس کمکی داخلی برای تعریف مشخصات هر آیتم ناوبری در منو
class _NavigationItem {
  final IconData? icon; // آیکون آیتم (اختیاری اگر جداکننده باشد)
  final String? title; // عنوان آیتم (اختیاری اگر جداکننده باشد)
  final Widget? routeWidget; // ویجت صفحه ای که باید به آن ناوبری شود (اختیاری اگر جداکننده باشد)
  final bool isDivider; // آیا این آیتم یک جداکننده است؟

  // سازنده کلاس _NavigationItem
  const _NavigationItem({
    this.icon,
    this.title,
    this.routeWidget,
    this.isDivider = false, // پیش فرض: آیتم جداکننده نیست
  });
}
