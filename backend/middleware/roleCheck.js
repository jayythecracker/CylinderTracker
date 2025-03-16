const { User } = require('../models/User');

// Role-based access control middleware
exports.checkRole = (allowedRoles) => {
  return async (req, res, next) => {
    try {
      const { userId, role } = req.user;

      // If no role information in token, fetch from database
      if (!role) {
        const user = await User.findByPk(userId);
        
        if (!user) {
          return res.status(404).json({ message: 'User not found' });
        }
        
        if (!user.isActive) {
          return res.status(403).json({ message: 'User account is inactive' });
        }
        
        if (!allowedRoles.includes(user.role)) {
          return res.status(403).json({ 
            message: 'Access denied. Insufficient permissions.',
            required: allowedRoles,
            current: user.role
          });
        }
      } else {
        // Check if user role is in allowed roles
        if (!allowedRoles.includes(role)) {
          return res.status(403).json({ 
            message: 'Access denied. Insufficient permissions.',
            required: allowedRoles,
            current: role
          });
        }
      }
      
      next();
    } catch (error) {
      console.error('Role check error:', error);
      res.status(500).json({ message: 'Server error during permission check' });
    }
  };
};
