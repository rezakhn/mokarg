import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  // Inventory Items Table
  await knex.schema.createTable('inventory_items', (table) => {
    table.increments('id').primary();
    table.string('name').notNullable().unique();
    table.integer('quantity').notNullable().defaultTo(0);
    table.decimal('averageCost').notNullable().defaultTo(0);
    table.integer('stockThreshold').nullable();
    table.timestamps(true, true);
  });

  // Purchases Table
  await knex.schema.createTable('purchases', (table) => {
    table.increments('id').primary();
    table.integer('contactId').unsigned().references('id').inTable('contacts').onDelete('SET NULL');
    table.date('purchaseDate').notNullable();
    table.decimal('totalValue').notNullable();
    table.timestamps(true, true);
  });

  // Purchase Items Table (Join table for Purchases and Inventory Items)
  await knex.schema.createTable('purchase_items', (table) => {
    table.increments('id').primary();
    table.integer('purchaseId').unsigned().references('id').inTable('purchases').onDelete('CASCADE');
    table.integer('inventoryItemId').unsigned().references('id').inTable('inventory_items').onDelete('CASCADE');
    table.integer('quantity').notNullable();
    table.decimal('unitCost').notNullable();
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('purchase_items');
  await knex.schema.dropTableIfExists('purchases');
  await knex.schema.dropTableIfExists('inventory_items');
}
