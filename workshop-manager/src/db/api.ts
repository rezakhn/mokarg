import db from './index';
import { Contact } from '../types';

export const getContacts = (): Promise<Contact[]> => {
  return db('contacts').select('*');
};

export const getSuppliers = (): Promise<Contact[]> => {
  return db('contacts').where({ type: 'supplier' }).select('*');
};

export const getCustomers = (): Promise<Contact[]> => {
    return db('contacts').where({ type: 'customer' }).select('*');
};

export const addContact = async (contact: Omit<Contact, 'id'>): Promise<Contact> => {
  const [newContact] = await db('contacts').insert(contact).returning('*');
  return newContact;
};

export const updateContact = async (id: number, updates: Partial<Contact>): Promise<Contact> => {
  const [updatedContact] = await db('contacts').where({ id }).update(updates).returning('*');
  return updatedContact;
};

export const deleteContact = (id: number): Promise<void> => {
  return db('contacts').where({ id }).del();
};

// --- Employee Functions ---

import { Employee } from '../types';

export const getEmployees = (): Promise<Employee[]> => {
  return db('employees').select('*');
};

export const addEmployee = async (employee: Omit<Employee, 'id'>): Promise<Employee> => {
  const [newEmployee] = await db('employees').insert(employee).returning('*');
  return newEmployee;
};

export const updateEmployee = async (id: number, updates: Partial<Employee>): Promise<Employee> => {
  const [updatedEmployee] = await db('employees').where({ id }).update(updates).returning('*');
  return updatedEmployee;
};

export const deleteEmployee = (id: number): Promise<void> => {
  return db('employees').where({ id }).del();
};

// --- Inventory and Purchase Functions ---

import { InventoryItem, NewPurchaseItem, Purchase, PurchaseItem } from '../types';

export const getInventoryItems = (): Promise<InventoryItem[]> => {
  return db('inventory_items').select('*').orderBy('name');
};

export const getPurchases = async (): Promise<Purchase[]> => {
  const purchases = await db('purchases').select('*').orderBy('purchaseDate', 'desc');
  for (const purchase of purchases) {
    purchase.items = await db('purchase_items').where({ purchaseId: purchase.id });
  }
  return purchases;
};

export const addPurchase = async (purchaseData: {
  contactId: number;
  purchaseDate: string;
  items: NewPurchaseItem[];
}): Promise<Purchase> => {
  return db.transaction(async (trx) => {
    // 1. Insert the main purchase record
    const { contactId, purchaseDate, items } = purchaseData;
    let totalValue = 0;
    items.forEach(item => totalValue += item.quantity * item.unitCost);

    const [newPurchase] = await trx('purchases').insert({
      contactId,
      purchaseDate,
      totalValue,
    }).returning('*');

    // 2. Handle each item in the purchase
    for (const item of items) {
      // a. Find or create the inventory item
      let inventoryItem = await trx('inventory_items').where({ name: item.name }).first();
      if (!inventoryItem) {
        [inventoryItem] = await trx('inventory_items').insert({ name: item.name }).returning('*');
      }

      // b. Insert into purchase_items join table
      await trx('purchase_items').insert({
        purchaseId: newPurchase.id,
        inventoryItemId: inventoryItem.id,
        quantity: item.quantity,
        unitCost: item.unitCost,
      });

      // c. Update inventory quantity and average cost
      const oldQuantity = inventoryItem.quantity;
      const oldAvgCost = inventoryItem.averageCost;
      const newQuantity = item.quantity;
      const newCost = item.unitCost;

      const totalQuantity = oldQuantity + newQuantity;
      const newAvgCost = totalQuantity > 0
        ? ((oldQuantity * oldAvgCost) + (newQuantity * newCost)) / totalQuantity
        : newCost;

      await trx('inventory_items').where({ id: inventoryItem.id }).update({
        quantity: totalQuantity,
        averageCost: newAvgCost,
      });
    }

    newPurchase.items = await trx('purchase_items').where({ purchaseId: newPurchase.id });
    return newPurchase;
  });
};

// --- Production Functions ---
import { Part, Product } from '../types';

export const getParts = (): Promise<Part[]> => {
  return db('parts').select('*');
};

export const getProducts = (): Promise<Product[]> => {
  return db('products').select('*');
};

export const getAssemblyOrders = (): Promise<any[]> => {
    return db('assembly_orders')
        .join('parts', 'assembly_orders.partId', '=', 'parts.id')
        .select('assembly_orders.*', 'parts.name as partName');
};

