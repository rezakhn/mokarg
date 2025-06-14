import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';
import '../models/sales_order.dart';
import '../models/order_item.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../../parts/models/product.dart'; // For product selection
import '../widgets/payment_list_tile.dart'; // Added import

class SalesOrderEditScreen extends StatefulWidget {
  final SalesOrder? salesOrder; // If null, it's a new order

  const SalesOrderEditScreen({Key? key, this.salesOrder}) : super(key: key);

  @override
  State<SalesOrderEditScreen> createState() => _SalesOrderEditScreenState();
}

class _SalesOrderEditScreenState extends State<SalesOrderEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form state
  int? _selectedCustomerId;
  DateTime _orderDate = DateTime.now();
  DateTime? _deliveryDate;
  String _status = 'Pending';
  List<OrderItem> _currentOrderItems = [];
  List<Payment> _currentPayments = [];

  late TextEditingController _orderDateController;
  late TextEditingController _deliveryDateController;

  final _paymentAmountController = TextEditingController();
  DateTime _paymentDate = DateTime.now();


  @override
  void initState() {
    super.initState();
    _orderDateController = TextEditingController(text: DateFormat.yMMMd().format(_orderDate));
    _deliveryDateController = TextEditingController();

    final orderController = Provider.of<OrderController>(context, listen: false);
    orderController.fetchCustomers();
    orderController.fetchAvailableProducts();

    if (widget.salesOrder != null) {
      final existingOrder = widget.salesOrder!;
      _selectedCustomerId = existingOrder.customerId;
      _orderDate = existingOrder.orderDate;
      _deliveryDate = existingOrder.deliveryDate;
      _status = existingOrder.status;
      _currentOrderItems = List<OrderItem>.from(existingOrder.items.map((item) =>
          OrderItem(orderId: item.orderId, productId: item.productId, quantity: item.quantity, priceAtSale: item.priceAtSale, id: item.id)
      ));
      _currentPayments = List<Payment>.from(existingOrder.payments);

      _orderDateController.text = DateFormat.yMMMd().format(_orderDate);
      if (_deliveryDate != null) {
        _deliveryDateController.text = DateFormat.yMMMd().format(_deliveryDate!);
      }
      // Fetch full details if the passed order might be partial
      // This ensures payments and items are fresh if the list view doesn't load them fully
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final fullOrder = await orderController.getFullSalesOrderDetails(widget.salesOrder!.id!);
        if (fullOrder != null && mounted) {
          setState(() {
            _selectedCustomerId = fullOrder.customerId;
            _orderDate = fullOrder.orderDate;
            _deliveryDate = fullOrder.deliveryDate;
            _status = fullOrder.status;
            _currentOrderItems = List<OrderItem>.from(fullOrder.items.map((item) =>
                OrderItem(orderId: item.orderId, productId: item.productId, quantity: item.quantity, priceAtSale: item.priceAtSale, id: item.id)
            ));
            _currentPayments = List<Payment>.from(fullOrder.payments);
            _orderDateController.text = DateFormat.yMMMd().format(_orderDate);
            _deliveryDateController.text = _deliveryDate != null ? DateFormat.yMMMd().format(_deliveryDate!) : "";
          });
        }
      });
    } else {
      final customers = orderController.customers;
      if (customers.isNotEmpty) _selectedCustomerId = customers.first.id;
    }
  }

  Future<void> _pickDate(BuildContext context, bool isOrderDate) async {
    final initial = isOrderDate ? _orderDate : (_deliveryDate ?? DateTime.now());
    final DateTime? picked = await showDatePicker(
        context: context, initialDate: initial,
        firstDate: DateTime(2000), lastDate: DateTime(2101));
    if (picked != null) {
      setState(() {
        if (isOrderDate) {
          _orderDate = picked; _orderDateController.text = DateFormat.yMMMd().format(_orderDate);
        } else {
          _deliveryDate = picked; _deliveryDateController.text = DateFormat.yMMMd().format(_deliveryDate!);
        }
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer.')));
      return;
    }
    if (_currentOrderItems.isEmpty && widget.salesOrder == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add items to the order.')));
      return;
    }

    final controller = Provider.of<OrderController>(context, listen: false);
    final orderToSave = SalesOrder(
      id: widget.salesOrder?.id,
      customerId: _selectedCustomerId!,
      orderDate: _orderDate,
      deliveryDate: _deliveryDate,
      status: _status,
      items: _currentOrderItems,
    );
    orderToSave.calculateTotalAmount();

    bool success;
    if (widget.salesOrder == null) {
      success = await controller.addSalesOrder(orderToSave);
    } else {
      success = await controller.updateSalesOrder(orderToSave);
    }

    if (!mounted) return; // Check after awaits
    if (success) {
      Navigator.of(context).pop();
    } else if (controller.errorMessage != null) { // mounted is already checked
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
    }
  }

  void _showAddOrderItemDialog() {
    final orderController = Provider.of<OrderController>(context, listen: false);
    Product? selectedProduct;
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(context: context, builder: (dialogContext){
      return AlertDialog(
        title: const Text("Add Item to Order"),
        content: StatefulBuilder(builder: (BuildContext context, StateSetter setStateDialog){
          return Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<Product>(
              hint: const Text("Select Product"),
              value: selectedProduct,
              items: orderController.availableProducts.map((p) => DropdownMenuItem<Product>(value: p, child: Text(p.name))).toList(),
              onChanged: (Product? val) { setStateDialog(() { selectedProduct = val; priceController.text = ""; }); },
              validator: (val) => val == null ? "Product required" : null,
            ),
            TextFormField(controller: quantityController, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
            TextFormField(controller: priceController, decoration: const InputDecoration(labelText: "Price per Unit"), keyboardType: TextInputType.number),
          ]);
        }),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(onPressed: (){
            if (selectedProduct != null && quantityController.text.isNotEmpty && priceController.text.isNotEmpty) {
              final qty = double.tryParse(quantityController.text);
              final price = double.tryParse(priceController.text);
              if (qty != null && qty > 0 && price != null && price >= 0) {
                setState(() {
                  _currentOrderItems.add(OrderItem(
                    orderId: widget.salesOrder?.id ?? 0,
                    productId: selectedProduct!.id!,
                    quantity: qty,
                    priceAtSale: price
                  ));
                });
                Navigator.pop(dialogContext);
              }
            }
          }, child: const Text("Add Item")),
        ],
      );
    });
  }

  Widget _buildPaymentsSection() {
    if (widget.salesOrder == null) return SizedBox.shrink();
    final order = widget.salesOrder!;

    // Calculate total paid
    final double totalPaid = _currentPayments.fold<double>(0.0, (sum, p) => sum + p.amount);

    // Calculate order total for outstanding calculation
    // Ensure _selectedCustomerId and _orderDate are valid here.
    // If this is for a new order and customer might not be selected, this could be an issue.
    // However, _buildPaymentsSection is only shown if widget.salesOrder != null,
    // implying _selectedCustomerId and _orderDate are from an existing order.
    final tempOrderForOutstanding = SalesOrder(
        customerId: _selectedCustomerId!, // Should be safe as widget.salesOrder is not null
        orderDate: _orderDate,          // Should be safe
        items: _currentOrderItems
    );
    tempOrderForOutstanding.calculateTotalAmount();
    final double orderTotalForOutstanding = tempOrderForOutstanding.totalAmount;
    final double outstandingAmount = orderTotalForOutstanding - totalPaid;

    return Column(children: [
      Text("Payments", style: Theme.of(context).textTheme.titleMedium),
      Text(
        "Total Paid: ${totalPaid.toStringAsFixed(2)} / Outstanding: ${outstandingAmount.toStringAsFixed(2)}",
        style: TextStyle(fontWeight: FontWeight.bold)
      ),
       ListView.builder(
          shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
          itemCount: _currentPayments.length,
          itemBuilder: (ctx, idx) {
            final payment = _currentPayments[idx];
            return PaymentListTile( // Using the new widget
              payment: payment,
              onDelete: () async {
                // No context use before await, so initial mounted check not strictly needed for this part
                final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirm Delete'), content: Text('Delete payment of ${payment.amount.toStringAsFixed(2)}?'), actions: [TextButton(child: const Text('Cancel'), onPressed: ()=>Navigator.pop(ctx, false)), TextButton(child: const Text('Delete'), onPressed: ()=>Navigator.pop(ctx, true))]));
                if (!mounted) return; // Check after await showDialog
                if (confirm == true) {
                  bool success = await Provider.of<OrderController>(context, listen: false).deletePayment(payment.id!);
                  if (!mounted) return; // Check after await deletePayment
                  if(success) {
                      final updatedOrder = await Provider.of<OrderController>(context, listen: false).getFullSalesOrderDetails(order.id!);
                      if (!mounted) return; // Check after await getFullSalesOrderDetails
                      if (updatedOrder != null) setState(() => _currentPayments = updatedOrder.payments);
                  }
                }
              }
            );
          },
        ),
      Row(children: [
        Expanded(child: TextFormField(controller: _paymentAmountController, decoration: InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number)),
        IconButton(icon: Icon(Icons.calendar_today), onPressed: () async {
            final DateTime? picked = await showDatePicker(context: context, initialDate: _paymentDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
            // setState is on picked != null, which is synchronous after await. Mounted check not strictly needed for setState itself if it's guarded.
            if (picked != null) { // mounted check is implicitly handled by widget lifecycle for setState
                setState(() => _paymentDate = picked);
            }
        }), Text(DateFormat.yMMMd().format(_paymentDate))),
        ElevatedButton(onPressed: () async {
            final amount = double.tryParse(_paymentAmountController.text);
            if (amount != null && amount > 0) {
                final newPayment = Payment(orderId: order.id!, amount: amount, paymentDate: _paymentDate);
                bool success = await Provider.of<OrderController>(context, listen: false).addPayment(newPayment);
                if (!mounted) return; // Check after await addPayment
                if(success) {
                    _paymentAmountController.clear();
                    final updatedOrder = await Provider.of<OrderController>(context, listen: false).getFullSalesOrderDetails(order.id!);
                    if (!mounted) return; // Check after await getFullSalesOrderDetails
                    if (updatedOrder != null) setState(() => _currentPayments = updatedOrder.payments);
                }
            }
        }, child: Text("Add Pmt"))
      ])
    ]);
  }

  Widget _buildStatusAndCompletionSection() {
    if (widget.salesOrder == null) return SizedBox.shrink();
    final controller = Provider.of<OrderController>(context, listen: false);
    final currentStatus = _status;

    List<String> statuses = ["Pending", "Confirmed", "Awaiting Payment", "Awaiting Delivery", "Completed", "Cancelled"];

    return Column(children: [
        DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Order Status"),
            value: currentStatus,
            items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (String? newStatus) async {
                if (newStatus != null && newStatus != currentStatus) {
                    bool success = await controller.updateSalesOrderStatus(widget.salesOrder!.id!, newStatus);
                    if (!mounted) return; // Check after await
                    if (success) {
                        setState(() => _status = newStatus);
                    }
                }
            }
        ),
        if (currentStatus != 'Completed' && currentStatus != 'Cancelled')
          ElevatedButton(
            child: Text("Check Stock Availability"),
            onPressed: () async {
              await controller.selectSalesOrder(widget.salesOrder!.id!);
              await controller.checkStockForSelectedOrder();
              if (!mounted) return; // Check after awaits
              if (controller.itemShortages.isNotEmpty) {
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text("Stock Shortages"),
                  content: Column(mainAxisSize: MainAxisSize.min, children: controller.itemShortages.entries.map((e) => Text('${e.key}: Short by ${e.value}')).toList()),
                  actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("OK"))],
                ));
              } else if (controller.itemShortages.isEmpty && controller.errorMessage == null) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All items in stock!")));
              }
            }
          ), // Add comma here ,
        Consumer<OrderController>(builder: (ctx, ctrl, _) {
            if(ctrl.selectedSalesOrder?.id != widget.salesOrder?.id || ctrl.itemShortages.isEmpty) return SizedBox.shrink();
            return Padding(padding: EdgeInsets.symmetric(vertical:8), child: Column(
                children: ctrl.itemShortages.entries.map((e) => Text('${e.key}: Short by ${e.value}', style: TextStyle(color: Colors.red))).toList()
            ));
        }),
        if (currentStatus != 'Completed' && currentStatus != 'Cancelled')
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text("Mark as Completed (Deliver & Update Inventory)"),
                onPressed: () async {
                    // No context use before await, so initial mounted check not strictly needed for this part
                    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirm Completion'), content: Text('Mark order as completed and update inventory? This cannot be undone easily.'), actions: [TextButton(child: const Text('Cancel'), onPressed: ()=>Navigator.pop(ctx, false)), TextButton(child: const Text('Complete'), onPressed: ()=>Navigator.pop(ctx, true))]));
                    if (!mounted) return; // Check after await showDialog
                    if(confirm == true) {
                      bool success = await controller.completeSelectedSalesOrder(widget.salesOrder!.id!, false);
                      if (!mounted) return; // Check after await completeSelectedSalesOrder
                      if (success) {
                          setState(() => _status = "Completed");
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order completed and inventory updated!'))); // Added semicolon
                      }
                    }
                }
            )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.salesOrder == null ? 'Create Sales Order' : 'Order ID: ${widget.salesOrder!.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Consumer<OrderController>(builder: (context, controller, child){
                return DropdownButtonFormField<int>(
                  value: _selectedCustomerId,
                  hint: const Text('Select Customer'),
                  items: controller.customers.map((Customer c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (int? newValue) => setState(() => _selectedCustomerId = newValue),
                  validator: (value) => value == null ? 'Customer is required' : null,
                  decoration: const InputDecoration(labelText: 'Customer'),
                );
              }),
              TextFormField(
                controller: _orderDateController,
                decoration: const InputDecoration(labelText: 'Order Date', suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true, onTap: () => _pickDate(context, true),
              ),
              TextFormField(
                controller: _deliveryDateController,
                decoration: const InputDecoration(labelText: 'Delivery Date (Optional)', suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true, onTap: () => _pickDate(context, false),
              ),
              const SizedBox(height: 10),
              Text("Order Items", style: Theme.of(context).textTheme.titleMedium),
              ListView.builder(
                shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
                itemCount: _currentOrderItems.length,
                itemBuilder: (context, index) {
                  final item = _currentOrderItems[index];
                  final productName = Provider.of<OrderController>(context, listen:false).productIdToNameMap[item.productId] ?? 'Unknown Product';
                  return ListTile(
                    title: Text('$productName (ID: ${item.productId})'),
                    subtitle: Text('Qty: ${item.quantity} @ ${item.priceAtSale.toStringAsFixed(2)} each = ${item.itemTotal.toStringAsFixed(2)}'),
                    trailing: IconButton(icon: Icon(Icons.remove_circle_outline), onPressed: (){ setState(()=>_currentOrderItems.removeAt(index)); }),
                  );
                },
              ),
              ElevatedButton.icon(icon: Icon(Icons.add_shopping_cart), label: Text("Add Item"), onPressed: _showAddOrderItemDialog),
              const Divider(height: 30),
              if (widget.salesOrder != null) ...[
                _buildPaymentsSection(),
                const Divider(height: 30),
                _buildStatusAndCompletionSection(),
                const SizedBox(height: 20),
              ],
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.salesOrder == null ? 'Create Order' : 'Save Order Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
   @override
  void dispose() {
    _orderDateController.dispose();
    _deliveryDateController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }
}
