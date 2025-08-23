import React from 'react';
import { MemoryRouter as Router, Routes, Route } from 'react-router-dom';
import MainLayout from './components/MainLayout';
import DashboardView from './views/DashboardView';
import ContactsView from './views/ContactsView';
import EmployeesView from './views/EmployeesView';
import InventoryView from './views/InventoryView';
import ProductionView from './views/ProductionView';
import SalesView from './views/SalesView';
import FinancialsView from './views/FinancialsView';

// Using MemoryRouter is important for Electron environments
const App = () => {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<MainLayout />}>
          <Route index element={<DashboardView />} />
          <Route path="contacts" element={<ContactsView />} />
          <Route path="employees" element={<EmployeesView />} />
          <Route path="inventory" element={<InventoryView />} />
          <Route path="production" element={<ProductionView />} />
          <Route path="sales" element={<SalesView />} />
          <Route path="financials" element={<FinancialsView />} />
          {/* Other routes will be added here */}
        </Route>
      </Routes>
    </Router>
  );
};

export default App;
