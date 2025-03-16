const { Sequelize } = require('sequelize');

// Get database credentials from environment variables
const host = process.env.PGHOST || 'localhost';
const port = process.env.PGPORT || 5432;
const username = process.env.PGUSER || 'postgres';
const password = process.env.PGPASSWORD || 'postgres';
const database = process.env.PGDATABASE || 'cylinder_management';
const databaseUrl = process.env.DATABASE_URL;

// Create Sequelize instance
let sequelize;

if (databaseUrl) {
  // If DATABASE_URL is provided (common in production environments)
  sequelize = new Sequelize(databaseUrl, {
    dialect: 'postgres',
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false // Important for some hosting providers
      }
    },
    logging: false
  });
} else {
  // Create connection using individual parameters
  sequelize = new Sequelize(database, username, password, {
    host,
    port,
    dialect: 'postgres',
    logging: false
  });
}

module.exports = sequelize;
