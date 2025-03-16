const express = require('express');
const router = express.Router();
const { 
  getAllDeliveries, 
  getDeliveryById, 
  createDelivery, 
  completeDelivery,
  cancelDelivery
} = require('../controllers/deliveryController');
const { protect } = require('../middleware/auth');
const { authorize } = require('../middleware/roleCheck');

// @route   GET /api/deliveries
// @desc    Get all deliveries
// @access  Private
router.get('/', protect, getAllDeliveries);

// @route   GET /api/deliveries/:id
// @desc    Get delivery by ID
// @access  Private
router.get('/:id', protect, getDeliveryById);

// @route   POST /api/deliveries
// @desc    Create a new delivery
// @access  Private (Admin, Manager, Seller)
router.post('/', protect, authorize('Admin', 'Manager', 'Seller'), createDelivery);

// @route   PUT /api/deliveries/:id/complete
// @desc    Complete a delivery
// @access  Private (Admin, Manager, Seller)
router.put('/:id/complete', protect, authorize('Admin', 'Manager', 'Seller'), completeDelivery);

// @route   PUT /api/deliveries/:id/cancel
// @desc    Cancel a delivery
// @access  Private (Admin, Manager)
router.put('/:id/cancel', protect, authorize('Admin', 'Manager'), cancelDelivery);

module.exports = router;
