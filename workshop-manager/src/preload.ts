import { contextBridge, ipcRenderer } from 'electron';
import { Contact, Employee, InventoryItem, NewPurchaseItem, Purchase } from './types';

export const dbApi = {
  // Contact API
  getContacts: (): Promise<Contact[]> => ipcRenderer.invoke('get-contacts'),
  addContact: (contact: Omit<Contact, 'id'>): Promise<Contact> => ipcRenderer.invoke('add-contact', contact),
  updateContact: (id: number, updates: Partial<Contact>): Promise<Contact> => ipcRenderer.invoke('update-contact', id, updates),
  deleteContact: (id: number): Promise<void> => ipcRenderer.invoke('delete-contact', id),

  // Employee API
  getEmployees: (): Promise<Employee[]> => ipcRenderer.invoke('get-employees'),
  addEmployee: (employee: Omit<Employee, 'id'>): Promise<Employee> => ipcRenderer.invoke('add-employee', employee),
  updateEmployee: (id: number, updates: Partial<Employee>): Promise<Employee> => ipcRenderer.invoke('update-employee', id, updates),
  deleteEmployee: (id: number): Promise<void> => ipcRenderer.invoke('delete-employee', id),

  // Inventory & Purchase API
  getInventoryItems: (): Promise<InventoryItem[]> => ipcRenderer.invoke('get-inventory-items'),
  getPurchases: (): Promise<Purchase[]> => ipcRenderer.invoke('get-purchases'),
  addPurchase: (purchaseData: { contactId: number; purchaseDate: string; items: NewPurchaseItem[] }): Promise<Purchase> => ipcRenderer.invoke('add-purchase', purchaseData),
  getSuppliers: (): Promise<Contact[]> => ipcRenderer.invoke('get-suppliers'),
  getCustomers: (): Promise<Contact[]> => ipcRenderer.invoke('get-customers'),

  // Production API
  getParts: (): Promise<Part[]> => ipcRenderer.invoke('get-parts'),
  addPart: (partData: Omit<Part, 'id'>): Promise<Part> => ipcRenderer.invoke('add-part', partData),
  getProducts: (): Promise<Product[]> => ipcRenderer.invoke('get-products'),
  addProduct: (productData: Omit<Product, 'id'>): Promise<Product> => ipcRenderer.invoke('add-product', productData),
  getAssemblyOrders: (): Promise<any[]> => ipcRenderer.invoke('get-assembly-orders'),
  fulfillAssemblyOrder: (orderId: number): Promise<void> => ipcRenderer.invoke('fulfill-assembly-order', orderId),

  // Sales API
  getSalesOrders: (): Promise<SalesOrder[]> => ipcRenderer.invoke('get-sales-orders'),
  addSalesOrder: (orderData: Omit<SalesOrder, 'id' | 'paidAmount' | 'fulfillmentStatus' | 'paymentStatus' | 'deliveryStatus'>): Promise<SalesOrder> => ipcRenderer.invoke('add-sales-order', orderData),
  fulfillSalesOrder: (orderId: number): Promise<void> => ipcRenderer.invoke('fulfill-sales-order', orderId),
  addPayment: (paymentData: { salesOrderId: number; amount: number; paymentDate: string }): Promise<void> => ipcRenderer.invoke('add-payment', paymentData),

  // Dashboard API
  getDashboardStats: (): Promise<{ employeeCount: number; pendingOrders: number; totalUnpaid: number; lowStockItems: InventoryItem[] }> => ipcRenderer.invoke('get-dashboard-stats'),

  // Financials API
  getExpenses: (): Promise<Expense[]> => ipcRenderer.invoke('get-expenses'),
  addExpense: (expenseData: Omit<Expense, 'id'>): Promise<Expense> => ipcRenderer.invoke('add-expense', expenseData),
  getProfitAndLoss: (args: { startDate: string; endDate: string }): Promise<any> => ipcRenderer.invoke('get-profit-and-loss', args),
};

contextBridge.exposeInMainWorld('dbApi', dbApi);

// We also need to declare the type of our API on the window object
// for TypeScript to recognize it in the renderer process.
declare global {
  interface Window {
    dbApi: typeof dbApi;
  }
}
