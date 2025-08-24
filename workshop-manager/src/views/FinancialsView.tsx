import React, { useEffect, useState } from 'react';
import { Expense } from '../types';
import ExpenseModal from '../components/modals/ExpenseModal';

const FinancialsView = () => {
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [report, setReport] = useState<any>(null);
  const [startDate, setStartDate] = useState(new Date(new Date().setMonth(new Date().getMonth() - 1)).toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState(new Date().toISOString().split('T')[0]);

  const fetchExpenses = async () => {
    const fetchedExpenses = await window.dbApi.getExpenses();
    setExpenses(fetchedExpenses);
  };

  useEffect(() => {
    fetchExpenses();
  }, []);

  const handleSaveExpense = async (expenseData: Omit<Expense, 'id'>) => {
    await window.dbApi.addExpense(expenseData);
    fetchExpenses();
    setIsModalOpen(false);
  };

  const generateReport = async () => {
    const pnlReport = await window.dbApi.getProfitAndLoss({ startDate, endDate });
    setReport(pnlReport);
  };

  return (
    <>
      <div className="view-container">
        <div className="card">
            <h2>Profit & Loss Statement</h2>
            <div className="pnl-form">
                <div className="form-group">
                    <label>Start Date</label>
                    <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} />
                </div>
                <div className="form-group">
                    <label>End Date</label>
                    <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} />
                </div>
                <button className="btn btn-primary" onClick={generateReport}>Generate Report</button>
            </div>
            {report && (
                <div className="pnl-report">
                    <h3>Report for {new Date(report.startDate).toLocaleDateString()} to {new Date(report.endDate).toLocaleDateString()}</h3>
                    <table className="data-table">
                        <tbody>
                            <tr><td>Revenue</td><td>${report.revenue.toFixed(2)}</td></tr>
                            <tr><td>Cost of Goods Sold (COGS)</td><td>${report.cogs.toFixed(2)}</td></tr>
                            <tr className="font-bold"><td>Gross Profit</td><td>${report.grossProfit.toFixed(2)}</td></tr>
                            <tr><td>Operating Expenses</td><td>${report.expenses.toFixed(2)}</td></tr>
                            <tr className="font-bold"><td>Net Profit</td><td>${report.netProfit.toFixed(2)}</td></tr>
                        </tbody>
                    </table>
                </div>
            )}
        </div>

        <div className="card">
            <div className="view-header">
                <h2>Expenses</h2>
                <button className="btn btn-primary" onClick={() => setIsModalOpen(true)}>Add Expense</button>
            </div>
            <table className="data-table">
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Description</th>
                        <th>Amount</th>
                    </tr>
                </thead>
                <tbody>
                    {expenses.map(exp => (
                        <tr key={exp.id}>
                            <td>{new Date(exp.expenseDate).toLocaleDateString()}</td>
                            <td>{exp.description}</td>
                            <td>${exp.amount.toFixed(2)}</td>
                        </tr>
                    ))}
                     {expenses.length === 0 && (
                        <tr>
                            <td colSpan={3}>No expenses found.</td>
                        </tr>
                    )}
                </tbody>
            </table>
        </div>
      </div>
      <ExpenseModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} onSave={handleSaveExpense} />
    </>
  );
};

export default FinancialsView;
