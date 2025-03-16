const { Cylinder, CYLINDER_STATUSES, CYLINDER_TYPES } = require('../models/Cylinder');
const { Factory } = require('../models/Factory');
const { Op } = require('sequelize');
const crypto = require('crypto');

// Generate QR code for a cylinder
const generateQRCode = (serialNumber) => {
  // Create a unique QR code based on serial number
  return crypto.createHash('sha256').update(serialNumber + Date.now().toString()).digest('hex');
};

// Get all cylinders with pagination and filters
exports.getAllCylinders = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      status, 
      type, 
      factoryId, 
      search,
      sortBy = 'createdAt',
      order = 'DESC'
    } = req.query;

    const offset = (page - 1) * limit;
    let whereClause = {};

    // Apply filters
    if (status && Object.values(CYLINDER_STATUSES).includes(status)) {
      whereClause.status = status;
    }

    if (type && Object.values(CYLINDER_TYPES).includes(type)) {
      whereClause.type = type;
    }

    if (factoryId) {
      whereClause.factoryId = factoryId;
    }

    if (search) {
      whereClause = {
        ...whereClause,
        [Op.or]: [
          { serialNumber: { [Op.iLike]: `%${search}%` } },
          { originalNumber: { [Op.iLike]: `%${search}%` } }
        ]
      };
    }

    // Get cylinders with pagination
    const { count, rows: cylinders } = await Cylinder.findAndCountAll({
      where: whereClause,
      include: [
        {
          model: Factory,
          as: 'factory',
          attributes: ['id', 'name', 'location']
        }
      ],
      order: [[sortBy, order]],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.status(200).json({
      cylinders,
      totalCount: count,
      totalPages: Math.ceil(count / limit),
      currentPage: parseInt(page)
    });
  } catch (error) {
    console.error('Get all cylinders error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get cylinder by ID
exports.getCylinderById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const cylinder = await Cylinder.findByPk(id, {
      include: [
        {
          model: Factory,
          as: 'factory',
          attributes: ['id', 'name', 'location']
        }
      ]
    });

    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }

    res.status(200).json({ cylinder });
  } catch (error) {
    console.error('Get cylinder by ID error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get cylinder by QR code
exports.getCylinderByQR = async (req, res) => {
  try {
    const { qrCode } = req.params;
    
    const cylinder = await Cylinder.findOne({
      where: { qrCode },
      include: [
        {
          model: Factory,
          as: 'factory',
          attributes: ['id', 'name', 'location']
        }
      ]
    });

    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }

    res.status(200).json({ cylinder });
  } catch (error) {
    console.error('Get cylinder by QR error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Create cylinder
exports.createCylinder = async (req, res) => {
  try {
    const {
      serialNumber,
      size,
      importDate,
      productionDate,
      originalNumber,
      workingPressure,
      designPressure,
      type,
      factoryId,
      notes
    } = req.body;

    // Validate required fields
    if (!serialNumber || !size || !workingPressure || !designPressure || !factoryId) {
      return res.status(400).json({ message: 'Please provide all required fields' });
    }

    // Check if cylinder with serial number already exists
    const existingCylinder = await Cylinder.findOne({ where: { serialNumber } });
    if (existingCylinder) {
      return res.status(400).json({ message: 'Cylinder with this serial number already exists' });
    }

    // Check if factory exists
    const factory = await Factory.findByPk(factoryId);
    if (!factory) {
      return res.status(400).json({ message: 'Factory not found' });
    }

    // Generate QR code
    const qrCode = generateQRCode(serialNumber);

    // Create cylinder
    const cylinder = await Cylinder.create({
      serialNumber,
      size,
      importDate,
      productionDate,
      originalNumber,
      workingPressure,
      designPressure,
      type: type || CYLINDER_TYPES.INDUSTRIAL,
      status: CYLINDER_STATUSES.EMPTY,
      factoryId,
      notes,
      qrCode
    });

    res.status(201).json({
      message: 'Cylinder created successfully',
      cylinder
    });
  } catch (error) {
    console.error('Create cylinder error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update cylinder
exports.updateCylinder = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      serialNumber,
      size,
      importDate,
      productionDate,
      originalNumber,
      workingPressure,
      designPressure,
      type,
      status,
      factoryId,
      notes,
      isActive
    } = req.body;

    // Find cylinder
    const cylinder = await Cylinder.findByPk(id);
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }

    // If serial number is changed, check if it already exists
    if (serialNumber && serialNumber !== cylinder.serialNumber) {
      const existingCylinder = await Cylinder.findOne({ where: { serialNumber } });
      if (existingCylinder && existingCylinder.id !== parseInt(id)) {
        return res.status(400).json({ message: 'Cylinder with this serial number already exists' });
      }
      
      // Generate new QR code if serial number changes
      cylinder.qrCode = generateQRCode(serialNumber);
      cylinder.serialNumber = serialNumber;
    }

    // Update fields
    if (size) cylinder.size = size;
    if (importDate !== undefined) cylinder.importDate = importDate;
    if (productionDate !== undefined) cylinder.productionDate = productionDate;
    if (originalNumber !== undefined) cylinder.originalNumber = originalNumber;
    if (workingPressure) cylinder.workingPressure = workingPressure;
    if (designPressure) cylinder.designPressure = designPressure;
    if (type && Object.values(CYLINDER_TYPES).includes(type)) cylinder.type = type;
    if (status && Object.values(CYLINDER_STATUSES).includes(status)) cylinder.status = status;
    if (factoryId) {
      // Check if factory exists
      const factory = await Factory.findByPk(factoryId);
      if (!factory) {
        return res.status(400).json({ message: 'Factory not found' });
      }
      cylinder.factoryId = factoryId;
    }
    if (notes !== undefined) cylinder.notes = notes;
    if (isActive !== undefined) cylinder.isActive = isActive;

    await cylinder.save();

    res.status(200).json({
      message: 'Cylinder updated successfully',
      cylinder
    });
  } catch (error) {
    console.error('Update cylinder error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Delete cylinder
exports.deleteCylinder = async (req, res) => {
  try {
    const { id } = req.params;

    // Find cylinder
    const cylinder = await Cylinder.findByPk(id);
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }

    await cylinder.destroy();
    res.status(200).json({ message: 'Cylinder deleted successfully' });
  } catch (error) {
    console.error('Delete cylinder error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update cylinder status
exports.updateCylinderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    // Validate status
    if (!status || !Object.values(CYLINDER_STATUSES).includes(status)) {
      return res.status(400).json({ message: 'Please provide a valid status' });
    }

    // Find cylinder
    const cylinder = await Cylinder.findByPk(id);
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }

    // Update status
    cylinder.status = status;
    if (notes) cylinder.notes = notes;

    // Update date fields based on status
    if (status === CYLINDER_STATUSES.FILLED) {
      cylinder.lastFilled = new Date();
    } else if (status === CYLINDER_STATUSES.INSPECTION) {
      cylinder.lastInspected = new Date();
    }

    await cylinder.save();

    res.status(200).json({
      message: 'Cylinder status updated successfully',
      cylinder
    });
  } catch (error) {
    console.error('Update cylinder status error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Batch update cylinder status
exports.batchUpdateStatus = async (req, res) => {
  try {
    const { cylinderIds, status, notes } = req.body;

    // Validate inputs
    if (!cylinderIds || !Array.isArray(cylinderIds) || cylinderIds.length === 0) {
      return res.status(400).json({ message: 'Please provide cylinderIds array' });
    }

    if (!status || !Object.values(CYLINDER_STATUSES).includes(status)) {
      return res.status(400).json({ message: 'Please provide a valid status' });
    }

    // Update cylinders
    const updateData = {
      status,
      notes: notes || null
    };

    // Add date fields based on status
    if (status === CYLINDER_STATUSES.FILLED) {
      updateData.lastFilled = new Date();
    } else if (status === CYLINDER_STATUSES.INSPECTION) {
      updateData.lastInspected = new Date();
    }

    const [updatedCount] = await Cylinder.update(updateData, {
      where: { id: cylinderIds }
    });

    res.status(200).json({
      message: 'Cylinders updated successfully',
      updatedCount
    });
  } catch (error) {
    console.error('Batch update cylinder status error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
