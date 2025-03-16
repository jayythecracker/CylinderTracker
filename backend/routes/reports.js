const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const authenticateJWT = require('../middleware/auth');
const { checkPermission } = require('../middleware/roles');
const { permissions } = require('../config/auth');

// All routes require authentication
router.use(authenticateJWT);
// All report routes require VIEW_REPORTS permission
router.use(checkPermission(permissions.VIEW_REPORTS));

// Dashboard overview
router.get('/dashboard', reportController.getDashboardOverview);

// Inventory report
router.get('/inventory', reportController.getInventoryReport);

// Sales report
router.get('/sales', reportController.getSalesReport);

// Operations report
router.get('/operations', reportController.getOperationsReport);

// Customer accounts report
router.get('/customer-accounts', reportController.getCustomerAccountsReport);

module.exports = router;
