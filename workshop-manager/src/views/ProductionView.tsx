import React, { useEffect, useState } from 'react';
import { Part, Product, AssemblyOrder } from '../types';
import PartModal from '../components/modals/PartModal';

const ProductionView = () => {
  const [parts, setParts] = useState<Part[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [assemblyOrders, setAssemblyOrders] = useState<any[]>([]);
  const [isPartModalOpen, setIsPartModalOpen] = useState(false);

  const fetchData = async () => {
    const [fetchedParts, fetchedProducts, fetchedOrders] = await Promise.all([
      window.dbApi.getParts(),
      window.dbApi.getProducts(),
      window.dbApi.getAssemblyOrders(),
    ]);
    setParts(fetchedParts);
    setProducts(fetchedProducts);
    setAssemblyOrders(fetchedOrders);
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleSavePart = async (partData: Omit<Part, 'id'>) => {
    await window.dbApi.addPart(partData);
    fetchData();
    setIsPartModalOpen(false);
  };

  const handleFulfillAssembly = async (orderId: number) => {
    try {
      await window.dbApi.fulfillAssemblyOrder(orderId);
      fetchData();
    } catch (error) {
      alert(`Error fulfilling order: ${error.message}`);
    }
  };

  const getStatusChip = (status: string) => {
    const statusClass = `status-chip status-${status.replace('_', '-')}`;
    return <span className={statusClass}>{status.replace('_', ' ')}</span>;
  };

  return (
    <>
      <div className="view-container production-view">
        {/* Left Column: Workflow */}
        <div className="production-workflow">
          <div className="card">
            <div className="view-header">
                <h2>Production Workflow</h2>
                <button className="btn btn-primary">New Assembly Order</button>
            </div>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Order ID</th>
                  <th>Part to Assemble</th>
                  <th>Quantity</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {assemblyOrders.map(order => (
                  <tr key={order.id}>
                    <td>#{order.id}</td>
                    <td>{order.partName}</td>
                    <td>{order.quantity}</td>
                    <td>{getStatusChip(order.status)}</td>
                    <td>
                      {order.status === 'pending' && (
                        <button className="btn btn-sm btn-secondary" onClick={() => handleFulfillAssembly(order.id)}>Complete</button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Right Column: Definitions */}
        <div className="production-definitions">
          <div className="card">
            <div className="view-header">
              <h2>Parts</h2>
              <button className="btn btn-primary btn-sm" onClick={() => setIsPartModalOpen(true)}>Add Part</button>
            </div>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Type</th>
                </tr>
              </thead>
              <tbody>
                {parts.map(p => (
                  <tr key={p.id}>
                    <td>{p.name}</td>
                    <td>{p.type}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="card">
            <div className="view-header">
              <h2>Products</h2>
              <button className="btn btn-primary btn-sm">Add Product</button>
            </div>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Sale Price</th>
                </tr>
              </thead>
              <tbody>
                {products.map(p => (
                  <tr key={p.id}>
                    <td>{p.name}</td>
                    <td>${p.salePrice.toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
      <PartModal
        isOpen={isPartModalOpen}
        onClose={() => setIsPartModalOpen(false)}
        onSave={handleSavePart}
      />
    </>
  );
};

export default ProductionView;
