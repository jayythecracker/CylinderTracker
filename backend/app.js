const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const helmet = require('helmet');
const morgan = require('morgan');

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const factoryRoutes = require('./routes/factories');
const cylinderRoutes = require('./routes/cylinders');
const customerRoutes = require('./routes/customers');
const fillingRoutes = require('./routes/fillings');
const inspectionRoutes = require('./routes/inspections');
const truckRoutes = require('./routes/trucks');
const saleRoutes = require('./routes/sales');
const reportRoutes = require('./routes/reports');

// Initialize express app
const app = express();

// Apply middlewares
app.use(cors());
app.use(helmet());
app.use(morgan('combined'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/factories', factoryRoutes);
app.use('/api/cylinders', cylinderRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/fillings', fillingRoutes);
app.use('/api/inspections', inspectionRoutes);
app.use('/api/trucks', truckRoutes);
app.use('/api/sales', saleRoutes);
app.use('/api/reports', reportRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Server Error',
    message: process.env.NODE_ENV === 'production' ? 'An unexpected error occurred' : err.message
  });
});

module.exports = app;
