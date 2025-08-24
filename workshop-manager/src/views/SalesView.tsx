import React, { useEffect, useState } from 'react';
import { SalesOrder, SalesOrderItem } from '../types';
import SalesOrderModal from '../components/modals/SalesOrderModal';
import PaymentModal from '../components/modals/PaymentModal';

const SalesView = () => {
  const [orders, setOrders] = useState<SalesOrder[]>([]);
  const [isOrderModalOpen, setIsOrderModalOpen] = useState(false);
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [payingForOrder, setPayingForOrder] = useState<SalesOrder | null>(null);

  const fetchData = async () => {
    const fetchedOrders = await window.dbApi.getSalesOrders();
    setOrders(fetchedOrders);
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleSaveOrder = async (orderData: { contactId: number; orderDate: string; items: Omit<SalesOrderItem, 'id' | 'salesOrderId'>[] }) => {
    await window.dbApi.addSalesOrder(orderData);
    fetchData();
    setIsOrderModalOpen(false);
  };

  const handleFulfill = async (orderId: number) => {
    try {
      await window.dbApi.fulfillSalesOrder(orderId);
      fetchData();
    } catch (error) {
      alert(`Error fulfilling order: ${error.message}`);
    }
  };

  const handleOpenPaymentModal = (order: SalesOrder) => {
    setPayingForOrder(order);
    setIsPaymentModalOpen(true);
  };

  const handleSavePayment = async (paymentData: { amount: number; paymentDate: string }) => {
    if (!payingForOrder) return;
    await window.dbApi.addPayment({ ...paymentData, salesOrderId: payingForOrder.id });
    fetchData();
    setIsPaymentModalOpen(false);
    setPayingForOrder(null);
  };

  const getStatusChip = (status: string) => {
    const statusClass = `status-chip status-${status.replace('_', '-')}`;
    return <span className={statusClass}>{status.replace('_', ' ')}</span>;
  };

  return (
    <>
      <div className="view-container">
        <div className="view-header">
          <h1>Sales Orders</h1>
          <button className="btn btn-primary" onClick={() => setIsOrderModalOpen(true)}>Add Sales Order</button>
        </div>
        <div className="card">
          <table className="data-table">
            <thead>
              <tr>
                <th>Order ID</th>
                <th>Customer ID</th>
                <th>Date</th>
                <th>Total</th>
                <th>Paid</th>
                <th>Fulfillment</th>
                <th>Payment</th>
                <th>Delivery</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((order) => (
                <tr key={order.id}>
                  <td>#{order.id}</td>
                  <td>{order.contactId}</td>
                  <td>{new Date(order.orderDate).toLocaleDateString()}</td>
                  <td>${order.totalValue.toFixed(2)}</td>
                  <td>${order.paidAmount.toFixed(2)}</td>
                  <td>{getStatusChip(order.fulfillmentStatus)}</td>
                  <td>{getStatusChip(order.paymentStatus)}</td>
                  <td>{getStatusChip(order.deliveryStatus)}</td>
                  <td>
                    {order.fulfillmentStatus === 'pending' && (
                      <button className="btn btn-sm btn-secondary" onClick={() => handleFulfill(order.id)}>Fulfill</button>
                    )}
                    {order.paymentStatus !== 'paid' && (
                      <button className="btn btn-sm btn-secondary" onClick={() => handleOpenPaymentModal(order)}>Log Payment</button>
                    )}
                  </td>
                </tr>
              ))}
              {orders.length === 0 && (
                <tr>
                  <td colSpan={7}>No sales orders found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
      <SalesOrderModal
        isOpen={isOrderModalOpen}
        onClose={() => setIsOrderModalOpen(false)}
        onSave={handleSaveOrder}
      />
      {payingForOrder && (
        <PaymentModal
          isOpen={isPaymentModalOpen}
          onClose={() => setIsPaymentModalOpen(false)}
          onSave={handleSavePayment}
          orderTotal={payingForOrder.totalValue}
          amountPaid={payingForOrder.paidAmount}
        />
      )}
    </>
  );
};

export default SalesView;
