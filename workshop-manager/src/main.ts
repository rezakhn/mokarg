import { app, BrowserWindow, ipcMain } from 'electron';
import path from 'node:path';
import started from 'electron-squirrel-startup';
import { runMigrations } from './db';
import * as api from './db/api';

// Handle creating/removing shortcuts on Windows when installing/uninstalling.
if (started) {
  app.quit();
}

const createWindow = () => {
  // Create the browser window.
  const mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
    },
  });

  // and load the index.html of the app.
  if (MAIN_WINDOW_VITE_DEV_SERVER_URL) {
    mainWindow.loadURL(MAIN_WINDOW_VITE_DEV_SERVER_URL);
  } else {
    mainWindow.loadFile(path.join(__dirname, '..', 'renderer', 'index.html'));
  }

  // Open the DevTools.
  mainWindow.webContents.openDevTools();
};

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(async () => {
  await runMigrations();

  // Setup IPC Handlers
  ipcMain.handle('get-contacts', () => api.getContacts());
  ipcMain.handle('add-contact', (_, contact) => api.addContact(contact));
  ipcMain.handle('update-contact', (_, id, updates) => api.updateContact(id, updates));
  ipcMain.handle('delete-contact', (_, id) => api.deleteContact(id));

  // Employee IPC Handlers
  ipcMain.handle('get-employees', () => api.getEmployees());
  ipcMain.handle('add-employee', (_, employee) => api.addEmployee(employee));
  ipcMain.handle('update-employee', (_, id, updates) => api.updateEmployee(id, updates));
  ipcMain.handle('delete-employee', (_, id) => api.deleteEmployee(id));

  // Inventory & Purchase IPC Handlers
  ipcMain.handle('get-inventory-items', () => api.getInventoryItems());
  ipcMain.handle('get-purchases', () => api.getPurchases());
  ipcMain.handle('add-purchase', (_, purchaseData) => api.addPurchase(purchaseData));
  ipcMain.handle('get-suppliers', () => api.getSuppliers());
  ipcMain.handle('get-customers', () => api.getCustomers());

  // Production IPC Handlers
  ipcMain.handle('get-parts', () => api.getParts());
  ipcMain.handle('add-part', (_, partData) => api.addPart(partData));
  ipcMain.handle('get-products', () => api.getProducts());
  ipcMain.handle('add-product', (_, productData) => api.addProduct(productData));
  ipcMain.handle('get-assembly-orders', () => api.getAssemblyOrders());
  ipcMain.handle('fulfill-assembly-order', (_, orderId) => api.fulfillAssemblyOrder(orderId));

  // Sales IPC Handlers
  ipcMain.handle('get-sales-orders', () => api.getSalesOrders());
  ipcMain.handle('add-sales-order', (_, orderData) => api.addSalesOrder(orderData));
  ipcMain.handle('fulfill-sales-order', (_, orderId) => api.fulfillSalesOrder(orderId));
  ipcMain.handle('add-payment', (_, paymentData) => api.addPayment(paymentData));

  // Dashboard IPC Handlers
  ipcMain.handle('get-dashboard-stats', () => api.getDashboardStats());

  // Financials IPC Handlers
  ipcMain.handle('get-expenses', () => api.getExpenses());
  ipcMain.handle('add-expense', (_, expenseData) => api.addExpense(expenseData));
  ipcMain.handle('get-profit-and-loss', (_, { startDate, endDate }) => api.getProfitAndLoss(startDate, endDate));

  createWindow();
});

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and import them here.
