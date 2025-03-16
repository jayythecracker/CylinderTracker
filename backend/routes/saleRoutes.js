const express = require('express');
const router = express.Router();
const saleController = require('../controllers/saleController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// All routes require authentication
router.use(authenticate);

// Get all sales - all authenticated users
router.get('/', saleController.getAllSales);

// Get sale by ID - all authenticated users
router.get('/:id', saleController.getSaleById);

// Create new sale - admin, manager, seller
router.post('/', authorize(['admin', 'manager', 'seller']), saleController.createSale);

// Update sale status - admin, manager, seller
router.put('/:id/status', authorize(['admin', 'manager', 'seller']), saleController.updateSaleStatus);

// Record cylinder return - admin, manager, seller
router.put('/items/:itemId/return', authorize(['admin', 'manager', 'seller']), saleController.recordCylinderReturn);

// Update sale payment - admin, manager, seller
router.put('/:id/payment', authorize(['admin', 'manager', 'seller']), saleController.updateSalePayment);

module.exports = router;
