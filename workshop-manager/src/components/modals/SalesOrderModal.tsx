import React, { useState, useEffect } from 'react';
import { Contact, Product, SalesOrderItem } from '../../types';

interface SalesOrderModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (orderData: { contactId: number; orderDate: string; items: Omit<SalesOrderItem, 'id' | 'salesOrderId'>[] }) => void;
}

const SalesOrderModal: React.FC<SalesOrderModalProps> = ({ isOpen, onClose, onSave }) => {
  const [customers, setCustomers] = useState<Contact[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [selectedCustomer, setSelectedCustomer] = useState<string>('');
  const [orderDate, setOrderDate] = useState(new Date().toISOString().split('T')[0]);
  const [items, setItems] = useState<Omit<SalesOrderItem, 'id' | 'salesOrderId'>[]>([{ productId: 0, quantity: 1, unitPrice: 0 }]);

  useEffect(() => {
    if (isOpen) {
      const fetchData = async () => {
        const [fetchedCustomers, fetchedProducts] = await Promise.all([
          window.dbApi.getCustomers(),
          window.dbApi.getProducts(),
        ]);
        setCustomers(fetchedCustomers);
        setProducts(fetchedProducts);
        if (fetchedCustomers.length > 0) setSelectedCustomer(String(fetchedCustomers[0].id));
        if (fetchedProducts.length > 0) {
            setItems([{ productId: fetchedProducts[0].id, quantity: 1, unitPrice: fetchedProducts[0].salePrice }]);
        } else {
            setItems([{ productId: 0, quantity: 1, unitPrice: 0 }])
        }
      };
      fetchData();
      setOrderDate(new Date().toISOString().split('T')[0]);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleItemChange = (index: number, field: keyof Omit<SalesOrderItem, 'id' | 'salesOrderId'>, value: string | number) => {
    const newItems = [...items];
    (newItems[index] as any)[field] = value;
    // If product changes, update the price
    if (field === 'productId') {
        const product = products.find(p => p.id === Number(value));
        if (product) {
            newItems[index].unitPrice = product.salePrice;
        }
    }
    setItems(newItems);
  };

  const addItem = () => {
    const firstProductId = products.length > 0 ? products[0].id : 0;
    const firstProductPrice = products.length > 0 ? products[0].salePrice : 0;
    setItems([...items, { productId: firstProductId, quantity: 1, unitPrice: firstProductPrice }]);
  };

  const removeItem = (index: number) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const handleSave = () => {
    const finalItems = items.filter(item => item.productId > 0 && item.quantity > 0);
    if (!selectedCustomer || finalItems.length === 0) {
      alert('Please select a customer and add at least one valid item.');
      return;
    }
    onSave({
      contactId: Number(selectedCustomer),
      orderDate,
      items: finalItems,
    });
  };

  return (
    <div className="modal-backdrop">
      <div className="modal" style={{ maxWidth: '700px' }}>
        <h2>Add New Sales Order</h2>
        <div className="modal-content">
          <div className="form-group">
            <label>Customer</label>
            <select value={selectedCustomer} onChange={e => setSelectedCustomer(e.target.value)}>
              {customers.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
          <div className="form-group">
            <label>Order Date</label>
            <input type="date" value={orderDate} onChange={e => setOrderDate(e.target.value)} />
          </div>
          <hr />
          <h3>Items</h3>
          {items.map((item, index) => (
            <div key={index} className="purchase-item-row">
              <select value={item.productId} onChange={e => handleItemChange(index, 'productId', Number(e.target.value))}>
                {products.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
              <input type="number" placeholder="Quantity" value={item.quantity} onChange={e => handleItemChange(index, 'quantity', Number(e.target.value))} />
              <input type="number" placeholder="Unit Price" value={item.unitPrice} onChange={e => handleItemChange(index, 'unitPrice', Number(e.target.value))} />
              <button className="btn btn-sm btn-danger" onClick={() => removeItem(index)}>X</button>
            </div>
          ))}
          <button className="btn btn-secondary" onClick={addItem}>Add Item</button>
        </div>
        <div className="modal-actions">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={handleSave}>Save Order</button>
        </div>
      </div>
    </div>
  );
};

export default SalesOrderModal;
