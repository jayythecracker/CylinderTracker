const express = require('express');
const salesController = require('../controllers/salesController');
const { auth } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const { USER_ROLES } = require('../models/User');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Get all sales (All roles)
router.get('/', salesController.getAllSales);

// Get sale by ID (All roles)
router.get('/:id', salesController.getSaleById);

// Create sale (Seller, Manager, Admin)
router.post(
  '/',
  checkRole([USER_ROLES.SELLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  salesController.createSale
);

// Update sale status (Seller, Manager, Admin)
router.patch(
  '/:id/status',
  checkRole([USER_ROLES.SELLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  salesController.updateSaleStatus
);

// Add cylinder returns (Seller, Manager, Admin)
router.post(
  '/:id/returns',
  checkRole([USER_ROLES.SELLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  salesController.addCylinderReturns
);

// Cancel sale (Manager, Admin)
router.patch(
  '/:id/cancel',
  checkRole([USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  salesController.cancelSale
);

module.exports = router;
