import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  // Add COGS to sales_orders
  await knex.schema.alterTable('sales_orders', (table) => {
    table.decimal('costOfGoodsSold').nullable();
  });

  // Expenses Table
  await knex.schema.createTable('expenses', (table) => {
    table.increments('id').primary();
    table.string('description').notNullable();
    table.decimal('amount').notNullable();
    table.date('expenseDate').notNullable();
    table.timestamps(true, true);
  });

  // Salary Payments Table
  await knex.schema.createTable('salary_payments', (table) => {
    table.increments('id').primary();
    table.integer('employeeId').unsigned().references('id').inTable('employees').onDelete('SET NULL');
    table.decimal('amount').notNullable();
    table.date('paymentDate').notNullable();
    table.date('periodStartDate').notNullable();
    table.date('periodEndDate').notNullable();
    table.timestamps(true, true);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('salary_payments');
  await knex.schema.dropTableIfExists('expenses');
  await knex.schema.alterTable('sales_orders', (table) => {
    table.dropColumn('costOfGoodsSold');
  });
}
