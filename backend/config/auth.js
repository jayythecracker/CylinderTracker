const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

// JWT secret key
const JWT_SECRET = process.env.JWT_SECRET || 'cylmanagement-secret-key';
const JWT_EXPIRY = '24h';

// Function to generate JWT token
const generateToken = (user) => {
  return jwt.sign(
    { 
      id: user.id, 
      email: user.email, 
      role: user.role 
    }, 
    JWT_SECRET, 
    { expiresIn: JWT_EXPIRY }
  );
};

// Function to verify JWT token
const verifyToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

// Function to hash password
const hashPassword = async (password) => {
  const salt = await bcrypt.genSalt(10);
  return await bcrypt.hash(password, salt);
};

// Function to compare password with hash
const comparePassword = async (password, hash) => {
  return await bcrypt.compare(password, hash);
};

// Role hierarchy for access control
const roleHierarchy = {
  admin: ['admin', 'manager', 'filler', 'seller'],
  manager: ['manager', 'filler', 'seller'],
  filler: ['filler'],
  seller: ['seller']
};

// Function to check if user has required role
const hasRole = (userRole, requiredRole) => {
  return roleHierarchy[userRole]?.includes(requiredRole) || false;
};

module.exports = {
  generateToken,
  verifyToken,
  hashPassword,
  comparePassword,
  hasRole,
  JWT_SECRET
};
