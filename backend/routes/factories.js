const express = require('express');
const router = express.Router();
const factoryController = require('../controllers/factoryController');
const authenticateJWT = require('../middleware/auth');
const { checkPermission } = require('../middleware/roles');
const { permissions } = require('../config/auth');

// Get all factories - public route, no authentication required
router.get('/', factoryController.getAllFactories);

// All other routes require authentication
router.use(authenticateJWT);

// Get factory by ID
router.get(
  '/:id',
  checkPermission(permissions.READ_FACTORY),
  factoryController.getFactoryById
);

// Create new factory
router.post(
  '/',
  checkPermission(permissions.CREATE_FACTORY),
  factoryController.createFactory
);

// Update factory
router.put(
  '/:id',
  checkPermission(permissions.UPDATE_FACTORY),
  factoryController.updateFactory
);

// Delete factory
router.delete(
  '/:id',
  checkPermission(permissions.DELETE_FACTORY),
  factoryController.deleteFactory
);

// Get cylinders for a factory
router.get(
  '/:id/cylinders',
  checkPermission(permissions.READ_CYLINDER),
  factoryController.getFactoryCylinders
);

module.exports = router;
