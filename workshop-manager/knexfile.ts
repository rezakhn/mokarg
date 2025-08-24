import type { Knex } from 'knex';
import path from 'path';

const config: { [key: string]: Knex.Config } = {
  development: {
    client: 'sqlite3',
    connection: {
      filename: path.resolve(__dirname, 'src', 'db', 'workshop.db'),
    },
    useNullAsDefault: true,
    migrations: {
      directory: './src/db/migrations',
    },
  },
};

export default config;
