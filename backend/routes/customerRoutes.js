const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// All routes require authentication
router.use(authenticate);

// Get all customers - all authenticated users
router.get('/', customerController.getAllCustomers);

// Get customer by ID - all authenticated users
router.get('/:id', customerController.getCustomerById);

// Create new customer - admin, manager, seller
router.post('/', authorize(['admin', 'manager', 'seller']), customerController.createCustomer);

// Update customer - admin, manager, seller
router.put('/:id', authorize(['admin', 'manager', 'seller']), customerController.updateCustomer);

// Delete customer - admin only
router.delete('/:id', authorize('admin'), customerController.deleteCustomer);

// Update customer credit - admin, manager
router.put('/:id/credit', authorize(['admin', 'manager']), customerController.updateCustomerCredit);

module.exports = router;
