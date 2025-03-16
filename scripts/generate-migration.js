require('dotenv').config();
const { Pool } = require('pg');
const { drizzle } = require('drizzle-orm/node-postgres');
const { migrate } = require('drizzle-orm/node-postgres/migrator');
const { sql } = require('drizzle-orm');

async function generateTables() {
  try {
    if (!process.env.DATABASE_URL) {
      console.error('DATABASE_URL environment variable is not set');
      process.exit(1);
    }

    console.log('Connecting to database...');
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    const db = drizzle(pool);

    // Direct SQL to create tables
    console.log('Creating tables directly with SQL...');
    
    // Create users table
    await db.execute(sql`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        full_name VARCHAR(100) NOT NULL,
        username VARCHAR(50) NOT NULL UNIQUE,
        password VARCHAR(100) NOT NULL,
        role VARCHAR(20) NOT NULL DEFAULT 'viewer',
        email VARCHAR(100),
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);
    console.log('Users table created');

    // Create factories table
    await db.execute(sql`
      CREATE TABLE IF NOT EXISTS factories (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        location VARCHAR(200) NOT NULL,
        contact_person VARCHAR(100),
        contact_phone VARCHAR(20),
        email VARCHAR(100),
        active BOOLEAN NOT NULL DEFAULT TRUE,
        description TEXT,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);
    console.log('Factories table created');

    // Create customers table
    await db.execute(sql`
      CREATE TABLE IF NOT EXISTS customers (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        type VARCHAR(20) NOT NULL,
        contact_person VARCHAR(100),
        contact_number VARCHAR(20),
        email VARCHAR(100),
        address TEXT,
        payment_type VARCHAR(20) NOT NULL DEFAULT 'Cash',
        credit_limit NUMERIC(10, 2) DEFAULT 0,
        current_credit NUMERIC(10, 2) DEFAULT 0,
        notes TEXT,
        active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);
    console.log('Customers table created');

    // Create cylinders table with factory_id reference
    await db.execute(sql`
      CREATE TABLE IF NOT EXISTS cylinders (
        id SERIAL PRIMARY KEY,
        serial_number VARCHAR(50) NOT NULL UNIQUE,
        gas_type VARCHAR(50) NOT NULL,
        size VARCHAR(20) NOT NULL,
        manufacturer VARCHAR(100),
        manufacture_date DATE,
        last_inspection_date DATE,
        next_inspection_date DATE,
        status VARCHAR(20) NOT NULL DEFAULT 'Empty',
        working_pressure NUMERIC(10, 2),
        test_pressure NUMERIC(10, 2),
        water_capacity NUMERIC(10, 2),
        empty_weight NUMERIC(10, 2),
        valve_type VARCHAR(50),
        current_location VARCHAR(100) DEFAULT 'Factory',
        current_customer_id INTEGER REFERENCES customers(id),
        factory_id INTEGER REFERENCES factories(id),
        qr_code VARCHAR(200),
        notes TEXT,
        active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);
    console.log('Cylinders table created');

    console.log('All tables created successfully');
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

generateTables();