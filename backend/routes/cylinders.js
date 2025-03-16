const express = require('express');
const router = express.Router();
const cylinderController = require('../controllers/cylinderController');
const authenticateJWT = require('../middleware/auth');
const { checkPermission } = require('../middleware/roles');
const { permissions } = require('../config/auth');

// All routes require authentication
router.use(authenticateJWT);

// Get all cylinders
router.get(
  '/',
  checkPermission(permissions.READ_CYLINDER),
  cylinderController.getAllCylinders
);

// Get cylinder by ID or QR code
router.get(
  '/:id',
  checkPermission(permissions.READ_CYLINDER),
  cylinderController.getCylinder
);

// Create new cylinder
router.post(
  '/',
  checkPermission(permissions.CREATE_CYLINDER),
  cylinderController.createCylinder
);

// Update cylinder
router.put(
  '/:id',
  checkPermission(permissions.UPDATE_CYLINDER),
  cylinderController.updateCylinder
);

// Delete cylinder
router.delete(
  '/:id',
  checkPermission(permissions.DELETE_CYLINDER),
  cylinderController.deleteCylinder
);

// Update cylinder status
router.patch(
  '/:id/status',
  checkPermission(permissions.UPDATE_CYLINDER),
  cylinderController.updateStatus
);

// Get cylinder history
router.get(
  '/:id/history',
  checkPermission(permissions.READ_CYLINDER),
  cylinderController.getCylinderHistory
);

module.exports = router;
