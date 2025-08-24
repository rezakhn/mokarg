import React, { useEffect, useState } from 'react';
import { InventoryItem, Purchase, NewPurchaseItem } from '../types';
import PurchaseModal from '../components/modals/PurchaseModal';

const InventoryView = () => {
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [purchases, setPurchases] = useState<Purchase[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const fetchData = async () => {
    const [fetchedInventory, fetchedPurchases] = await Promise.all([
      window.dbApi.getInventoryItems(),
      window.dbApi.getPurchases(),
    ]);
    setInventory(fetchedInventory);
    setPurchases(fetchedPurchases);
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleSavePurchase = async (purchaseData: { contactId: number; purchaseDate: string; items: NewPurchaseItem[] }) => {
    await window.dbApi.addPurchase(purchaseData);
    fetchData(); // Refresh all data
    setIsModalOpen(false);
  };

  return (
    <>
      <div className="view-container">
        <div className="view-header">
          <h1>Inventory & Purchases</h1>
          <button className="btn btn-primary" onClick={() => setIsModalOpen(true)}>Add Purchase</button>
        </div>

        {/* Inventory Status Card */}
        <div className="card">
          <h2>Inventory Status</h2>
          <table className="data-table">
            <thead>
              <tr>
                <th>Item Name</th>
                <th>Quantity</th>
                <th>Average Cost</th>
                <th>Stock Value</th>
              </tr>
            </thead>
            <tbody>
              {inventory.map((item) => (
                <tr key={item.id}>
                  <td>{item.name}</td>
                  <td>{item.quantity}</td>
                  <td>${item.averageCost.toFixed(2)}</td>
                  <td>${(item.quantity * item.averageCost).toFixed(2)}</td>
                </tr>
              ))}
              {inventory.length === 0 && (
                <tr>
                  <td colSpan={4}>No items in inventory.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Purchase History Card */}
        <div className="card">
          <h2>Purchase History</h2>
          <table className="data-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Supplier ID</th>
                <th>Total Value</th>
              </tr>
            </thead>
            <tbody>
              {purchases.map((purchase) => (
                <tr key={purchase.id}>
                  <td>{new Date(purchase.purchaseDate).toLocaleDateString()}</td>
                  <td>{purchase.contactId}</td>
                  <td>${purchase.totalValue.toFixed(2)}</td>
                </tr>
              ))}
              {purchases.length === 0 && (
                <tr>
                  <td colSpan={3}>No purchase history.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
      <PurchaseModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSave={handleSavePurchase}
      />
    </>
  );
};

export default InventoryView;
