import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('contacts', (table) => {
    table.increments('id').primary();
    table.string('name').notNullable();
    table.string('type').notNullable(); // 'customer' or 'supplier'
    table.string('phone');
    table.text('address');
    table.text('notes');
    table.timestamps(true, true);
  });

  await knex.schema.createTable('employees', (table) => {
    table.increments('id').primary();
    table.string('name').notNullable();
    table.string('paymentType').notNullable(); // 'daily' or 'hourly'
    table.decimal('paymentRate').notNullable();
    table.timestamps(true, true);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('employees');
  await knex.schema.dropTableIfExists('contacts');
}
