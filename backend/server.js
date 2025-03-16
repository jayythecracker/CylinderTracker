const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { Pool } = require('pg');
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const factoryRoutes = require('./routes/factoryRoutes');
const cylinderRoutes = require('./routes/cylinderRoutes');
const customerRoutes = require('./routes/customerRoutes');
const fillingRoutes = require('./routes/fillingRoutes');
const inspectionRoutes = require('./routes/inspectionRoutes');
const saleRoutes = require('./routes/saleRoutes');
const reportRoutes = require('./routes/reportRoutes');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000; // Use port 5000 as default for Replit

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/factories', factoryRoutes);
app.use('/api/cylinders', cylinderRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/filling', fillingRoutes);
app.use('/api/inspection', inspectionRoutes);
app.use('/api/sales', saleRoutes);
app.use('/api/reports', reportRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'production' ? {} : err
  });
});

// Database connection and server start
async function startServer() {
  try {
    // Create a database connection pool
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
    });

    // Test database connection
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    console.log('Database connected successfully at', result.rows[0].now);
    client.release();
    
    // Start the server
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
