import React, { useState } from 'react';
import { Contact } from '../../types';

interface ContactModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (contact: Omit<Contact, 'id'>) => void;
  contact?: Contact | null;
}

const ContactModal: React.FC<ContactModalProps> = ({ isOpen, onClose, onSave, contact }) => {
  const [name, setName] = useState('');
  const [type, setType] = useState<'customer' | 'supplier'>('customer');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [notes, setNotes] = useState('');

  // When the modal opens, populate the form if we are editing a contact
  React.useEffect(() => {
    if (isOpen && contact) {
      setName(contact.name);
      setType(contact.type);
      setPhone(contact.phone || '');
      setAddress(contact.address || '');
      setNotes(contact.notes || '');
    } else {
      // Reset form when opening for a new contact
      setName('');
      setType('customer');
      setPhone('');
      setAddress('');
      setNotes('');
    }
  }, [isOpen, contact]);

  if (!isOpen) {
    return null;
  }

  const handleSave = () => {
    onSave({ name, type, phone, address, notes });
  };

  return (
    <div className="modal-backdrop">
      <div className="modal">
        <h2>{contact ? 'Edit Contact' : 'Add New Contact'}</h2>
        <div className="modal-content">
          <div className="form-group">
            <label>Name</label>
            <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Type</label>
            <select value={type} onChange={(e) => setType(e.target.value as any)}>
              <option value="customer">Customer</option>
              <option value="supplier">Supplier</option>
            </select>
          </div>
          <div className="form-group">
            <label>Phone</label>
            <input type="text" value={phone} onChange={(e) => setPhone(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Address</label>
            <textarea value={address} onChange={(e) => setAddress(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Notes</label>
            <textarea value={notes} onChange={(e) => setNotes(e.target.value)} />
          </div>
        </div>
        <div className="modal-actions">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={handleSave}>Save Contact</button>
        </div>
      </div>
    </div>
  );
};

export default ContactModal;
