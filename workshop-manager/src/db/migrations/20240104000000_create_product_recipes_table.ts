import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('product_recipes', (table) => {
    table.increments('id').primary();
    // The product this recipe is for
    table.integer('productId').unsigned().references('id').inTable('products').onDelete('CASCADE');
    // The component part required
    table.integer('partId').unsigned().references('id').inTable('parts').onDelete('CASCADE');
    table.integer('quantity').notNullable();
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('product_recipes');
}
