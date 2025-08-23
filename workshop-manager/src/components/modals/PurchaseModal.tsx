import React, { useState, useEffect } from 'react';
import { Contact, NewPurchaseItem } from '../../types';

interface PurchaseModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (purchaseData: { contactId: number; purchaseDate: string; items: NewPurchaseItem[] }) => void;
}

const PurchaseModal: React.FC<PurchaseModalProps> = ({ isOpen, onClose, onSave }) => {
  const [suppliers, setSuppliers] = useState<Contact[]>([]);
  const [selectedSupplier, setSelectedSupplier] = useState<string>('');
  const [purchaseDate, setPurchaseDate] = useState(new Date().toISOString().split('T')[0]);
  const [items, setItems] = useState<NewPurchaseItem[]>([{ name: '', quantity: 1, unitCost: 0 }]);

  useEffect(() => {
    if (isOpen) {
      const fetchSuppliers = async () => {
        const fetchedSuppliers = await window.dbApi.getSuppliers();
        setSuppliers(fetchedSuppliers);
        if (fetchedSuppliers.length > 0) {
          setSelectedSupplier(String(fetchedSuppliers[0].id));
        }
      };
      fetchSuppliers();
      // Reset form on open
      setPurchaseDate(new Date().toISOString().split('T')[0]);
      setItems([{ name: '', quantity: 1, unitCost: 0 }]);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleItemChange = (index: number, field: keyof NewPurchaseItem, value: string | number) => {
    const newItems = [...items];
    (newItems[index] as any)[field] = value;
    setItems(newItems);
  };

  const addItem = () => {
    setItems([...items, { name: '', quantity: 1, unitCost: 0 }]);
  };

  const removeItem = (index: number) => {
    const newItems = items.filter((_, i) => i !== index);
    setItems(newItems);
  };

  const handleSave = () => {
    const finalItems = items.filter(item => item.name && item.quantity > 0);
    if (!selectedSupplier || finalItems.length === 0) {
      alert('Please select a supplier and add at least one valid item.');
      return;
    }
    onSave({
      contactId: Number(selectedSupplier),
      purchaseDate,
      items: finalItems,
    });
  };

  return (
    <div className="modal-backdrop">
      <div className="modal" style={{ maxWidth: '700px' }}>
        <h2>Add New Purchase</h2>
        <div className="modal-content">
          <div className="form-group">
            <label>Supplier</label>
            <select value={selectedSupplier} onChange={e => setSelectedSupplier(e.target.value)}>
              {suppliers.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          </div>
          <div className="form-group">
            <label>Purchase Date</label>
            <input type="date" value={purchaseDate} onChange={e => setPurchaseDate(e.target.value)} />
          </div>
          <hr />
          <h3>Items</h3>
          {items.map((item, index) => (
            <div key={index} className="purchase-item-row">
              <input type="text" placeholder="Item Name" value={item.name} onChange={e => handleItemChange(index, 'name', e.target.value)} />
              <input type="number" placeholder="Quantity" value={item.quantity} onChange={e => handleItemChange(index, 'quantity', Number(e.target.value))} />
              <input type="number" placeholder="Unit Cost" value={item.unitCost} onChange={e => handleItemChange(index, 'unitCost', Number(e.target.value))} />
              <button className="btn btn-sm btn-danger" onClick={() => removeItem(index)}>X</button>
            </div>
          ))}
          <button className="btn btn-secondary" onClick={addItem}>Add Item</button>
        </div>
        <div className="modal-actions">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={handleSave}>Save Purchase</button>
        </div>
      </div>
    </div>
  );
};

export default PurchaseModal;
