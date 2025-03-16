const express = require('express');
const cors = require('cors');
const { sequelize } = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const cylinderRoutes = require('./routes/cylinderRoutes');
const customerRoutes = require('./routes/customerRoutes');
const factoryRoutes = require('./routes/factoryRoutes');
const fillingRoutes = require('./routes/fillingRoutes');
const inspectionRoutes = require('./routes/inspectionRoutes');
const salesRoutes = require('./routes/salesRoutes');
const reportRoutes = require('./routes/reportRoutes');

// Initialize express app
const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(express.json());
app.use(cors());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/cylinders', cylinderRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/factories', factoryRoutes);
app.use('/api/filling', fillingRoutes);
app.use('/api/inspection', inspectionRoutes);
app.use('/api/sales', salesRoutes);
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
    error: process.env.NODE_ENV === 'development' ? err.message : {}
  });
});

// Start server
const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log('Database connection has been established successfully.');
    
    // Sync database models (in production, use migrations instead)
    await sequelize.sync();
    console.log('Database synchronized.');
    
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }
};

startServer();
