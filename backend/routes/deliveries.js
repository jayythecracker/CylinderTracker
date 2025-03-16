const express = require('express');
const router = express.Router();
const { 
  getAllDeliveries, 
  getDeliveryById, 
  createDelivery, 
  completeDelivery,
  cancelDelivery
} = require('../controllers/deliveryController');
const authenticateJWT = require('../middleware/auth');
const { authorize } = require('../middleware/roles');

// @route   GET /api/deliveries
// @desc    Get all deliveries
// @access  Private
router.get('/', authenticateJWT, getAllDeliveries);

// @route   GET /api/deliveries/:id
// @desc    Get delivery by ID
// @access  Private
router.get('/:id', authenticateJWT, getDeliveryById);

// @route   POST /api/deliveries
// @desc    Create a new delivery
// @access  Private (Admin, Manager, Seller)
router.post('/', authenticateJWT, authorize('admin', 'manager', 'seller'), createDelivery);

// @route   PUT /api/deliveries/:id/complete
// @desc    Complete a delivery
// @access  Private (Admin, Manager, Seller)
router.put('/:id/complete', authenticateJWT, authorize('admin', 'manager', 'seller'), completeDelivery);

// @route   PUT /api/deliveries/:id/cancel
// @desc    Cancel a delivery
// @access  Private (Admin, Manager)
router.put('/:id/cancel', authenticateJWT, authorize('admin', 'manager'), cancelDelivery);

module.exports = router;
