const express = require('express');
const fillingController = require('../controllers/fillingController');
const { auth } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const { USER_ROLES } = require('../models/User');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Get all filling lines (All roles)
router.get('/lines', fillingController.getAllFillingLines);

// Get filling line by ID (All roles)
router.get('/lines/:id', fillingController.getFillingLineById);

// Create filling line (Admin, Manager)
router.post(
  '/lines',
  checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER]),
  fillingController.createFillingLine
);

// Update filling line (Admin, Manager)
router.put(
  '/lines/:id',
  checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER]),
  fillingController.updateFillingLine
);

// Start filling session (Filler, Manager, Admin)
router.post(
  '/sessions',
  checkRole([USER_ROLES.FILLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  fillingController.startFillingSession
);

// Add cylinder to filling session (Filler, Manager, Admin)
router.post(
  '/sessions/cylinders',
  checkRole([USER_ROLES.FILLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  fillingController.addCylinderToSession
);

// Update cylinder filling status (Filler, Manager, Admin)
router.patch(
  '/sessions/cylinders/:id',
  checkRole([USER_ROLES.FILLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  fillingController.updateCylinderFilling
);

// End filling session (Filler, Manager, Admin)
router.patch(
  '/sessions/:id/end',
  checkRole([USER_ROLES.FILLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  fillingController.endFillingSession
);

// Get session details (All roles)
router.get('/sessions/:id', fillingController.getSessionDetails);

// Get filling sessions list (All roles)
router.get('/sessions', fillingController.getFillingSessionsList);

module.exports = router;
