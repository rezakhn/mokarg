import React, { useState, useEffect } from 'react';
import { Expense } from '../../types';

interface ExpenseModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (expenseData: Omit<Expense, 'id'>) => void;
}

const ExpenseModal: React.FC<ExpenseModalProps> = ({ isOpen, onClose, onSave }) => {
  const [description, setDescription] = useState('');
  const [amount, setAmount] = useState('');
  const [expenseDate, setExpenseDate] = useState(new Date().toISOString().split('T')[0]);

  useEffect(() => {
    if (isOpen) {
      setDescription('');
      setAmount('');
      setExpenseDate(new Date().toISOString().split('T')[0]);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleSave = () => {
    const expenseAmount = parseFloat(amount);
    if (!description || isNaN(expenseAmount) || expenseAmount <= 0) {
      alert('Please fill in all fields correctly.');
      return;
    }
    onSave({ description, amount: expenseAmount, expenseDate });
  };

  return (
    <div className="modal-backdrop">
      <div className="modal">
        <h2>Add New Expense</h2>
        <div className="modal-content">
          <div className="form-group">
            <label>Description</label>
            <input type="text" value={description} onChange={e => setDescription(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Amount</label>
            <input type="number" value={amount} onChange={e => setAmount(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Expense Date</label>
            <input type="date" value={expenseDate} onChange={e => setExpenseDate(e.target.value)} />
          </div>
        </div>
        <div className="modal-actions">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={handleSave}>Save Expense</button>
        </div>
      </div>
    </div>
  );
};

export default ExpenseModal;
