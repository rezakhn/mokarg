import React, { useEffect, useState } from 'react';
import { InventoryItem } from '../types';

interface DashboardStats {
  employeeCount: number;
  pendingOrders: number;
  totalUnpaid: number;
  lowStockItems: InventoryItem[];
}

const StatCard = ({ title, value, icon }: { title: string; value: string | number; icon: string }) => (
  <div className="stat-card">
    <div className="stat-card-icon">{icon}</div>
    <div className="stat-card-info">
      <h4>{title}</h4>
      <p>{value}</p>
    </div>
  </div>
);

const DashboardView = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);

  useEffect(() => {
    const fetchStats = async () => {
      const fetchedStats = await window.dbApi.getDashboardStats();
      setStats(fetchedStats);
    };
    fetchStats();
  }, []);

  if (!stats) {
    return <div>Loading...</div>;
  }

  return (
    <div className="view-container">
      <h1>Dashboard</h1>
      <div className="dashboard-grid">
        <div className="dashboard-stats">
          <StatCard title="Total Employees" value={stats.employeeCount} icon="👥" />
          <StatCard title="Pending Orders" value={stats.pendingOrders} icon="📦" />
          <StatCard title="Total Unpaid" value={`$${stats.totalUnpaid.toFixed(2)}`} icon="💰" />
        </div>
        <div className="dashboard-alerts">
          <div className="card">
            <h2>Alerts</h2>
            {stats.lowStockItems.length > 0 ? (
              <ul>
                {stats.lowStockItems.map(item => (
                  <li key={item.id}>
                    <strong>Low Stock:</strong> {item.name} (Qty: {item.quantity})
                  </li>
                ))}
              </ul>
            ) : (
              <p>No alerts.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardView;
