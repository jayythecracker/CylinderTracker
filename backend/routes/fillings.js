const express = require('express');
const router = express.Router();
const fillingController = require('../controllers/fillingController');
const authenticateJWT = require('../middleware/auth');
const { checkPermission } = require('../middleware/roles');
const { permissions } = require('../config/auth');

// All routes require authentication
router.use(authenticateJWT);

// Get all fillings
router.get(
  '/',
  checkPermission(permissions.READ_FILLING),
  fillingController.getAllFillings
);

// Get filling by ID
router.get(
  '/:id',
  checkPermission(permissions.READ_FILLING),
  fillingController.getFillingById
);

// Start filling process
router.post(
  '/',
  checkPermission(permissions.CREATE_FILLING),
  fillingController.startFilling
);

// Complete filling process
router.put(
  '/:id',
  checkPermission(permissions.UPDATE_FILLING),
  fillingController.completeFilling
);

// Get active filling lines
router.get(
  '/lines/active',
  checkPermission(permissions.READ_FILLING),
  fillingController.getActiveLines
);

// Get filling stats
router.get(
  '/stats/overview',
  checkPermission(permissions.VIEW_REPORTS),
  fillingController.getFillingStats
);

module.exports = router;
