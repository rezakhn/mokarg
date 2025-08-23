import React, { useState, useEffect } from 'react';
import { Part } from '../../types';

interface PartModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (partData: Omit<Part, 'id'>) => void;
}

const PartModal: React.FC<PartModalProps> = ({ isOpen, onClose, onSave }) => {
  const [name, setName] = useState('');
  const [type, setType] = useState<'raw' | 'assembled'>('raw');

  useEffect(() => {
    if (isOpen) {
      setName('');
      setType('raw');
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleSave = () => {
    if (!name) {
      alert('Part name is required.');
      return;
    }
    // For now, only handles simple case. Recipe logic will be added later.
    onSave({ name, type });
  };

  return (
    <div className="modal-backdrop">
      <div className="modal">
        <h2>Add New Part</h2>
        <div className="modal-content">
          <div className="form-group">
            <label>Part Name</label>
            <input type="text" value={name} onChange={e => setName(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Part Type</label>
            <select value={type} onChange={e => setType(e.target.value as any)}>
              <option value="raw">Raw Material</option>
              <option value="assembled">Assembled</option>
            </select>
          </div>
          {/* Recipe builder will go here when type is 'assembled' */}
        </div>
        <div className="modal-actions">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={handleSave}>Save Part</button>
        </div>
      </div>
    </div>
  );
};

export default PartModal;
