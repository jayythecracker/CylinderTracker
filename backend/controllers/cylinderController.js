const { Cylinder, Factory, Filling, Inspection, User } = require('../models');
const { Op } = require('sequelize');
const broadcast = require('../utils/broadcast');

/**
 * Get all cylinders with pagination and filtering
 */
exports.getAllCylinders = async (req, res) => {
  try {
    // Get query parameters for filtering and pagination
    const { 
      status, 
      type, 
      factoryId, 
      search,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter object
    const filter = {};
    
    if (status) {
      filter.status = status;
    }
    
    if (type) {
      filter.type = type;
    }
    
    if (factoryId) {
      filter.factory_id = factoryId;
    }
    
    if (search) {
      filter[Op.or] = [
        { serial_number: { [Op.iLike]: `%${search}%` } }
      ];
    }
    
    // Calculate pagination
    const offset = (page - 1) * limit;
    
    // Find cylinders with pagination and include factory info
    const { count, rows: cylinders } = await Cylinder.findAndCountAll({
      where: filter,
      include: [
        { model: Factory, as: 'factory', attributes: ['id', 'name'] }
      ],
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
    console.error('Get all cylinders error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving cylinders',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get cylinder by ID or QR code
 */
exports.getCylinder = async (req, res) => {
  try {
    const { id } = req.params;
    const { qrCode } = req.query;
    
    let cylinder;
    
    // Find by QR code if provided, otherwise by ID
    if (qrCode) {
      cylinder = await Cylinder.findOne({
        where: { qr_code: qrCode },
        include: [
          { model: Factory, as: 'factory', attributes: ['id', 'name'] }
        ]
      });
    } else {
      cylinder = await Cylinder.findByPk(id, {
        include: [
          { model: Factory, as: 'factory', attributes: ['id', 'name'] }
        ]
      });
    }
    
    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }
    
    // Get last filling information
    const lastFilling = await Filling.findOne({
      where: { cylinder_id: cylinder.id },
      order: [['created_at', 'DESC']]
    });
    
    // Get last inspection information
    const lastInspection = await Inspection.findOne({
      where: { cylinder_id: cylinder.id },
      order: [['created_at', 'DESC']]
    });
    
    // Send response
    res.json({
      success: true,
      data: { 
        cylinder,
        lastFilling,
        lastInspection
      }
    });
  } catch (error) {
    console.error('Get cylinder error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving cylinder',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Create new cylinder
 */
exports.createCylinder = async (req, res) => {
  try {
    const { 
      serialNumber, 
      size, 
      type, 
      importDate, 
      productionDate, 
      originalNumber, 
      workingPressure, 
      designPressure, 
      factoryId,
      notes
    } = req.body;
    
    // Validate input
    if (!serialNumber || !size || !type || !productionDate || !workingPressure || !designPressure || !factoryId) {
      return res.status(400).json({
        success: false,
        message: 'Serial number, size, type, production date, working pressure, design pressure, and factory ID are required'
      });
    }
    
    // Check if factory exists
    const factory = await Factory.findByPk(factoryId);
    
    if (!factory) {
      return res.status(400).json({
        success: false,
        message: 'Factory not found'
      });
    }
    
    // Check if cylinder with same serial number already exists
    const existingCylinder = await Cylinder.findOne({
      where: { serial_number: serialNumber }
    });
    
    if (existingCylinder) {
      return res.status(400).json({
        success: false,
        message: 'A cylinder with this serial number already exists'
      });
    }
    
    // Create new cylinder
    const cylinder = await Cylinder.create({
      serial_number: serialNumber,
      size,
      type,
      import_date: importDate || null,
      production_date: productionDate,
      original_number: originalNumber || null,
      working_pressure: workingPressure,
      design_pressure: designPressure,
      factory_id: factoryId,
      notes: notes || null
    });
    
    // Get factory details for response
    const cylWithFactory = await Cylinder.findByPk(cylinder.id, {
      include: [
        { model: Factory, as: 'factory', attributes: ['id', 'name'] }
      ]
    });
    
    // Broadcast cylinder creation
    broadcast.cylinderCreated(cylWithFactory);
    
    // Send response
    res.status(201).json({
      success: true,
      data: { cylinder: cylWithFactory }
    });
  } catch (error) {
    console.error('Create cylinder error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while creating cylinder',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Update cylinder
 */
exports.updateCylinder = async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      serialNumber, 
      size, 
      type, 
      importDate, 
      productionDate, 
      originalNumber, 
      workingPressure, 
      designPressure, 
      status,
      factoryId,
      notes
    } = req.body;
    
    // Find cylinder
    const cylinder = await Cylinder.findByPk(id);
    
    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }
    
    // Check if new serial number is already in use by another cylinder
    if (serialNumber && serialNumber !== cylinder.serial_number) {
      const existingCylinder = await Cylinder.findOne({
        where: { 
          serial_number: serialNumber,
          id: { [Op.ne]: id }
        }
      });
      
      if (existingCylinder) {
        return res.status(400).json({
          success: false,
          message: 'A cylinder with this serial number already exists'
        });
      }
    }
    
    // If factory ID is provided, check if factory exists
    if (factoryId && factoryId !== cylinder.factory_id) {
      const factory = await Factory.findByPk(factoryId);
      
      if (!factory) {
        return res.status(400).json({
          success: false,
          message: 'Factory not found'
        });
      }
    }
    
    // Update cylinder fields
    await cylinder.update({
      serial_number: serialNumber || cylinder.serial_number,
      size: size || cylinder.size,
      type: type || cylinder.type,
      import_date: importDate !== undefined ? importDate : cylinder.import_date,
      production_date: productionDate || cylinder.production_date,
      original_number: originalNumber !== undefined ? originalNumber : cylinder.original_number,
      working_pressure: workingPressure || cylinder.working_pressure,
      design_pressure: designPressure || cylinder.design_pressure,
      status: status || cylinder.status,
      factory_id: factoryId || cylinder.factory_id,
      notes: notes !== undefined ? notes : cylinder.notes
    });
    
    // Get updated cylinder with factory details
    const updatedCylinder = await Cylinder.findByPk(id, {
      include: [
        { model: Factory, as: 'factory', attributes: ['id', 'name'] }
      ]
    });
    
    // Broadcast cylinder update
    broadcast.cylinderUpdated(updatedCylinder);
    
    // Send response
    res.json({
      success: true,
      data: { cylinder: updatedCylinder }
    });
  } catch (error) {
    console.error('Update cylinder error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating cylinder',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Delete cylinder
 */
exports.deleteCylinder = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find cylinder
    const cylinder = await Cylinder.findByPk(id);
    
    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }
    
    // Check if cylinder has fillings
    const fillingCount = await Filling.count({
      where: { cylinder_id: id }
    });
    
    if (fillingCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete cylinder with ${fillingCount} filling records. Consider updating its status instead.`
      });
    }
    
    // Store the ID before deleting (for broadcasting)
    const cylinderId = cylinder.id;
    
    // Delete cylinder
    await cylinder.destroy();
    
    // Broadcast cylinder deletion
    broadcast.cylinderDeleted(cylinderId);
    
    // Send response
    res.json({
      success: true,
      message: 'Cylinder deleted successfully'
    });
  } catch (error) {
    console.error('Delete cylinder error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while deleting cylinder',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Update cylinder status (e.g., for maintenance)
 */
exports.updateStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    
    // Validate input
    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required'
      });
    }
    
    // Find cylinder
    const cylinder = await Cylinder.findByPk(id);
    
    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }
    
    // Update status
    await cylinder.update({
      status,
      notes: notes !== undefined ? notes : cylinder.notes
    });
    
    // Broadcast status update
    broadcast.cylinderStatusUpdated({
      id: cylinder.id,
      status: status,
      notes: cylinder.notes
    });
    
    // Send response
    res.json({
      success: true,
      data: { cylinder }
    });
  } catch (error) {
    console.error('Update cylinder status error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating cylinder status',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get cylinder history (fillings and inspections)
 */
exports.getCylinderHistory = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find cylinder
    const cylinder = await Cylinder.findByPk(id);
    
    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }
    
    // Get filling history
    const fillings = await Filling.findAll({
      where: { cylinder_id: id },
      include: [
        { model: User, as: 'startedBy', attributes: ['id', 'name'] },
        { model: User, as: 'endedBy', attributes: ['id', 'name'] }
      ],
      order: [['created_at', 'DESC']]
    });
    
    // Get inspection history
    const inspections = await Inspection.findAll({
      where: { cylinder_id: id },
      include: [
        { model: User, as: 'inspectedBy', attributes: ['id', 'name'] }
      ],
      order: [['created_at', 'DESC']]
    });
    
    // Send response
    res.json({
      success: true,
      data: { 
        cylinder,
        history: {
          fillings,
          inspections
        }
      }
    });
  } catch (error) {
    console.error('Get cylinder history error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving cylinder history',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};
