const { Factory } = require('../models/Factory');
const { Cylinder } = require('../models/Cylinder');
const { Op } = require('sequelize');

// Get all factories
exports.getAllFactories = async (req, res) => {
  try {
    const { search } = req.query;
    let whereClause = {};

    // Search by name or location if provided
    if (search) {
      whereClause = {
        [Op.or]: [
          { name: { [Op.iLike]: `%${search}%` } },
          { location: { [Op.iLike]: `%${search}%` } }
        ]
      };
    }

    const factories = await Factory.findAll({
      where: whereClause,
      order: [['name', 'ASC']]
    });

    res.status(200).json({ factories });
  } catch (error) {
    console.error('Get all factories error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get factory by ID
exports.getFactoryById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const factory = await Factory.findByPk(id);
    if (!factory) {
      return res.status(404).json({ message: 'Factory not found' });
    }

    // Get cylinder count for this factory
    const cylinderCount = await Cylinder.count({ where: { factoryId: id } });

    res.status(200).json({ 
      factory,
      cylinderCount 
    });
  } catch (error) {
    console.error('Get factory by ID error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Create factory
exports.createFactory = async (req, res) => {
  try {
    const {
      name,
      location,
      contact,
      email,
      description
    } = req.body;

    // Validate required fields
    if (!name || !location) {
      return res.status(400).json({ message: 'Please provide name and location' });
    }

    // Check if factory with the same name already exists
    const existingFactory = await Factory.findOne({ where: { name } });
    if (existingFactory) {
      return res.status(400).json({ message: 'Factory with this name already exists' });
    }

    // Create factory
    const factory = await Factory.create({
      name,
      location,
      contact: contact || '',
      email: email || null,
      description: description || ''
    });

    res.status(201).json({
      message: 'Factory created successfully',
      factory
    });
  } catch (error) {
    console.error('Create factory error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update factory
exports.updateFactory = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      location,
      contact,
      email,
      isActive,
      description
    } = req.body;

    // Find factory
    const factory = await Factory.findByPk(id);
    if (!factory) {
      return res.status(404).json({ message: 'Factory not found' });
    }

    // If name is changing, check for duplicates
    if (name && name !== factory.name) {
      const existingFactory = await Factory.findOne({ where: { name } });
      if (existingFactory && existingFactory.id !== parseInt(id)) {
        return res.status(400).json({ message: 'Factory with this name already exists' });
      }
      factory.name = name;
    }

    // Update fields
    if (location) factory.location = location;
    if (contact !== undefined) factory.contact = contact;
    if (email !== undefined) factory.email = email;
    if (isActive !== undefined) factory.isActive = isActive;
    if (description !== undefined) factory.description = description;

    await factory.save();

    res.status(200).json({
      message: 'Factory updated successfully',
      factory
    });
  } catch (error) {
    console.error('Update factory error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Delete factory
exports.deleteFactory = async (req, res) => {
  try {
    const { id } = req.params;

    // Find factory
    const factory = await Factory.findByPk(id);
    if (!factory) {
      return res.status(404).json({ message: 'Factory not found' });
    }

    // Check if factory has associated cylinders
    const cylinderCount = await Cylinder.count({ where: { factoryId: id } });
    if (cylinderCount > 0) {
      return res.status(400).json({ 
        message: 'Cannot delete factory with associated cylinders',
        cylinderCount
      });
    }

    await factory.destroy();
    res.status(200).json({ message: 'Factory deleted successfully' });
  } catch (error) {
    console.error('Delete factory error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get factory statistics
exports.getFactoryStats = async (req, res) => {
  try {
    const { id } = req.params;

    // Find factory
    const factory = await Factory.findByPk(id);
    if (!factory) {
      return res.status(404).json({ message: 'Factory not found' });
    }

    // Get cylinder counts by status
    const cylinders = await Cylinder.findAll({
      where: { factoryId: id },
      attributes: ['status', [sequelize.fn('COUNT', sequelize.col('id')), 'count']],
      group: ['status']
    });

    // Get cylinder counts by type
    const cylinderTypes = await Cylinder.findAll({
      where: { factoryId: id },
      attributes: ['type', [sequelize.fn('COUNT', sequelize.col('id')), 'count']],
      group: ['type']
    });

    res.status(200).json({
      factory: {
        id: factory.id,
        name: factory.name
      },
      stats: {
        statusCounts: cylinders,
        typeCounts: cylinderTypes,
        totalCylinders: cylinders.reduce((acc, item) => acc + parseInt(item.dataValues.count), 0)
      }
    });
  } catch (error) {
    console.error('Get factory stats error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
