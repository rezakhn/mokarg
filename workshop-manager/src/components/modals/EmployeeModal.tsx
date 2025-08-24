import React, { useState, useEffect } from 'react';
import { Employee } from '../../types';

interface EmployeeModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (employee: Omit<Employee, 'id'>) => void;
  employee?: Employee | null;
}

const EmployeeModal: React.FC<EmployeeModalProps> = ({ isOpen, onClose, onSave, employee }) => {
  const [name, setName] = useState('');
  const [paymentType, setPaymentType] = useState<'daily' | 'hourly'>('daily');
  const [paymentRate, setPaymentRate] = useState('');

  useEffect(() => {
    if (isOpen && employee) {
      setName(employee.name);
      setPaymentType(employee.paymentType);
      setPaymentRate(String(employee.paymentRate));
    } else {
      setName('');
      setPaymentType('daily');
      setPaymentRate('');
    }
  }, [isOpen, employee]);

  if (!isOpen) {
    return null;
  }

  const handleSave = () => {
    const rate = parseFloat(paymentRate);
    if (name && !isNaN(rate)) {
      onSave({ name, paymentType, paymentRate: rate });
    } else {
      alert('Please fill in all fields correctly.');
    }
  };

  return (
    <div className="modal-backdrop">
      <div className="modal">
        <h2>{employee ? 'Edit Employee' : 'Add New Employee'}</h2>
        <div className="modal-content">
          <div className="form-group">
            <label>Name</label>
            <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Payment Type</label>
            <select value={paymentType} onChange={(e) => setPaymentType(e.target.value as any)}>
              <option value="daily">Daily</option>
              <option value="hourly">Hourly</option>
            </select>
          </div>
          <div className="form-group">
            <label>Payment Rate</label>
            <input type="number" value={paymentRate} onChange={(e) => setPaymentRate(e.target.value)} />
          </div>
        </div>
        <div className="modal-actions">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={handleSave}>Save Employee</button>
        </div>
      </div>
    </div>
  );
};

export default EmployeeModal;
