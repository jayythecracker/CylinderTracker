const express = require('express');
const router = express.Router();
const cylinderController = require('../controllers/cylinderController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// All routes require authentication
router.use(authenticate);

// Get all cylinders - all authenticated users
router.get('/', cylinderController.getAllCylinders);

// Get cylinder by ID - all authenticated users
router.get('/:id', cylinderController.getCylinderById);

// Get cylinder by QR code - all authenticated users
router.get('/qr/:qrCode', cylinderController.getCylinderByQRCode);

// Create new cylinder - admin and manager only
router.post('/', authorize(['admin', 'manager']), cylinderController.createCylinder);

// Update cylinder - admin and manager only
router.put('/:id', authorize(['admin', 'manager']), cylinderController.updateCylinder);

// Delete cylinder - admin only
router.delete('/:id', authorize('admin'), cylinderController.deleteCylinder);

// Update cylinder status - admin, manager, filler
router.put('/:id/status', authorize(['admin', 'manager', 'filler']), cylinderController.updateCylinderStatus);

module.exports = router;