export const addPart = async (partData: Omit<Part, 'id'>): Promise<Part> => {
  return db.transaction(async (trx) => {
    const { name, type, recipe } = partData;

    // Create the part
    const [newPart] = await trx('parts').insert({ name, type }).returning('*');

    // If it's an assembled part with a recipe, save the recipe
    if (type === 'assembled' && recipe && recipe.length > 0) {
      const recipeToInsert = recipe.map(r => ({
        assembledPartId: newPart.id,
        componentPartId: r.componentPartId,
        quantity: r.quantity,
      }));
      await trx('part_recipes').insert(recipeToInsert);
    }

    return newPart;
  });
};

export const addProduct = async (productData: Omit<Product, 'id'>): Promise<Product> => {
    return db.transaction(async (trx) => {
        const { name, salePrice, recipe } = productData;

        const [newProduct] = await trx('products').insert({ name, salePrice }).returning('*');

        if (recipe && recipe.length > 0) {
            const recipeToInsert = recipe.map(r => ({
                productId: newProduct.id,
                partId: r.componentPartId, // Assuming the recipe passed in uses componentPartId
                quantity: r.quantity,
            }));
            await trx('product_recipes').insert(recipeToInsert);
        }
        return newProduct;
    });
};

// --- Sales Functions ---
import { SalesOrder, SalesOrderItem } from '../types';

// --- Dashboard Functions ---
export const getDashboardStats = async () => {
    const employeeCount = await db('employees').count({ count: 'id' }).first();
    const pendingOrders = await db('sales_orders').whereNot({ fulfillmentStatus: 'fulfilled' }).count({ count: 'id' }).first();
    const totalUnpaid = await db('sales_orders').whereNot({ paymentStatus: 'paid' }).sum({ sum: 'totalValue' }).first();
    const totalPaid = await db('sales_orders').whereNot({ paymentStatus: 'paid' }).sum({ sum: 'paidAmount' }).first();
    const lowStockItems = await db('inventory_items').whereRaw('quantity < stockThreshold');

    return {
        employeeCount: employeeCount.count,
        pendingOrders: pendingOrders.count,
        totalUnpaid: (totalUnpaid.sum || 0) - (totalPaid.sum || 0),
        lowStockItems,
    };
};


export const getSalesOrders = async (): Promise<SalesOrder[]> => {
    const orders = await db('sales_orders').select('*').orderBy('orderDate', 'desc');
    for (const order of orders) {
        order.items = await db('sales_order_items').where({ salesOrderId: order.id });
    }
    return orders;
};

export const addSalesOrder = async (orderData: Omit<SalesOrder, 'id' | 'paidAmount' | 'fulfillmentStatus' | 'paymentStatus' | 'deliveryStatus'>): Promise<SalesOrder> => {
    return db.transaction(async (trx) => {
        const { contactId, orderDate, items } = orderData;
        let totalValue = 0;
        items.forEach(item => totalValue += item.quantity * item.unitPrice);

        const [newOrder] = await trx('sales_orders').insert({
            contactId,
            orderDate,
            totalValue,
        }).returning('*');

        const itemsToInsert = items.map(item => ({
            salesOrderId: newOrder.id,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
        }));

        await trx('sales_order_items').insert(itemsToInsert);

        newOrder.items = itemsToInsert;
        return newOrder;
    });
};

export const fulfillSalesOrder = async (orderId: number): Promise<void> => {
    return db.transaction(async (trx) => {
        const orderItems = await trx('sales_order_items').where({ salesOrderId: orderId });
        let totalCostOfGoodsSold = 0;

        for (const item of orderItems) {
            // This assumes a product directly maps to an inventory item.
            const product = await trx('products').where({ id: item.productId }).first();
            if (!product || !product.inventoryItemId) {
                throw new Error(`Product ID ${item.productId} not found or not linked to inventory.`);
            }

            const inventoryItem = await trx('inventory_items').where({ id: product.inventoryItemId }).first();
            if (inventoryItem.quantity < item.quantity) {
                throw new Error(`Not enough stock for item ${inventoryItem.name}. Required: ${item.quantity}, Available: ${inventoryItem.quantity}`);
            }

            // Add to COGS
            totalCostOfGoodsSold += inventoryItem.averageCost * item.quantity;

            await trx('inventory_items')
                .where({ id: product.inventoryItemId })
                .decrement('quantity', item.quantity);
        }

        await trx('sales_orders').where({ id: orderId }).update({
            fulfillmentStatus: 'fulfilled',
            costOfGoodsSold: totalCostOfGoodsSold,
        });
    });
};

