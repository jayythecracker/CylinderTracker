const { pool } = require('../config/db');
const { hashPassword } = require('../config/auth');
const { users } = require('../../shared/schema');

// Create a user data access object
const User = {
  // Find user by ID
  findById: async (id) => {
    try {
      const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
      return result.rows[0];
    } catch (error) {
      console.error('Error finding user by ID:', error);
      throw error;
    }
  },
  
  // Find user by email
  findByEmail: async (email) => {
    try {
      const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      return result.rows[0];
    } catch (error) {
      console.error('Error finding user by email:', error);
      throw error;
    }
  },
  
  // Create a new user
  create: async (userData) => {
    try {
      // Hash password before storing
      const hashedPassword = await hashPassword(userData.password);
      
      const result = await pool.query(
        'INSERT INTO users (name, email, password, role, contact_number, address) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
        [
          userData.name,
          userData.email,
          hashedPassword,
          userData.role || 'seller',
          userData.contactNumber,
          userData.address
        ]
      );
      
      // Remove password from returned object
      const newUser = result.rows[0];
      delete newUser.password;
      
      return newUser;
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  },
  
  // Update user
  update: async (id, userData) => {
    try {
      // If password is being updated, hash it
      if (userData.password) {
        userData.password = await hashPassword(userData.password);
      }
      
      // Build the SET part of the query dynamically based on provided fields
      const setFields = [];
      const values = [];
      let paramCounter = 1;
      
      // Define mappings between camelCase and snake_case fields
      const fieldMappings = {
        name: 'name',
        email: 'email',
        password: 'password',
        role: 'role',
        contactNumber: 'contact_number',
        address: 'address',
        isActive: 'is_active'
      };
      
      // Add each field that's present in userData to the update query
      for (const [camelCaseField, snakeCaseField] of Object.entries(fieldMappings)) {
        if (userData[camelCaseField] !== undefined) {
          setFields.push(`${snakeCaseField} = $${paramCounter}`);
          values.push(userData[camelCaseField]);
          paramCounter++;
        }
      }
      
      // Add updated_at timestamp
      setFields.push(`updated_at = $${paramCounter}`);
      values.push(new Date());
      paramCounter++;
      
      // Add ID for WHERE clause
      values.push(id);
      
      // Construct and execute query
      const query = `
        UPDATE users 
        SET ${setFields.join(', ')} 
        WHERE id = $${paramCounter} 
        RETURNING *
      `;
      
      const result = await pool.query(query, values);
      
      // Remove password from returned object
      const updatedUser = result.rows[0];
      if (updatedUser) {
        delete updatedUser.password;
      }
      
      return updatedUser;
    } catch (error) {
      console.error('Error updating user:', error);
      throw error;
    }
  },
  
  // Utility to return user data without password
  sanitizeUser: (user) => {
    if (!user) return null;
    const sanitizedUser = { ...user };
    delete sanitizedUser.password;
    return sanitizedUser;
  }
};

module.exports = User;
