const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authenticateJWT = require('../middleware/auth');
const { checkPermission } = require('../middleware/roles');
const { permissions } = require('../config/auth');

// All routes require authentication
router.use(authenticateJWT);

// Get all users (admin and manager)
router.get(
  '/',
  checkPermission(permissions.READ_USER),
  userController.getAllUsers
);

// Get user by ID
router.get(
  '/:id',
  checkPermission(permissions.READ_USER),
  userController.getUserById
);

// Create new user (admin only)
router.post(
  '/',
  checkPermission(permissions.CREATE_USER),
  userController.createUser
);

// Update user
router.put(
  '/:id',
  checkPermission(permissions.UPDATE_USER),
  userController.updateUser
);

// Reset user password (admin only)
router.post(
  '/:id/reset-password',
  checkPermission(permissions.UPDATE_USER),
  userController.resetPassword
);

// Delete user (admin only)
router.delete(
  '/:id',
  checkPermission(permissions.DELETE_USER),
  userController.deleteUser
);

module.exports = router;
