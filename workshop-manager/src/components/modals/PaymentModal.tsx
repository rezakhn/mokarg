import React, { useState, useEffect } from 'react';

interface PaymentModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (paymentData: { amount: number; paymentDate: string }) => void;
  orderTotal: number;
  amountPaid: number;
}

const PaymentModal: React.FC<PaymentModalProps> = ({ isOpen, onClose, onSave, orderTotal, amountPaid }) => {
  const remainingAmount = orderTotal - amountPaid;
  const [amount, setAmount] = useState(remainingAmount);
  const [paymentDate, setPaymentDate] = useState(new Date().toISOString().split('T')[0]);

  useEffect(() => {
    if (isOpen) {
      setAmount(orderTotal - amountPaid);
      setPaymentDate(new Date().toISOString().split('T')[0]);
    }
  }, [isOpen, orderTotal, amountPaid]);

  if (!isOpen) return null;

  const handleSave = () => {
    const paymentAmount = Number(amount);
    if (isNaN(paymentAmount) || paymentAmount <= 0) {
        alert('Please enter a valid payment amount.');
        return;
    }
    onSave({ amount: paymentAmount, paymentDate });
  };

  return (
    <div className="modal-backdrop">
      <div className="modal">
        <h2>Log a Payment</h2>
        <p>Order Total: ${orderTotal.toFixed(2)}</p>
        <p>Amount Paid: ${amountPaid.toFixed(2)}</p>
        <p><strong>Amount Due: ${remainingAmount.toFixed(2)}</strong></p>
        <hr />
        <div className="modal-content">
          <div className="form-group">
            <label>Payment Amount</label>
            <input type="number" value={amount} onChange={e => setAmount(Number(e.target.value))} />
          </div>
          <div className="form-group">
            <label>Payment Date</label>
            <input type="date" value={paymentDate} onChange={e => setPaymentDate(e.target.value)} />
          </div>
        </div>
        <div className="modal-actions">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={handleSave}>Save Payment</button>
        </div>
      </div>
    </div>
  );
};

export default PaymentModal;
