import React, { useEffect, useState } from 'react';
import { Employee } from '../types';
import EmployeeModal from '../components/modals/EmployeeModal';

const EmployeesView = () => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingEmployee, setEditingEmployee] = useState<Employee | null>(null);

  const fetchEmployees = async () => {
    const fetchedEmployees = await window.dbApi.getEmployees();
    setEmployees(fetchedEmployees);
  };

  useEffect(() => {
    fetchEmployees();
  }, []);

  const handleAdd = () => {
    setEditingEmployee(null);
    setIsModalOpen(true);
  };

  const handleEdit = (employee: Employee) => {
    setEditingEmployee(employee);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this employee?')) {
      await window.dbApi.deleteEmployee(id);
      fetchEmployees();
    }
  };

  const handleSave = async (employeeData: Omit<Employee, 'id'>) => {
    if (editingEmployee) {
      await window.dbApi.updateEmployee(editingEmployee.id, employeeData);
    } else {
      await window.dbApi.addEmployee(employeeData);
    }
    fetchEmployees();
    setIsModalOpen(false);
  };

  return (
    <>
      <div className="view-container">
        <div className="view-header">
          <h1>Employees</h1>
          <button className="btn btn-primary" onClick={handleAdd}>Add Employee</button>
        </div>
        <div className="card">
          <table className="data-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Payment Type</th>
                <th>Rate</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {employees.map((employee) => (
                <tr key={employee.id}>
                  <td>{employee.name}</td>
                  <td>{employee.paymentType}</td>
                  <td>{employee.paymentRate}</td>
                  <td>
                    <button className="btn btn-sm btn-secondary" onClick={() => handleEdit(employee)}>Edit</button>
                    <button className="btn btn-sm btn-danger" onClick={() => handleDelete(employee.id)}>Delete</button>
                  </td>
                </tr>
              ))}
              {employees.length === 0 && (
                <tr>
                  <td colSpan={4}>No employees found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
      <EmployeeModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSave={handleSave}
        employee={editingEmployee}
      />
    </>
  );
};

export default EmployeesView;
