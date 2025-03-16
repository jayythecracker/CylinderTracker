require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcrypt');

async function createAdminUser() {
  console.log('Creating admin user...');

  try {
    // Create connection pool with SSL configuration
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false // Required for some cloud database providers
      }
    });

    // Check if admin user exists
    const checkQuery = await pool.query(
      'SELECT * FROM users WHERE username = $1',
      ['admin']
    );

    if (checkQuery.rows.length > 0) {
      console.log('Admin user already exists');
      await pool.end();
      return;
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('admin123', salt);

    // Insert admin user
    const insertQuery = await pool.query(
      `INSERT INTO users 
      (username, password, email, full_name, role) 
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, username, email, role`,
      ['admin', hashedPassword, 'admin@example.com', 'System Administrator', 'admin']
    );

    console.log('Admin user created:', insertQuery.rows[0]);

    // Close the pool
    await pool.end();
  } catch (error) {
    console.error('Failed to create admin user:', error);
    process.exit(1);
  }
}

createAdminUser();