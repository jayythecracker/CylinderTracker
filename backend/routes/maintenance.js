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
const authenticateJWT = require('../middleware/auth');
const { authorize } = require('../middleware/roles');

// @route   GET /api/maintenance
// @desc    Get all maintenance records
// @access  Private
router.get('/', authenticateJWT, getAllMaintenanceRecords);

// @route   GET /api/maintenance/:id
// @desc    Get maintenance record by ID
// @access  Private
router.get('/:id', authenticateJWT, getMaintenanceById);

// @route   POST /api/maintenance
// @desc    Create a new maintenance record
// @access  Private (Admin, Manager, Filler)
router.post('/', authenticateJWT, authorize('admin', 'manager', 'filler'), createMaintenance);

// @route   PUT /api/maintenance/:id
// @desc    Update maintenance record
// @access  Private (Admin, Manager, Filler)
router.put('/:id', authenticateJWT, authorize('admin', 'manager', 'filler'), updateMaintenance);

// @route   PUT /api/maintenance/:id/complete
// @desc    Complete maintenance
// @access  Private (Admin, Manager, Filler)
router.put('/:id/complete', authenticateJWT, authorize('admin', 'manager', 'filler'), completeMaintenance);

// @route   PUT /api/maintenance/:id/unrepairable
// @desc    Mark maintenance as unrepairable
// @access  Private (Admin, Manager)
router.put('/:id/unrepairable', authenticateJWT, authorize('admin', 'manager'), markUnrepairable);

module.exports = router;