export const addPayment = async (paymentData: { salesOrderId: number; amount: number; paymentDate: string }): Promise<void> => {
    return db.transaction(async (trx) => {
        const { salesOrderId, amount, paymentDate } = paymentData;

        // 1. Insert payment record
        await trx('payments').insert({ salesOrderId, amount, paymentDate });

        // 2. Update paidAmount on the sales order
        await trx('sales_orders').where({ id: salesOrderId }).increment('paidAmount', amount);

        // 3. Update paymentStatus
        const order = await trx('sales_orders').where({ id: salesOrderId }).first();
        let newStatus = 'partially_paid';
        if (order.paidAmount >= order.totalValue) {
            newStatus = 'paid';
        }

        await trx('sales_orders').where({ id: salesOrderId }).update({ paymentStatus: newStatus });
    });
};

export const fulfillAssemblyOrder = async (assemblyOrderId: number): Promise<void> => {
    return db.transaction(async (trx) => {
        const assemblyOrder = await trx('assembly_orders').where({ id: assemblyOrderId }).first();
        if (!assemblyOrder) throw new Error('Assembly order not found.');
        if (assemblyOrder.status === 'fulfilled') throw new Error('Order already fulfilled.');

        const recipeItems = await trx('part_recipes').where({ assembledPartId: assemblyOrder.partId });
        if (!recipeItems || recipeItems.length === 0) throw new Error('No recipe found for this part.');

        // Check stock for all components
        for (const recipeItem of recipeItems) {
            const componentPart = await trx('parts').where({ id: recipeItem.componentPartId }).first();
            if (!componentPart.inventoryItemId) throw new Error(`Component part ${componentPart.name} is not an inventory item.`);

            const inventoryItem = await trx('inventory_items').where({ id: componentPart.inventoryItemId }).first();
            const requiredQty = recipeItem.quantity * assemblyOrder.quantity;
            if (inventoryItem.quantity < requiredQty) {
                throw new Error(`Not enough stock for ${inventoryItem.name}. Required: ${requiredQty}, Available: ${inventoryItem.quantity}`);
            }
        }

        // Deduct components and add final part
        let totalCostOfComponents = 0;
        for (const recipeItem of recipeItems) {
            const componentPart = await trx('parts').where({ id: recipeItem.componentPartId }).first();
            const inventoryItem = await trx('inventory_items').where({ id: componentPart.inventoryItemId }).first();
            const requiredQty = recipeItem.quantity * assemblyOrder.quantity;

            totalCostOfComponents += inventoryItem.averageCost * requiredQty;

            await trx('inventory_items').where({ id: componentPart.inventoryItemId }).decrement('quantity', requiredQty);
        }

        const finalPart = await trx('parts').where({ id: assemblyOrder.partId }).first();
        if (!finalPart.inventoryItemId) throw new Error('Final assembled part is not linked to an inventory item.');

        // Update final part quantity and cost
        const finalInventoryItem = await trx('inventory_items').where({ id: finalPart.inventoryItemId }).first();
        const newCostOfAssembledPart = totalCostOfComponents / assemblyOrder.quantity;
        const newAvgCost =
            ((finalInventoryItem.quantity * finalInventoryItem.averageCost) + (assemblyOrder.quantity * newCostOfAssembledPart))
            / (finalInventoryItem.quantity + assemblyOrder.quantity);

        await trx('inventory_items').where({ id: finalPart.inventoryItemId }).update({
            quantity: trx.raw(`quantity + ${assemblyOrder.quantity}`),
            averageCost: newAvgCost,
        });

        // Mark order as fulfilled
        await trx('assembly_orders').where({ id: assemblyOrderId }).update({ status: 'fulfilled' });
    });
};

// --- Financials Functions ---
import { Expense } from '../types';

export const getExpenses = (): Promise<Expense[]> => {
    return db('expenses').select('*').orderBy('expenseDate', 'desc');
};

export const addExpense = (expenseData: Omit<Expense, 'id'>): Promise<Expense> => {
    return db('expenses').insert(expenseData).returning('*');
};

export const getProfitAndLoss = async (startDate: string, endDate: string) => {
    const revenueResult = await db('sales_orders')
        .whereBetween('orderDate', [startDate, endDate])
        .sum({ total: 'totalValue' })
        .first();

    const cogsResult = await db('sales_orders')
        .whereBetween('orderDate', [startDate, endDate])
        .whereNotNull('costOfGoodsSold')
        .sum({ total: 'costOfGoodsSold' })
        .first();

    const expensesResult = await db('expenses')
        .whereBetween('expenseDate', [startDate, endDate])
        .sum({ total: 'amount' })
        .first();

    const revenue = revenueResult.total || 0;
    const cogs = cogsResult.total || 0;
    const expenses = expensesResult.total || 0;
    const grossProfit = revenue - cogs;
    const netProfit = grossProfit - expenses;

    return {
        revenue,
        cogs,
        grossProfit,
        expenses,
        netProfit,
        startDate,
        endDate,
    };
};
