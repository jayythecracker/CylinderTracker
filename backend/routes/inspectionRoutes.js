const express = require('express');
const inspectionController = require('../controllers/inspectionController');
const { auth } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const { USER_ROLES } = require('../models/User');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Get cylinders for inspection (All roles)
router.get('/cylinders', inspectionController.getCylindersForInspection);

// Get cylinder inspection details (All roles)
router.get('/cylinders/:id', inspectionController.getCylinderInspectionDetails);

// Approve cylinder (Filler, Manager, Admin)
router.patch(
  '/cylinders/:id/approve',
  checkRole([USER_ROLES.FILLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  inspectionController.approveCylinder
);

// Reject cylinder (Filler, Manager, Admin)
router.patch(
  '/cylinders/:id/reject',
  checkRole([USER_ROLES.FILLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  inspectionController.rejectCylinder
);

// Batch approve cylinders (Filler, Manager, Admin)
router.post(
  '/cylinders/batch-approve',
  checkRole([USER_ROLES.FILLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  inspectionController.batchApproveCylinders
);

// Batch reject cylinders (Filler, Manager, Admin)
router.post(
  '/cylinders/batch-reject',
  checkRole([USER_ROLES.FILLER, USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  inspectionController.batchRejectCylinders
);

module.exports = router;
