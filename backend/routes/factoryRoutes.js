const express = require('express');
const router = express.Router();
const factoryController = require('../controllers/factoryController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// All routes require authentication
router.use(authenticate);

// Get all factories - all authenticated users
router.get('/', factoryController.getAllFactories);

// Get factory by ID - all authenticated users
router.get('/:id', factoryController.getFactoryById);

// Create new factory - admin and manager only
router.post('/', authorize(['admin', 'manager']), factoryController.createFactory);

// Update factory - admin and manager only
router.put('/:id', authorize(['admin', 'manager']), factoryController.updateFactory);

// Delete factory - admin only
router.delete('/:id', authorize('admin'), factoryController.deleteFactory);

module.exports = router;
