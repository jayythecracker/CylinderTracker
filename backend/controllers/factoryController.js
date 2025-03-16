const { Factory, Cylinder } = require('../models');
const { Op } = require('sequelize');

/**
 * Get all factories
 */
exports.getAllFactories = async (req, res) => {
  try {
    // Get query parameters for filtering
    const { active, search } = req.query;
    
    // Build filter object
    const filter = {};
    
    if (active !== undefined) {
      filter.active = active === 'true';
    }
    
    if (search) {
      filter[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { location: { [Op.iLike]: `%${search}%` } },
        { contact_person: { [Op.iLike]: `%${search}%` } }
      ];
    }
    
    // Find factories with filter
    const factories = await Factory.findAll({
      where: filter,
      order: [['name', 'ASC']]
    });
    
    // Send response
    res.json({
      success: true,
      data: { factories }
    });
  } catch (error) {
    console.error('Get all factories error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving factories',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get factory by ID
 */
exports.getFactoryById = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find factory with cylinders count
    const factory = await Factory.findByPk(id);
    
    if (!factory) {
      return res.status(404).json({
        success: false,
        message: 'Factory not found'
      });
    }
    
    // Get cylinders count
    const cylinderCount = await Cylinder.count({
      where: { factory_id: id }
    });
    
    // Send response
    res.json({
      success: true,
      data: { 
        factory: {
          ...factory.toJSON(),
          cylinderCount
        }
      }
    });
  } catch (error) {
    console.error('Get factory by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving factory',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Create new factory
 */
exports.createFactory = async (req, res) => {
  try {
    const { 
      name, 
      location, 
      contactPerson, 
      contactPhone, 
      email, 
      description 
    } = req.body;
    
    // Validate input
    if (!name || !location) {
      return res.status(400).json({
        success: false,
        message: 'Name and location are required'
      });
    }
    
    // Create new factory
    const factory = await Factory.create({
      name,
      location,
      contact_person: contactPerson,
      contact_phone: contactPhone,
      email,
      description
    });
    
    // Send response
    res.status(201).json({
      success: true,
      data: { factory }
    });
  } catch (error) {
    console.error('Create factory error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while creating factory',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Update factory
 */
exports.updateFactory = async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      name, 
      location, 
      contactPerson, 
      contactPhone, 
      email, 
      active, 
      description 
    } = req.body;
    
    // Find factory
    const factory = await Factory.findByPk(id);
    
    if (!factory) {
      return res.status(404).json({
        success: false,
        message: 'Factory not found'
      });
    }
    
    // Update factory fields
    await factory.update({
      name: name || factory.name,
      location: location || factory.location,
      contact_person: contactPerson !== undefined ? contactPerson : factory.contact_person,
      contact_phone: contactPhone !== undefined ? contactPhone : factory.contact_phone,
      email: email !== undefined ? email : factory.email,
      active: active !== undefined ? active : factory.active,
      description: description !== undefined ? description : factory.description
    });
    
    // Send response
    res.json({
      success: true,
      data: { factory }
    });
  } catch (error) {
    console.error('Update factory error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating factory',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Delete factory
 */
exports.deleteFactory = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find factory
    const factory = await Factory.findByPk(id);
    
    if (!factory) {
      return res.status(404).json({
        success: false,
        message: 'Factory not found'
      });
    }
    
    // Check if factory has cylinders
    const cylinderCount = await Cylinder.count({
      where: { factory_id: id }
    });
    
    if (cylinderCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete factory with ${cylinderCount} cylinders. Please reassign or delete cylinders first.`
      });
    }
    
    // Delete factory
    await factory.destroy();
    
    // Send response
    res.json({
      success: true,
      message: 'Factory deleted successfully'
    });
  } catch (error) {
    console.error('Delete factory error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while deleting factory',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get cylinders for a factory
 */
exports.getFactoryCylinders = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, type, search, page = 1, limit = 20 } = req.query;
    
    // Validate factory exists
    const factory = await Factory.findByPk(id);
    
    if (!factory) {
      return res.status(404).json({
        success: false,
        message: 'Factory not found'
      });
    }
    
    // Build filter object
    const filter = { factory_id: id };
    
    if (status) {
      filter.status = status;
    }
    
    if (type) {
      filter.type = type;
    }
    
    if (search) {
      filter[Op.or] = [
        { serial_number: { [Op.iLike]: `%${search}%` } }
      ];
    }
    
    // Calculate pagination
    const offset = (page - 1) * limit;
    
    // Find cylinders with pagination
    const { count, rows: cylinders } = await Cylinder.findAndCountAll({
      where: filter,
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    // Calculate total pages
    const totalPages = Math.ceil(count / limit);
    
    // Send response
    res.json({
      success: true,
      data: { 
        cylinders,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages
        }
      }
    });
  } catch (error) {
    console.error('Get factory cylinders error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving factory cylinders',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};
