const express = require('express');
const router = express.Router();
const inspectionController = require('../controllers/inspectionController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// All routes require authentication
router.use(authenticate);

// Get all inspections - all authenticated users
router.get('/', inspectionController.getAllInspections);

// Get inspection by ID - all authenticated users
router.get('/:id', inspectionController.getInspectionById);

// Get cylinder inspection history - all authenticated users
router.get('/cylinder/:cylinderId', inspectionController.getCylinderInspectionHistory);

// Create new inspection - admin, manager, filler
router.post('/', authorize(['admin', 'manager', 'filler']), inspectionController.createInspection);

// Batch inspect cylinders - admin, manager, filler
router.post('/batch', authorize(['admin', 'manager', 'filler']), inspectionController.batchInspect);

module.exports = router;
