import React, { useEffect, useState } from 'react';
import { Contact } from '../types';
import ContactModal from '../components/modals/ContactModal';

const ContactsView = () => {
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingContact, setEditingContact] = useState<Contact | null>(null);

  const fetchContacts = async () => {
    const fetchedContacts = await window.dbApi.getContacts();
    setContacts(fetchedContacts);
  };

  useEffect(() => {
    fetchContacts();
  }, []);

  const handleAdd = () => {
    setEditingContact(null);
    setIsModalOpen(true);
  };

  const handleEdit = (contact: Contact) => {
    setEditingContact(contact);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this contact?')) {
      await window.dbApi.deleteContact(id);
      fetchContacts(); // Refresh the list
    }
  };

  const handleSave = async (contactData: Omit<Contact, 'id'>) => {
    if (editingContact) {
      // Update existing contact
      await window.dbApi.updateContact(editingContact.id, contactData);
    } else {
      // Add new contact
      await window.dbApi.addContact(contactData);
    }
    fetchContacts(); // Refresh the list
    setIsModalOpen(false); // Close the modal
  };

  return (
    <>
      <div className="view-container">
        <div className="view-header">
          <h1>Contacts</h1>
          <button className="btn btn-primary" onClick={handleAdd}>Add Contact</button>
        </div>
        <div className="card">
          <table className="data-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Type</th>
                <th>Phone</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {contacts.map((contact) => (
                <tr key={contact.id}>
                  <td>{contact.name}</td>
                  <td>{contact.type}</td>
                  <td>{contact.phone || '-'}</td>
                  <td>
                    <button className="btn btn-sm btn-secondary" onClick={() => handleEdit(contact)}>Edit</button>
                    <button className="btn btn-sm btn-danger" onClick={() => handleDelete(contact.id)}>Delete</button>
                  </td>
                </tr>
              ))}
              {contacts.length === 0 && (
                <tr>
                  <td colSpan={4}>No contacts found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
      <ContactModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSave={handleSave}
        contact={editingContact}
      />
    </>
  );
};

export default ContactsView;
