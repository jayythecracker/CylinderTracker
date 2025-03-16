const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');
const authenticateJWT = require('../middleware/auth');
const { checkPermission } = require('../middleware/roles');
const { permissions } = require('../config/auth');

// All routes require authentication
router.use(authenticateJWT);

// Get all customers
router.get(
  '/',
  checkPermission(permissions.READ_CUSTOMER),
  customerController.getAllCustomers
);

// Get customer by ID
router.get(
  '/:id',
  checkPermission(permissions.READ_CUSTOMER),
  customerController.getCustomerById
);

// Create new customer
router.post(
  '/',
  checkPermission(permissions.CREATE_CUSTOMER),
  customerController.createCustomer
);

// Update customer
router.put(
  '/:id',
  checkPermission(permissions.UPDATE_CUSTOMER),
  customerController.updateCustomer
);

// Delete customer
router.delete(
  '/:id',
  checkPermission(permissions.DELETE_CUSTOMER),
  customerController.deleteCustomer
);

// Get customer sales history
router.get(
  '/:id/sales',
  checkPermission(permissions.READ_SALE),
  customerController.getCustomerSales
);

// Update customer balance
router.patch(
  '/:id/balance',
  checkPermission(permissions.UPDATE_CUSTOMER),
  customerController.updateBalance
);

module.exports = router;
