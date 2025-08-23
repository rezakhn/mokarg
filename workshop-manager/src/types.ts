export interface Contact {
  id?: number;
  name: string;
  type: 'customer' | 'supplier';
  phone?: string;
  address?: string;
  notes?: string;
  created_at?: string;
  updated_at?: string;
}

export interface Employee {
  id?: number;
  name: string;
  paymentType: 'daily' | 'hourly';
  paymentRate: number;
  created_at?: string;
  updated_at?: string;
}

// This will evolve as we add more features
export interface InventoryItem {
  id?: number;
  name: string;
  quantity: number;
  averageCost: number;
  stockThreshold?: number;
  created_at?: string;
  updated_at?: string;
}

export interface Purchase {
  id?: number;
  contactId: number;
  purchaseDate: string;
  totalValue: number;
  items: PurchaseItem[]; // Not in DB table, but useful for frontend
  created_at?: string;
  updated_at?: string;
}

export interface PurchaseItem {
  id?: number;
  purchaseId: number;
  inventoryItemId: number;
  quantity: number;
  unitCost: number;
}

// Type for a new purchase item coming from the UI, which has a name instead of an ID
export interface NewPurchaseItem {
  name: string;
  quantity: number;
  unitCost: number;
}

export interface Part {
  id?: number;
  name: string;
  type: 'raw' | 'assembled';
  inventoryItemId?: number;
  recipe?: PartRecipe[]; // For assembled parts
}

export interface PartRecipe {
  id?: number;
  assembledPartId: number;
  componentPartId: number;
  quantity: number;
}

export interface Product {
  id?: number;
  name: string;
  salePrice: number;
  inventoryItemId?: number;
  recipe?: PartRecipe[]; // Recipe to make the product
}

export interface AssemblyOrder {
  id?: number;
  partId: number;
  quantity: number;
  status: 'pending' | 'fulfilled';
}

export interface SalesOrder {
  id?: number;
  contactId: number;
  orderDate: string;
  totalValue: number;
  paidAmount: number;
  fulfillmentStatus: 'pending' | 'fulfilled';
  paymentStatus: 'unpaid' | 'partially_paid' | 'paid';
  deliveryStatus: 'undelivered' | 'delivered';
  items: SalesOrderItem[];
}

export interface SalesOrderItem {
    id?: number;
    salesOrderId: number;
    productId: number;
    quantity: number;
    unitPrice: number;
}

export interface Payment {
    id?: number;
    salesOrderId: number;
    amount: number;
    paymentDate: string;
}

export interface Expense {
    id?: number;
    description: string;
    amount: number;
    expenseDate: string;
}

export interface AppState {
  contacts: Contact[];
  employees: Employee[];
  inventory: InventoryItem[];
  purchases: Purchase[];
  parts: Part[];
  products: Product[];
  assemblyOrders: AssemblyOrder[];
  salesOrders: SalesOrder[];
  expenses: Expense[];
}
