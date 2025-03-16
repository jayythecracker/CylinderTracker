const Cylinder = require('../models/cylinder');
const Factory = require('../models/factory');
const { Op } = require('sequelize');
const crypto = require('crypto');

// Generate a unique QR code
const generateQRCode = () => {
  return crypto.randomBytes(8).toString('hex');
};

// Get all cylinders with optional filters
const getAllCylinders = async (req, res) => {
  try {
    const { 
      status, 
      gasType, 
      factoryId, 
      size,
      search,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter conditions
    const whereConditions = { isActive: true };
    
    if (status) whereConditions.status = status;
    if (gasType) whereConditions.gasType = gasType;
    if (factoryId) whereConditions.factoryId = factoryId;
    if (size) whereConditions.size = size;
    
    if (search) {
      whereConditions[Op.or] = [
        { serialNumber: { [Op.iLike]: `%${search}%` } },
        { qrCode: { [Op.iLike]: `%${search}%` } },
        { originalNumber: { [Op.iLike]: `%${search}%` } }
      ];
    }
    
    // Pagination
    const offset = (page - 1) * limit;
    
    const { count, rows: cylinders } = await Cylinder.findAndCountAll({
      where: whereConditions,
      include: [{ model: Factory }],
      order: [['updatedAt', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    res.status(200).json({
      cylinders,
      totalCount: count,
      currentPage: parseInt(page),
      totalPages: Math.ceil(count / limit)
    });
  } catch (error) {
    console.error('Get all cylinders error:', error);
    res.status(500).json({ message: 'Server error while fetching cylinders' });
  }
};

// Get cylinder by ID
const getCylinderById = async (req, res) => {
  try {
    const cylinderId = req.params.id;
    
    const cylinder = await Cylinder.findOne({
      where: { id: cylinderId, isActive: true },
      include: [{ model: Factory }]
    });
    
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }
    
    res.status(200).json({ cylinder });
  } catch (error) {
    console.error('Get cylinder by ID error:', error);
    res.status(500).json({ message: 'Server error while fetching cylinder' });
  }
};

// Get cylinder by QR code
const getCylinderByQRCode = async (req, res) => {
  try {
    const { qrCode } = req.params;
    
    const cylinder = await Cylinder.findOne({
      where: { qrCode, isActive: true },
      include: [{ model: Factory }]
    });
    
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }
    
    res.status(200).json({ cylinder });
  } catch (error) {
    console.error('Get cylinder by QR error:', error);
    res.status(500).json({ message: 'Server error while fetching cylinder' });
  }
};

// Create new cylinder
const createCylinder = async (req, res) => {
  try {
    const { 
      serialNumber, 
      size, 
      importDate, 
      productionDate, 
      originalNumber,
      workingPressure,
      designPressure,
      gasType,
      factoryId
    } = req.body;
    
    // Validate required fields
    if (!serialNumber || !size || !productionDate || !workingPressure || !designPressure || !gasType || !factoryId) {
      return res.status(400).json({ 
        message: 'Serial number, size, production date, working pressure, design pressure, gas type, and factory ID are required' 
      });
    }
    
    // Check if factory exists
    const factory = await Factory.findByPk(factoryId);
    if (!factory) {
      return res.status(404).json({ message: 'Factory not found' });
    }
    
    // Check if serial number is unique
    const existingCylinder = await Cylinder.findOne({ where: { serialNumber } });
    if (existingCylinder) {
      return res.status(409).json({ message: 'Cylinder with this serial number already exists' });
    }
    
    // Generate QR code
    const qrCode = generateQRCode();
    
    // Create new cylinder
    const newCylinder = await Cylinder.create({
      serialNumber,
      qrCode,
      size,
      importDate,
      productionDate,
      originalNumber,
      workingPressure,
      designPressure,
      gasType,
      factoryId,
      status: 'Empty'
    });
    
    res.status(201).json({
      message: 'Cylinder created successfully',
      cylinder: newCylinder
    });
  } catch (error) {
    console.error('Create cylinder error:', error);
    res.status(500).json({ message: 'Server error while creating cylinder' });
  }
};

// Update cylinder
const updateCylinder = async (req, res) => {
  try {
    const cylinderId = req.params.id;
    const { 
      serialNumber, 
      size, 
      importDate, 
      productionDate, 
      originalNumber,
      workingPressure,
      designPressure,
      gasType,
      factoryId,
      status
    } = req.body;
    
    const cylinder = await Cylinder.findOne({
      where: { id: cylinderId, isActive: true }
    });
    
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }
    
    // Check if serial number is unique if changing
    if (serialNumber && serialNumber !== cylinder.serialNumber) {
      const existingCylinder = await Cylinder.findOne({ where: { serialNumber } });
      if (existingCylinder) {
        return res.status(409).json({ message: 'Cylinder with this serial number already exists' });
      }
      cylinder.serialNumber = serialNumber;
    }
    
    // Check if factory exists if changing
    if (factoryId && factoryId !== cylinder.factoryId) {
      const factory = await Factory.findByPk(factoryId);
      if (!factory) {
        return res.status(404).json({ message: 'Factory not found' });
      }
      cylinder.factoryId = factoryId;
    }
    
    // Update fields if provided
    if (size) cylinder.size = size;
    if (importDate !== undefined) cylinder.importDate = importDate;
    if (productionDate) cylinder.productionDate = productionDate;
    if (originalNumber !== undefined) cylinder.originalNumber = originalNumber;
    if (workingPressure) cylinder.workingPressure = workingPressure;
    if (designPressure) cylinder.designPressure = designPressure;
    if (gasType) cylinder.gasType = gasType;
    if (status) cylinder.status = status;
    
    await cylinder.save();
    
    res.status(200).json({
      message: 'Cylinder updated successfully',
      cylinder
    });
  } catch (error) {
    console.error('Update cylinder error:', error);
    res.status(500).json({ message: 'Server error while updating cylinder' });
  }
};

// Delete cylinder (soft delete)
const deleteCylinder = async (req, res) => {
  try {
    const cylinderId = req.params.id;
    
    const cylinder = await Cylinder.findByPk(cylinderId);
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }
    
    // Soft delete
    cylinder.isActive = false;
    await cylinder.save();
    
    res.status(200).json({ message: 'Cylinder deleted successfully' });
  } catch (error) {
    console.error('Delete cylinder error:', error);
    res.status(500).json({ message: 'Server error while deleting cylinder' });
  }
};

// Update cylinder status
const updateCylinderStatus = async (req, res) => {
  try {
    const cylinderId = req.params.id;
    const { status } = req.body;
    
    if (!status) {
      return res.status(400).json({ message: 'Status is required' });
    }
    
    const cylinder = await Cylinder.findOne({
      where: { id: cylinderId, isActive: true }
    });
    
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }
    
    cylinder.status = status;
    
    // If marked as filled, update last filled date
    if (status === 'Full') {
      cylinder.lastFilledDate = new Date();
    }
    
    // If marked as inspected, update last inspection date
    if (status === 'Empty' || status === 'Full') {
      cylinder.lastInspectionDate = new Date();
    }
    
    await cylinder.save();
    
    res.status(200).json({
      message: 'Cylinder status updated successfully',
      cylinder
    });
  } catch (error) {
    console.error('Update cylinder status error:', error);
    res.status(500).json({ message: 'Server error while updating cylinder status' });
  }
};

module.exports = {
  getAllCylinders,
  getCylinderById,
  getCylinderByQRCode,
  createCylinder,
  updateCylinder,
  deleteCylinder,
  updateCylinderStatus
};
