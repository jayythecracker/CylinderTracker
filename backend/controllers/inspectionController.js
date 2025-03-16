const Inspection = require('../models/inspection');
const Cylinder = require('../models/cylinder');
const User = require('../models/user');
const { sequelize } = require('../config/db');
const { Op } = require('sequelize');

// Get all inspections with pagination and filters
const getAllInspections = async (req, res) => {
  try {
    const { 
      result,
      cylinderId,
      inspectedById,
      startDate,
      endDate,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter conditions
    const whereConditions = {};
    
    if (result) whereConditions.result = result;
    if (cylinderId) whereConditions.cylinderId = cylinderId;
    if (inspectedById) whereConditions.inspectedById = inspectedById;
    
    if (startDate && endDate) {
      whereConditions.inspectionDate = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    } else if (startDate) {
      whereConditions.inspectionDate = {
        [Op.gte]: new Date(startDate)
      };
    } else if (endDate) {
      whereConditions.inspectionDate = {
        [Op.lte]: new Date(endDate)
      };
    }
    
    // Pagination
    const offset = (page - 1) * limit;
    
    const { count, rows: inspections } = await Inspection.findAndCountAll({
      where: whereConditions,
      include: [
        { model: Cylinder },
        { model: User, as: 'InspectedBy', attributes: ['id', 'name'] }
      ],
      order: [['inspectionDate', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    res.status(200).json({
      inspections,
      totalCount: count,
      currentPage: parseInt(page),
      totalPages: Math.ceil(count / limit)
    });
  } catch (error) {
    console.error('Get all inspections error:', error);
    res.status(500).json({ message: 'Server error while fetching inspections' });
  }
};

// Get inspection by ID
const getInspectionById = async (req, res) => {
  try {
    const inspectionId = req.params.id;
    
    const inspection = await Inspection.findOne({
      where: { id: inspectionId },
      include: [
        { model: Cylinder },
        { model: User, as: 'InspectedBy', attributes: ['id', 'name'] }
      ]
    });
    
    if (!inspection) {
      return res.status(404).json({ message: 'Inspection not found' });
    }
    
    res.status(200).json({ inspection });
  } catch (error) {
    console.error('Get inspection by ID error:', error);
    res.status(500).json({ message: 'Server error while fetching inspection' });
  }
};

// Create new inspection
const createInspection = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { 
      cylinderId,
      pressureReading,
      visualInspection,
      result,
      notes
    } = req.body;
    
    const inspectedById = req.user.id;
    
    // Validate required fields
    if (!cylinderId || pressureReading === undefined || result === undefined) {
      await transaction.rollback();
      return res.status(400).json({ 
        message: 'Cylinder ID, pressure reading and result are required' 
      });
    }
    
    // Check if cylinder exists
    const cylinder = await Cylinder.findOne({
      where: { id: cylinderId, isActive: true },
      transaction
    });
    
    if (!cylinder) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Cylinder not found' });
    }
    
    // Create new inspection
    const newInspection = await Inspection.create({
      cylinderId,
      inspectedById,
      pressureReading,
      visualInspection: visualInspection !== undefined ? visualInspection : true,
      result,
      notes
    }, { transaction });
    
    // Update cylinder status based on inspection result
    if (result === 'Approved') {
      cylinder.status = cylinder.status === 'Full' ? 'Full' : 'Empty';
    } else {
      cylinder.status = 'Error';
    }
    
    cylinder.lastInspectionDate = new Date();
    await cylinder.save({ transaction });
    
    await transaction.commit();
    
    res.status(201).json({
      message: 'Inspection created successfully',
      inspection: newInspection
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Create inspection error:', error);
    res.status(500).json({ message: 'Server error while creating inspection' });
  }
};

// Batch inspect cylinders
const batchInspect = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { cylinderIds, result, notes } = req.body;
    const inspectedById = req.user.id;
    
    // Validate required fields
    if (!cylinderIds || !cylinderIds.length || result === undefined) {
      await transaction.rollback();
      return res.status(400).json({ 
        message: 'Cylinder IDs and result are required' 
      });
    }
    
    // Check if all cylinders exist
    const cylinders = await Cylinder.findAll({
      where: { 
        id: { [Op.in]: cylinderIds },
        isActive: true
      },
      transaction
    });
    
    if (cylinders.length !== cylinderIds.length) {
      await transaction.rollback();
      return res.status(400).json({ 
        message: 'One or more cylinders not found' 
      });
    }
    
    // Create inspection records and update cylinder statuses
    const inspections = [];
    for (const cylinder of cylinders) {
      // Create inspection record
      const newInspection = await Inspection.create({
        cylinderId: cylinder.id,
        inspectedById,
        pressureReading: cylinder.status === 'Full' ? cylinder.workingPressure : 0,
        visualInspection: true,
        result,
        notes
      }, { transaction });
      
      inspections.push(newInspection);
      
      // Update cylinder status
      if (result === 'Approved') {
        cylinder.status = cylinder.status === 'Full' ? 'Full' : 'Empty';
      } else {
        cylinder.status = 'Error';
      }
      
      cylinder.lastInspectionDate = new Date();
      await cylinder.save({ transaction });
    }
    
    await transaction.commit();
    
    res.status(201).json({
      message: 'Batch inspection completed successfully',
      inspectionCount: inspections.length
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Batch inspect error:', error);
    res.status(500).json({ message: 'Server error while performing batch inspection' });
  }
};

// Get cylinder inspection history
const getCylinderInspectionHistory = async (req, res) => {
  try {
    const cylinderId = req.params.cylinderId;
    
    // Check if cylinder exists
    const cylinder = await Cylinder.findOne({
      where: { id: cylinderId, isActive: true }
    });
    
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }
    
    // Get inspection history
    const inspections = await Inspection.findAll({
      where: { cylinderId },
      include: [
        { model: User, as: 'InspectedBy', attributes: ['id', 'name'] }
      ],
      order: [['inspectionDate', 'DESC']]
    });
    
    res.status(200).json({
      cylinder,
      inspections
    });
  } catch (error) {
    console.error('Get cylinder inspection history error:', error);
    res.status(500).json({ message: 'Server error while fetching cylinder inspection history' });
  }
};

module.exports = {
  getAllInspections,
  getInspectionById,
  createInspection,
  batchInspect,
  getCylinderInspectionHistory
};
