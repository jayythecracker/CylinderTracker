const express = require('express');
const router = express.Router();
const saleController = require('../controllers/saleController');
const authenticateJWT = require('../middleware/auth');
const { checkPermission } = require('../middleware/roles');
const { permissions } = require('../config/auth');

// All routes require authentication
router.use(authenticateJWT);

// Get all sales
router.get(
  '/',
  checkPermission(permissions.READ_SALE),
  saleController.getAllSales
);

// Get sale by ID
router.get(
  '/:id',
  checkPermission(permissions.READ_SALE),
  saleController.getSaleById
);

// Create new sale
router.post(
  '/',
  checkPermission(permissions.CREATE_SALE),
  saleController.createSale
);

// Update sale delivery status
router.patch(
  '/:id/delivery',
  checkPermission(permissions.UPDATE_SALE),
  saleController.updateDeliveryStatus
);

// Update sale payment status
router.patch(
  '/:id/payment',
  checkPermission(permissions.UPDATE_SALE),
  saleController.updatePaymentStatus
);

// Get sales statistics
router.get(
  '/stats/overview',
  checkPermission(permissions.VIEW_REPORTS),
  saleController.getSalesStats
);

module.exports = router;
