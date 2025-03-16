const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// All routes require authentication
router.use(authenticate);

// Get daily sales report - admin, manager
router.get('/daily-sales', authorize(['admin', 'manager']), reportController.getDailySalesReport);

// Get monthly sales report - admin, manager
router.get('/monthly-sales', authorize(['admin', 'manager']), reportController.getMonthlySalesReport);

// Get cylinder statistics - all authenticated users
router.get('/cylinder-statistics', reportController.getCylinderStatistics);

// Get filling operations report - admin, manager, filler
router.get('/filling', authorize(['admin', 'manager', 'filler']), reportController.getFillingReport);

// Get customer activity report - admin, manager, seller
router.get('/customer-activity', authorize(['admin', 'manager', 'seller']), reportController.getCustomerActivityReport);

module.exports = router;
