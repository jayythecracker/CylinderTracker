const { Pool } = require('pg');
const { drizzle } = require('drizzle-orm/node-postgres');
require('dotenv').config();

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

console.log('Creating database schema...');

async function runMigration() {
  try {
    // We'll use the SQL way to create tables as we can't directly import TypeScript schema
    // First let's create the enums
    const createEnumsSql = `
      DO $$
      BEGIN
        -- Create enums if they don't exist
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
          CREATE TYPE user_role AS ENUM ('admin', 'manager', 'filler', 'inspector', 'seller', 'viewer');
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cylinder_status') THEN
          CREATE TYPE cylinder_status AS ENUM ('Empty', 'Full', 'InTransit', 'AtCustomer', 'Error', 'Scrapped');
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_type') THEN
          CREATE TYPE payment_type AS ENUM ('Cash', 'Credit');
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'customer_type') THEN
          CREATE TYPE customer_type AS ENUM ('Hospital', 'Factory', 'Shop', 'Workshop', 'Individual');
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'inspection_result') THEN
          CREATE TYPE inspection_result AS ENUM ('Approved', 'Rejected');
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sale_status') THEN
          CREATE TYPE sale_status AS ENUM ('Pending', 'Delivered', 'Completed', 'Cancelled');
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
          CREATE TYPE payment_status AS ENUM ('Unpaid', 'Partially Paid', 'Paid');
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'delivery_type') THEN
          CREATE TYPE delivery_type AS ENUM ('Pickup', 'Delivery');
        END IF;
      END
      $$;
    `;
    
    await pool.query(createEnumsSql);
    console.log('Created enum types');
    
    // Create tables
    const createUsersSql = `
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        username VARCHAR(50) NOT NULL UNIQUE,
        password VARCHAR(100) NOT NULL,
        role user_role NOT NULL DEFAULT 'viewer',
        email VARCHAR(100),
        phone VARCHAR(20),
        active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    const createCustomersSql = `
      CREATE TABLE IF NOT EXISTS customers (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        type customer_type NOT NULL,
        contact_person VARCHAR(100),
        contact_number VARCHAR(20),
        email VARCHAR(100),
        address TEXT,
        payment_type payment_type NOT NULL DEFAULT 'Cash',
        credit_limit NUMERIC(10, 2) DEFAULT '0',
        current_credit NUMERIC(10, 2) DEFAULT '0',
        notes TEXT,
        active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    const createCylindersSql = `
      CREATE TABLE IF NOT EXISTS cylinders (
        id SERIAL PRIMARY KEY,
        serial_number VARCHAR(50) NOT NULL UNIQUE,
        gas_type VARCHAR(50) NOT NULL,
        size VARCHAR(20) NOT NULL,
        manufacturer VARCHAR(100),
        manufacture_date DATE,
        last_inspection_date DATE,
        next_inspection_date DATE,
        status cylinder_status NOT NULL DEFAULT 'Empty',
        working_pressure NUMERIC(10, 2),
        test_pressure NUMERIC(10, 2),
        water_capacity NUMERIC(10, 2),
        empty_weight NUMERIC(10, 2),
        valve_type VARCHAR(50),
        current_location VARCHAR(100) DEFAULT 'Factory',
        current_customer_id INTEGER REFERENCES customers(id),
        qr_code VARCHAR(200),
        notes TEXT,
        active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    const createInspectionsSql = `
      CREATE TABLE IF NOT EXISTS inspections (
        id SERIAL PRIMARY KEY,
        cylinder_id INTEGER NOT NULL REFERENCES cylinders(id),
        inspection_date TIMESTAMP NOT NULL DEFAULT NOW(),
        inspected_by_id INTEGER NOT NULL REFERENCES users(id),
        visual_inspection BOOLEAN NOT NULL,
        pressure_reading NUMERIC(10, 2),
        result inspection_result NOT NULL,
        notes TEXT,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    const createFillingOperationsSql = `
      CREATE TABLE IF NOT EXISTS filling_operations (
        id SERIAL PRIMARY KEY,
        cylinder_id INTEGER NOT NULL REFERENCES cylinders(id),
        filling_date TIMESTAMP NOT NULL DEFAULT NOW(),
        filled_by_id INTEGER NOT NULL REFERENCES users(id),
        pressure_before NUMERIC(10, 2),
        pressure_after NUMERIC(10, 2),
        gas_weight NUMERIC(10, 2),
        batch_number VARCHAR(50),
        notes TEXT,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    const createSalesSql = `
      CREATE TABLE IF NOT EXISTS sales (
        id SERIAL PRIMARY KEY,
        invoice_number VARCHAR(50) NOT NULL UNIQUE,
        customer_id INTEGER NOT NULL REFERENCES customers(id),
        sale_date TIMESTAMP NOT NULL DEFAULT NOW(),
        sold_by_id INTEGER NOT NULL REFERENCES users(id),
        status sale_status NOT NULL DEFAULT 'Pending',
        delivery_type delivery_type NOT NULL DEFAULT 'Pickup',
        payment_status payment_status NOT NULL DEFAULT 'Unpaid',
        subtotal_amount NUMERIC(10, 2) NOT NULL,
        tax_amount NUMERIC(10, 2) DEFAULT '0',
        discount_amount NUMERIC(10, 2) DEFAULT '0',
        total_amount NUMERIC(10, 2) NOT NULL,
        paid_amount NUMERIC(10, 2) DEFAULT '0',
        notes TEXT,
        delivery_address TEXT,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    const createSaleItemsSql = `
      CREATE TABLE IF NOT EXISTS sale_items (
        id SERIAL PRIMARY KEY,
        sale_id INTEGER NOT NULL REFERENCES sales(id),
        cylinder_id INTEGER NOT NULL REFERENCES cylinders(id),
        gas_type VARCHAR(50) NOT NULL,
        cylinder_size VARCHAR(20) NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_price NUMERIC(10, 2) NOT NULL,
        total_price NUMERIC(10, 2) NOT NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'Sold',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    const createPaymentsSql = `
      CREATE TABLE IF NOT EXISTS payments (
        id SERIAL PRIMARY KEY,
        sale_id INTEGER NOT NULL REFERENCES sales(id),
        payment_date TIMESTAMP NOT NULL DEFAULT NOW(),
        received_by_id INTEGER NOT NULL REFERENCES users(id),
        amount NUMERIC(10, 2) NOT NULL,
        payment_method VARCHAR(50) NOT NULL,
        reference_number VARCHAR(50),
        notes TEXT,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    const createTrucksSql = `
      CREATE TABLE IF NOT EXISTS trucks (
        id SERIAL PRIMARY KEY,
        registration_number VARCHAR(50) NOT NULL UNIQUE,
        model VARCHAR(100),
        capacity INTEGER,
        driver_id INTEGER REFERENCES users(id),
        status VARCHAR(20) NOT NULL DEFAULT 'Available',
        notes TEXT,
        active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    const createDeliveriesSql = `
      CREATE TABLE IF NOT EXISTS deliveries (
        id SERIAL PRIMARY KEY,
        sale_id INTEGER NOT NULL REFERENCES sales(id),
        truck_id INTEGER REFERENCES trucks(id),
        delivery_date TIMESTAMP,
        scheduled_date TIMESTAMP,
        driver_id INTEGER REFERENCES users(id),
        status VARCHAR(20) NOT NULL DEFAULT 'Scheduled',
        notes TEXT,
        address TEXT NOT NULL,
        contact_number VARCHAR(20),
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    // Execute table creation in order
    console.log('Creating tables...');
    await pool.query(createUsersSql);
    console.log('Created users table');
    await pool.query(createCustomersSql);
    console.log('Created customers table');
    await pool.query(createCylindersSql);
    console.log('Created cylinders table');
    await pool.query(createInspectionsSql);
    console.log('Created inspections table');
    await pool.query(createFillingOperationsSql);
    console.log('Created filling_operations table');
    await pool.query(createSalesSql);
    console.log('Created sales table');
    await pool.query(createSaleItemsSql);
    console.log('Created sale_items table');
    await pool.query(createPaymentsSql);
    console.log('Created payments table');
    await pool.query(createTrucksSql);
    console.log('Created trucks table');
    await pool.query(createDeliveriesSql);
    console.log('Created deliveries table');
    
    console.log('All tables created successfully!');
    
    // Create a default admin user
    const createAdminSql = `
      INSERT INTO users (name, username, password, role, email)
      SELECT 'Administrator', 'admin', '$2a$10$ORG8.KPLbh9hLzY0Kj0TgeWI60TsB6xgBpEmAODm.QRqsGpgzWmCO', 'admin'::user_role, 'admin@example.com'
      WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');
    `;
    
    await pool.query(createAdminSql);
    console.log('Admin user created (if not already exists)');
    
    process.exit(0);
  } catch (error) {
    console.error('Error creating tables:', error);
    process.exit(1);
  }
}

runMigration();