import knex from 'knex';
import config from '../../knexfile';
import path from 'path';

// We need to adjust the migration path to be absolute for Electron
const dbPath = path.resolve(__dirname, 'workshop.db');
const migrationsPath = path.resolve(__dirname, 'migrations');

const db = knex({
  ...config.development,
  connection: {
    filename: dbPath,
  },
  migrations: {
    directory: migrationsPath,
  },
});

export const runMigrations = async () => {
  try {
    await db.migrate.latest();
    console.log('Migrations ran successfully');
  } catch (error) {
    console.error('Error running migrations:', error);
  }
};

export default db;
