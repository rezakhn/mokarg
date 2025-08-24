import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  // Parts can be raw materials or assembled components
  await knex.schema.createTable('parts', (table) => {
    table.increments('id').primary();
    table.string('name').notNullable().unique();
    table.string('type').notNullable(); // 'raw' or 'assembled'
    // A part can also be an inventory item
    table.integer('inventoryItemId').unsigned().references('id').inTable('inventory_items').nullable();
    table.timestamps(true, true);
  });

  // A recipe defines which parts are needed to create an assembled part
  await knex.schema.createTable('part_recipes', (table) => {
    table.increments('id').primary();
    // The assembled part this recipe is for
    table.integer('assembledPartId').unsigned().references('id').inTable('parts').onDelete('CASCADE');
    // The component part required
    table.integer('componentPartId').unsigned().references('id').inTable('parts').onDelete('CASCADE');
    table.integer('quantity').notNullable();
  });

  // Products are final items sold to customers
  await knex.schema.createTable('products', (table) => {
    table.increments('id').primary();
    table.string('name').notNullable().unique();
    table.decimal('salePrice').notNullable();
    // A product can be an inventory item
    table.integer('inventoryItemId').unsigned().references('id').inTable('inventory_items').nullable();
    table.timestamps(true, true);
  });

  // Assembly Orders are work orders to produce a certain quantity of an assembled part
  await knex.schema.createTable('assembly_orders', (table) => {
    table.increments('id').primary();
    table.integer('partId').unsigned().references('id').inTable('parts').onDelete('CASCADE');
    table.integer('quantity').notNullable();
    table.string('status').notNullable().defaultTo('pending'); // pending, fulfilled
    table.timestamps(true, true);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('assembly_orders');
  await knex.schema.dropTableIfExists('products');
  await knex.schema.dropTableIfExists('part_recipes');
  await knex.schema.dropTableIfExists('parts');
}
