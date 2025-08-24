import React from 'react';
import { NavLink } from 'react-router-dom';

const Sidebar = () => {
  return (
    <nav className="sidebar">
      <div className="sidebar-header">
        <h2>Workshop Mgr</h2>
      </div>
      <ul className="sidebar-nav">
        <li>
          <NavLink to="/" end>
            Dashboard
          </NavLink>
        </li>
        <li>
          <NavLink to="/contacts">
            Contacts
          </NavLink>
        </li>
        <li>
          <NavLink to="/employees">
            Employees
          </NavLink>
        </li>
        <li>
          <NavLink to="/inventory">
            Inventory
          </NavLink>
        </li>
        <li>
          <NavLink to="/production">
            Production
          </NavLink>
        </li>
        <li>
          <NavLink to="/sales">
            Sales
          </NavLink>
        </li>
        <li>
          <NavLink to="/financials">
            Financials
          </NavLink>
        </li>
        {/* Add other links as we build the features */}
      </ul>
    </nav>
  );
};

export default Sidebar;
