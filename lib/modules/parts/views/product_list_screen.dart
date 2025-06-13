import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/part_controller.dart';
import '../models/product.dart';
import 'product_edit_screen.dart';
import '../widgets/product_card.dart'; // Added import

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PartController>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductEditScreen()),
              ).then((_) {
                if (!mounted) return;
                Provider.of<PartController>(context, listen: false).fetchProducts();
              });
            },
          ),
        ],
      ),
      body: Consumer<PartController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null && controller.products.isEmpty) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }
          if (controller.products.isEmpty) {
            return const Center(child: Text('No products defined. Add one!'));
          }
          return ListView.builder(
            itemCount: controller.products.length,
            itemBuilder: (context, index) {
              final product = controller.products[index];
              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProductEditScreen(product: product)),
                  ).then((_) {
                    if (!mounted) return;
                    Provider.of<PartController>(context, listen: false).fetchProducts();
                  });
                },
                onDelete: () async {
                    final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: Text('Are you sure you want to delete product "${product.name}"?'),
                            actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                            ],
                        ),
                    );
                    if (!mounted) return; // Check after showDialog
                    if (confirm == true) {
                        await controller.deleteProduct(product.id!);
                        if (!mounted) return; // Check after await
                        if (controller.errorMessage != null) { // mounted is already checked
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${controller.errorMessage}')),
                            );
                        }
                    }
                }
              );
            },
          );
        },
      ),
    );
  }
}
