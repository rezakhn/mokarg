import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  // Sales Orders Table
  await knex.schema.createTable('sales_orders', (table) => {
    table.increments('id').primary();
    table.integer('contactId').unsigned().references('id').inTable('contacts').onDelete('SET NULL');
    table.date('orderDate').notNullable();
    table.decimal('totalValue').notNullable();
    table.decimal('paidAmount').notNullable().defaultTo(0);
    table.string('fulfillmentStatus').notNullable().defaultTo('pending'); // pending, fulfilled
    table.string('paymentStatus').notNullable().defaultTo('unpaid'); // unpaid, partially_paid, paid
    table.string('deliveryStatus').notNullable().defaultTo('undelivered'); // undelivered, delivered
    table.timestamps(true, true);
  });

  // Sales Order Items Table
  await knex.schema.createTable('sales_order_items', (table) => {
    table.increments('id').primary();
    table.integer('salesOrderId').unsigned().references('id').inTable('sales_orders').onDelete('CASCADE');
    table.integer('productId').unsigned().references('id').inTable('products').onDelete('SET NULL');
    table.integer('quantity').notNullable();
    table.decimal('unitPrice').notNullable();
  });

  // Payments Table
  await knex.schema.createTable('payments', (table) => {
    table.increments('id').primary();
    table.integer('salesOrderId').unsigned().references('id').inTable('sales_orders').onDelete('CASCADE');
    table.decimal('amount').notNullable();
    table.date('paymentDate').notNullable();
    table.timestamps(true, true);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('payments');
  await knex.schema.dropTableIfExists('sales_order_items');
  await knex.schema.dropTableIfExists('sales_orders');
}
