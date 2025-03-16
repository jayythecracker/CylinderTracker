const jwt = require('jsonwebtoken');

// JWT secret should be in environment variables in production
const JWT_SECRET = process.env.JWT_SECRET || 'cylinder-management-secret-key';
const JWT_EXPIRES_IN = '24h';

module.exports = {
  JWT_SECRET,
  JWT_EXPIRES_IN,
  
  // Generate JWT token
  generateToken: (userId, role) => {
    return jwt.sign(
      { 
        userId, 
        role 
      }, 
      JWT_SECRET, 
      { 
        expiresIn: JWT_EXPIRES_IN 
      }
    );
  },
  
  // Verify JWT token
  verifyToken: (token) => {
    try {
      return jwt.verify(token, JWT_SECRET);
    } catch (error) {
      return null;
    }
  }
};
