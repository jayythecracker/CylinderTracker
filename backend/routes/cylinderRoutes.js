const express = require('express');
const cylinderController = require('../controllers/cylinderController');
const { auth } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const { USER_ROLES } = require('../models/User');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Get all cylinders (All roles)
router.get('/', cylinderController.getAllCylinders);

// Get cylinder by ID (All roles)
router.get('/:id', cylinderController.getCylinderById);

// Get cylinder by QR code (All roles)
router.get('/qr/:qrCode', cylinderController.getCylinderByQR);

// Create cylinder (Admin, Manager)
router.post(
  '/',
  checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER]),
  cylinderController.createCylinder
);

// Update cylinder (Admin, Manager)
router.put(
  '/:id',
  checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER]),
  cylinderController.updateCylinder
);

// Delete cylinder (Admin only)
router.delete(
  '/:id',
  checkRole([USER_ROLES.ADMIN]),
  cylinderController.deleteCylinder
);

// Update cylinder status (All roles)
router.patch(
  '/:id/status',
  cylinderController.updateCylinderStatus
);

// Batch update cylinder status (Filler, Manager, Admin)
router.post(
  '/batch-update',
  checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER, USER_ROLES.FILLER]),
  cylinderController.batchUpdateStatus
);

module.exports = router;
