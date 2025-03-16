const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authenticateJWT = require('../middleware/auth');

// Public routes
router.post('/login', authController.login);

// Protected routes
router.post('/register', authenticateJWT, authController.register);
router.get('/me', authenticateJWT, authController.getMe);
router.post('/update-password', authenticateJWT, authController.updatePassword);

module.exports = router;
