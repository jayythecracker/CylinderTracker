const express = require('express');
const userController = require('../controllers/userController');
const { auth } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const { USER_ROLES } = require('../models/User');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Get all users (Admin, Manager)
router.get('/', checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER]), userController.getAllUsers);

// Get user by ID (Admin, Manager)
router.get('/:id', checkRole([USER_ROLES.ADMIN, USER_ROLES.MANAGER]), userController.getUserById);

// Create user (Admin only)
router.post('/', checkRole([USER_ROLES.ADMIN]), userController.updateUser);

// Update user (Admin only)
router.put('/:id', checkRole([USER_ROLES.ADMIN]), userController.updateUser);

// Delete user (Admin only)
router.delete('/:id', checkRole([USER_ROLES.ADMIN]), userController.deleteUser);

// Reset password (Admin only)
router.post('/:id/reset-password', checkRole([USER_ROLES.ADMIN]), userController.resetPassword);

module.exports = router;
