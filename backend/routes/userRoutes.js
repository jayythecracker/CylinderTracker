const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// All routes require authentication
router.use(authenticate);

// Get all users - admin only
router.get('/', authorize('admin'), userController.getAllUsers);

// Get user by ID - admin or the user themselves
router.get('/:id', (req, res, next) => {
  // Allow users to access their own profile
  if (req.params.id == req.user.id) {
    return next();
  }
  // Otherwise check for admin privileges
  authorize('admin')(req, res, next);
}, userController.getUserById);

// Create new user - admin only
router.post('/', authorize('admin'), userController.createUser);

// Update user - admin or the user themselves
router.put('/:id', (req, res, next) => {
  // Allow users to update their own profile
  if (req.params.id == req.user.id) {
    return next();
  }
  // Otherwise check for admin privileges
  authorize('admin')(req, res, next);
}, userController.updateUser);

// Reset user password - admin only
router.put('/:id/reset-password', authorize('admin'), userController.resetPassword);

// Delete user - admin only
router.delete('/:id', authorize('admin'), userController.deleteUser);

module.exports = router;
