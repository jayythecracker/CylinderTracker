const express = require('express');
const reportController = require('../controllers/reportController');
const { auth } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const { USER_ROLES } = require('../models/User');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Daily sales report (Manager, Admin)
router.get(
  '/sales/daily',
  checkRole([USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  reportController.dailySalesReport
);

// Monthly sales report (Manager, Admin)
router.get(
  '/sales/monthly',
  checkRole([USER_ROLES.MANAGER, USER_ROLES.ADMIN]),
  reportController.monthlySalesReport
);

// Cylinder status report (All roles)
router.get('/cylinders/status', reportController.cylinderStatusReport);

// Filling activity report (Manager, Admin, Filler)
router.get(
  '/filling/activity',
  checkRole([USER_ROLES.MANAGER, USER_ROLES.ADMIN, USER_ROLES.FILLER]),
  reportController.fillingActivityReport
);

// Customer activity report (Manager, Admin, Seller)
router.get(
  '/customers/activity',
  checkRole([USER_ROLES.MANAGER, USER_ROLES.ADMIN, USER_ROLES.SELLER]),
  reportController.customerActivityReport
);

module.exports = router;
