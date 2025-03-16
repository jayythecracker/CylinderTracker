const express = require('express');
const router = express.Router();
const { 
  getAllMaintenanceRecords, 
  getMaintenanceById, 
  createMaintenance, 
  updateMaintenance,
  completeMaintenance,
  markUnrepairable
} = require('../controllers/maintenanceController');
const { protect } = require('../middleware/auth');
const { authorize } = require('../middleware/roleCheck');

// @route   GET /api/maintenance
// @desc    Get all maintenance records
// @access  Private
router.get('/', protect, getAllMaintenanceRecords);

// @route   GET /api/maintenance/:id
// @desc    Get maintenance record by ID
// @access  Private
router.get('/:id', protect, getMaintenanceById);

// @route   POST /api/maintenance
// @desc    Create a new maintenance record
// @access  Private (Admin, Manager, Filler)
router.post('/', protect, authorize('Admin', 'Manager', 'Filler'), createMaintenance);

// @route   PUT /api/maintenance/:id
// @desc    Update maintenance record
// @access  Private (Admin, Manager, Filler)
router.put('/:id', protect, authorize('Admin', 'Manager', 'Filler'), updateMaintenance);

// @route   PUT /api/maintenance/:id/complete
// @desc    Complete maintenance
// @access  Private (Admin, Manager, Filler)
router.put('/:id/complete', protect, authorize('Admin', 'Manager', 'Filler'), completeMaintenance);

// @route   PUT /api/maintenance/:id/unrepairable
// @desc    Mark maintenance as unrepairable
// @access  Private (Admin, Manager)
router.put('/:id/unrepairable', protect, authorize('Admin', 'Manager'), markUnrepairable);

module.exports = router;
