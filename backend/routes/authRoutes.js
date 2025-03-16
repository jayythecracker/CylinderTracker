const express = require('express');
const authController = require('../controllers/authController');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Public routes
router.post('/login', authController.login);

// Protected routes
router.post('/register', auth, authController.register);
router.get('/me', auth, authController.getCurrentUser);
router.post('/change-password', auth, authController.changePassword);

module.exports = router;
