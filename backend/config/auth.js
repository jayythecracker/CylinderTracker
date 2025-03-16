/**
 * Authentication and Authorization Configuration
 */

// Import shared config
const config = require('./config');

module.exports = {
  jwtSecret: process.env.JWT_SECRET || config.jwt.secret,
  jwtExpiresIn: config.jwt.expiresIn,
  saltRounds: 10,
  roles: {
    ADMIN: 'admin',
    MANAGER: 'manager',
    FILLER: 'filler',
    INSPECTOR: 'inspector',
    SELLER: 'seller',
    VIEWER: 'viewer'
  },
  permissions: {
    // User management permissions
    CREATE_USER: 'create_user',
    READ_USER: 'read_user',
    UPDATE_USER: 'update_user',
    DELETE_USER: 'delete_user',
    
    // Factory and cylinder permissions
    CREATE_FACTORY: 'create_factory',
    READ_FACTORY: 'read_factory',
    UPDATE_FACTORY: 'update_factory',
    DELETE_FACTORY: 'delete_factory',
    
    CREATE_CYLINDER: 'create_cylinder',
    READ_CYLINDER: 'read_cylinder',
    UPDATE_CYLINDER: 'update_cylinder',
    DELETE_CYLINDER: 'delete_cylinder',
    
    // Customer permissions
    CREATE_CUSTOMER: 'create_customer',
    READ_CUSTOMER: 'read_customer',
    UPDATE_CUSTOMER: 'update_customer',
    DELETE_CUSTOMER: 'delete_customer',
    
    // Filling permissions
    CREATE_FILLING: 'create_filling',
    READ_FILLING: 'read_filling',
    UPDATE_FILLING: 'update_filling',
    
    // Inspection permissions
    CREATE_INSPECTION: 'create_inspection',
    READ_INSPECTION: 'read_inspection',
    UPDATE_INSPECTION: 'update_inspection',
    
    // Sales permissions
    CREATE_SALE: 'create_sale',
    READ_SALE: 'read_sale',
    UPDATE_SALE: 'update_sale',
    
    // Report permissions
    VIEW_REPORTS: 'view_reports',
    GENERATE_REPORTS: 'generate_reports'
  },
  
  // Role-based permission mapping
  rolePermissions: {
    admin: [
      // Admin has all permissions
      'create_user', 'read_user', 'update_user', 'delete_user',
      'create_factory', 'read_factory', 'update_factory', 'delete_factory',
      'create_cylinder', 'read_cylinder', 'update_cylinder', 'delete_cylinder',
      'create_customer', 'read_customer', 'update_customer', 'delete_customer',
      'create_filling', 'read_filling', 'update_filling',
      'create_inspection', 'read_inspection', 'update_inspection',
      'create_sale', 'read_sale', 'update_sale',
      'view_reports', 'generate_reports'
    ],
    
    manager: [
      // Manager can create and manage most entities but cannot delete users or factories
      'read_user', 'update_user',
      'read_factory', 'update_factory',
      'create_cylinder', 'read_cylinder', 'update_cylinder',
      'create_customer', 'read_customer', 'update_customer',
      'create_filling', 'read_filling', 'update_filling',
      'create_inspection', 'read_inspection', 'update_inspection',
      'create_sale', 'read_sale', 'update_sale',
      'view_reports', 'generate_reports'
    ],
    
    filler: [
      // Filler can manage filling operations and view customers and cylinders
      'read_cylinder', 'update_cylinder',
      'read_customer',
      'create_filling', 'read_filling', 'update_filling'
    ],
    
    inspector: [
      // Inspector can perform inspections and view cylinders
      'read_cylinder', 'update_cylinder',
      'create_inspection', 'read_inspection', 'update_inspection'
    ],
    
    seller: [
      // Seller can manage sales and view customers and cylinders
      'read_cylinder',
      'read_customer', 'update_customer',
      'read_filling',
      'read_inspection',
      'create_sale', 'read_sale', 'update_sale'
    ],
    
    viewer: [
      // Viewer has read-only permissions
      'read_user',
      'read_factory',
      'read_cylinder',
      'read_customer',
      'read_filling',
      'read_inspection',
      'read_sale',
      'view_reports'
    ]
  }
};
