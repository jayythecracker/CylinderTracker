const express = require('express');
const router = express.Router();
const fillingController = require('../controllers/fillingController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// All routes require authentication
router.use(authenticate);

// Get all filling lines - all authenticated users
router.get('/lines', fillingController.getAllFillingLines);

// Get filling line by ID - all authenticated users
router.get('/lines/:id', fillingController.getFillingLineById);

// Create new filling line - admin and manager only
router.post('/lines', authorize(['admin', 'manager']), fillingController.createFillingLine);

// Update filling line - admin and manager only
router.put('/lines/:id', authorize(['admin', 'manager']), fillingController.updateFillingLine);

// Delete filling line - admin only
router.delete('/lines/:id', authorize('admin'), fillingController.deleteFillingLine);

// Get all filling batches - all authenticated users
router.get('/batches', fillingController.getAllFillingBatches);

// Get filling batch by ID - all authenticated users
router.get('/batches/:id', fillingController.getFillingBatchById);

// Start new filling batch - admin, manager, filler
router.post('/batches', authorize(['admin', 'manager', 'filler']), fillingController.startFillingBatch);

// Complete filling batch - admin, manager, filler
router.put('/batches/:id/complete', authorize(['admin', 'manager', 'filler']), fillingController.completeFillingBatch);

module.exports = router;
