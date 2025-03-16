const express = require('express');
const factoryController = require('../controllers/factoryController');
const { auth } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const { USER_ROLES } = require('../models/User');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Get all factories (All roles)
router.get('/', factoryController.getAllFactories);

// Get factory by ID (All roles)
router.get('/:id', factoryController.getFactoryById);

// Create factory (Admin, Manager)
router.post(
  '/',
  checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER]),
  factoryController.createFactory
);

// Update factory (Admin, Manager)
router.put(
  '/:id',
  checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER]),
  factoryController.updateFactory
);

// Delete factory (Admin only)
router.delete(
  '/:id',
  checkRole([USER_ROLES.ADMIN]),
  factoryController.deleteFactory
);

// Get factory statistics (All roles)
router.get('/:id/stats', factoryController.getFactoryStats);

module.exports = router;
