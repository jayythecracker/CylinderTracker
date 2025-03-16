const express = require('express');
const router = express.Router();
const inspectionController = require('../controllers/inspectionController');
const authenticateJWT = require('../middleware/auth');
const { checkPermission } = require('../middleware/roles');
const { permissions } = require('../config/auth');

// All routes require authentication
router.use(authenticateJWT);

// Get all inspections
router.get(
  '/',
  checkPermission(permissions.READ_INSPECTION),
  inspectionController.getAllInspections
);

// Get inspection by ID
router.get(
  '/:id',
  checkPermission(permissions.READ_INSPECTION),
  inspectionController.getInspectionById
);

// Create new inspection
router.post(
  '/',
  checkPermission(permissions.CREATE_INSPECTION),
  inspectionController.createInspection
);

// Batch create inspections (approve all)
router.post(
  '/batch',
  checkPermission(permissions.CREATE_INSPECTION),
  inspectionController.batchCreateInspections
);

// Get inspection stats
router.get(
  '/stats/overview',
  checkPermission(permissions.VIEW_REPORTS),
  inspectionController.getInspectionStats
);

module.exports = router;
