const Factory = require('../models/factory');

// Get all factories
const getAllFactories = async (req, res) => {
  try {
    const factories = await Factory.findAll({
      where: { isActive: true }
    });
    
    res.status(200).json({ factories });
  } catch (error) {
    console.error('Get all factories error:', error);
    res.status(500).json({ message: 'Server error while fetching factories' });
  }
};

// Get factory by ID
const getFactoryById = async (req, res) => {
  try {
    const factoryId = req.params.id;
    
    const factory = await Factory.findOne({
      where: { id: factoryId, isActive: true }
    });
    
    if (!factory) {
      return res.status(404).json({ message: 'Factory not found' });
    }
    
    res.status(200).json({ factory });
  } catch (error) {
    console.error('Get factory by ID error:', error);
    res.status(500).json({ message: 'Server error while fetching factory' });
  }
};

// Create new factory
const createFactory = async (req, res) => {
  try {
    const { name, location, contactPerson, contactEmail, contactPhone } = req.body;
    
    // Validate required fields
    if (!name || !location) {
      return res.status(400).json({ message: 'Name and location are required' });
    }
    
    // Create new factory
    const newFactory = await Factory.create({
      name,
      location,
      contactPerson,
      contactEmail,
      contactPhone
    });
    
    res.status(201).json({
      message: 'Factory created successfully',
      factory: newFactory
    });
  } catch (error) {
    console.error('Create factory error:', error);
    res.status(500).json({ message: 'Server error while creating factory' });
  }
};

// Update factory
const updateFactory = async (req, res) => {
  try {
    const factoryId = req.params.id;
    const { name, location, contactPerson, contactEmail, contactPhone } = req.body;
    
    const factory = await Factory.findOne({
      where: { id: factoryId, isActive: true }
    });
    
    if (!factory) {
      return res.status(404).json({ message: 'Factory not found' });
    }
    
    // Update fields if provided
    if (name) factory.name = name;
    if (location) factory.location = location;
    if (contactPerson !== undefined) factory.contactPerson = contactPerson;
    if (contactEmail !== undefined) factory.contactEmail = contactEmail;
    if (contactPhone !== undefined) factory.contactPhone = contactPhone;
    
    await factory.save();
    
    res.status(200).json({
      message: 'Factory updated successfully',
      factory
    });
  } catch (error) {
    console.error('Update factory error:', error);
    res.status(500).json({ message: 'Server error while updating factory' });
  }
};

// Delete factory (soft delete by setting isActive to false)
const deleteFactory = async (req, res) => {
  try {
    const factoryId = req.params.id;
    
    const factory = await Factory.findByPk(factoryId);
    if (!factory) {
      return res.status(404).json({ message: 'Factory not found' });
    }
    
    // Soft delete
    factory.isActive = false;
    await factory.save();
    
    res.status(200).json({ message: 'Factory deleted successfully' });
  } catch (error) {
    console.error('Delete factory error:', error);
    res.status(500).json({ message: 'Server error while deleting factory' });
  }
};

module.exports = {
  getAllFactories,
  getFactoryById,
  createFactory,
  updateFactory,
  deleteFactory
};
