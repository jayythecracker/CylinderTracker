const express = require('express');
const customerController = require('../controllers/customerController');
const { auth } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const { USER_ROLES } = require('../models/User');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Get all customers (All roles)
router.get('/', customerController.getAllCustomers);

// Get customer by ID (All roles)
router.get('/:id', customerController.getCustomerById);

// Create customer (Admin, Manager)
router.post(
  '/',
  checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER]),
  customerController.createCustomer
);

// Update customer (Admin, Manager)
router.put(
  '/:id',
  checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER]),
  customerController.updateCustomer
);

// Delete customer (Admin only)
router.delete(
  '/:id',
  checkRole([USER_ROLES.ADMIN]),
  customerController.deleteCustomer
);

// Update customer balance (Admin, Manager, Seller)
router.patch(
  '/:id/balance',
  checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER, USER_ROLES.SELLER]),
  customerController.updateBalance
);

module.exports = router;
