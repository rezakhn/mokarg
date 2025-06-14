import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart'; // Removed unused import
import 'package:workshop_management_app/shared/widgets/main_layout_scaffold.dart'; // Added
import '../controllers/order_controller.dart';
import '../models/customer.dart'; // Required for _getCustomerName
import '../models/sales_order.dart'; // Not directly used if card handles it
import 'sales_order_edit_screen.dart';
import '../widgets/sales_order_card.dart';

class SalesOrderListScreen extends StatefulWidget {
  const SalesOrderListScreen({Key? key}) : super(key: key);
  @override
  State<SalesOrderListScreen> createState() => _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends State<SalesOrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false).fetchSalesOrders();
      Provider.of<OrderController>(context, listen: false).fetchCustomers();
    });
  }

  String _getCustomerName(BuildContext context, int customerId) {
    final controller = Provider.of<OrderController>(context, listen: false);
    try {
       if (controller.customers.isEmpty) {
          return 'ID: $customerId';
      }
      return controller.customers.firstWhere((c) => c.id == customerId).name;
    } catch (e) {
      return 'Unknown Customer (ID: $customerId)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget screenBody = Consumer<OrderController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.salesOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage != null && controller.salesOrders.isEmpty) {
          return Center(child: Text('Error: ${controller.errorMessage}'));
        }
        if (controller.salesOrders.isEmpty) {
          return const Center(child: Text('No sales orders found. Create one!'));
        }
        return ListView.builder(
          itemCount: controller.salesOrders.length,
          itemBuilder: (context, index) {
            final order = controller.salesOrders[index];
            final customerName = _getCustomerName(context, order.customerId);
            return SalesOrderCard(
              order: order,
              customerName: customerName,
              onTap: () {
                  if (!mounted) return; // Added check
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SalesOrderEditScreen(salesOrder: order)),
                ).then((_) {
                  if (!mounted) return;
                  Provider.of<OrderController>(context, listen: false).fetchSalesOrders();
                });
              },
              onDelete: (order.status != 'Completed' && order.status != 'Cancelled') ? () async {
                final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirm Delete'), content: Text('Are you sure you want to delete Sales Order #${order.id}?'), actions: [TextButton(child: const Text('Cancel'), onPressed: ()=>Navigator.pop(ctx, false)), TextButton(child: const Text('Delete'), onPressed: ()=>Navigator.pop(ctx, true))]));
                if (!mounted) return; // Check after showDialog
                if (confirm == true) { // No need to recheck mounted if it was true for the previous check
                    bool success = await controller.deleteSalesOrder(order.id!);
                    if (!mounted) return; // Check after await
                    if (!success && controller.errorMessage != null) {
                         if (!mounted) return; // Added check
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${controller.errorMessage}')),
                          );
                    }
                }
              } : null
            );
          },
        );
      },
    );
    return MainLayoutScaffold(
      title: 'Sales Orders',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add_shopping_cart_outlined),
          tooltip: 'New Sales Order',
          onPressed: () {
            if (!mounted) return; // Added check
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalesOrderEditScreen()),
            ).then((_) {
              if (!mounted) return;
              Provider.of<OrderController>(context, listen: false).fetchSalesOrders();
            });
          },
        ),
      ],
      body: screenBody,
    );
  }
}
