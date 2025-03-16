const express = require('express');
const router = express.Router();
const truckController = require('../controllers/truckController');
const authenticateJWT = require('../middleware/auth');
const { checkPermission } = require('../middleware/roles');
const { permissions } = require('../config/auth');

// All routes require authentication
router.use(authenticateJWT);

// Get all trucks
router.get(
  '/',
  checkPermission(permissions.READ_CYLINDER), // Using cylinder permission
  truckController.getAllTrucks
);

// Get truck by ID
router.get(
  '/:id',
  checkPermission(permissions.READ_CYLINDER),
  truckController.getTruckById
);

// Create new truck
router.post(
  '/',
  checkPermission(permissions.CREATE_CYLINDER),
  truckController.createTruck
);

// Update truck
router.put(
  '/:id',
  checkPermission(permissions.UPDATE_CYLINDER),
  truckController.updateTruck
);

// Delete truck
router.delete(
  '/:id',
  checkPermission(permissions.DELETE_CYLINDER),
  truckController.deleteTruck
);

// Update truck status
router.patch(
  '/:id/status',
  checkPermission(permissions.UPDATE_CYLINDER),
  truckController.updateStatus
);

// Get truck deliveries
router.get(
  '/:id/deliveries',
  checkPermission(permissions.READ_SALE),
  truckController.getTruckDeliveries
);

module.exports = router;
