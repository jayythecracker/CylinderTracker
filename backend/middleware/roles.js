const { rolePermissions } = require('../config/auth');

/**
 * Middleware to check if user has required permission
 * @param {string|string[]} requiredPermissions - Permission(s) required to access the resource
 */
const checkPermission = (requiredPermissions) => {
  return (req, res, next) => {
    // Get user from JWT middleware
    const { user } = req;
    
    if (!user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }

    const { role } = user;
    
    // Get permissions for the user's role
    const userPermissions = rolePermissions[role] || [];
    
    // If requiredPermissions is a string, convert to array
    const permissionsArray = Array.isArray(requiredPermissions) 
      ? requiredPermissions 
      : [requiredPermissions];
    
    // Check if user has all required permissions
    const hasPermission = permissionsArray.every(permission => 
      userPermissions.includes(permission)
    );
    
    if (!hasPermission) {
      return res.status(403).json({ 
        success: false, 
        message: 'You do not have permission to perform this action' 
      });
    }
    
    next();
  };
};

/**
 * Middleware to restrict access based on user role
 * @param {string|string[]} allowedRoles - Role(s) allowed to access the resource
 */
const restrictTo = (allowedRoles) => {
  return (req, res, next) => {
    // Get user from JWT middleware
    const { user } = req;
    
    if (!user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }
    
    const { role } = user;
    
    // If allowedRoles is a string, convert to array
    const rolesArray = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];
    
    if (!rolesArray.includes(role)) {
      return res.status(403).json({ 
        success: false, 
        message: 'You do not have permission to perform this action' 
      });
    }
    
    next();
  };
};

/**
 * Middleware for role-based access control (alias for restrictTo)
 * @param {string|string[]} roles - Role(s) allowed to access the resource
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized - No user found'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `User role ${req.user.role} is not authorized to access this resource`
      });
    }
    
    next();
  };
};

module.exports = {
  checkPermission,
  restrictTo,
  authorize
};
