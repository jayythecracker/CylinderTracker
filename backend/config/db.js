const { Sequelize } = require('sequelize');

// Get database credentials from environment variables
const host = process.env.PGHOST || 'localhost';
const port = process.env.PGPORT || 5432;
const database = process.env.PGDATABASE || 'cylinder_management';
const username = process.env.PGUSER || 'postgres';
const password = process.env.PGPASSWORD || 'postgres';

// Create Sequelize instance
const sequelize = new Sequelize({
  host,
  port,
  database,
  username,
  password,
  dialect: 'postgres',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: {
    max: 10,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
});

// Alternative connection method using DATABASE_URL if provided
if (process.env.DATABASE_URL) {
  console.log('Using DATABASE_URL for connection');
  sequelize = new Sequelize(process.env.DATABASE_URL, {
    dialect: 'postgres',
    protocol: 'postgres',
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false
      }
    }
  });
}

module.exports = {
  sequelize
};
