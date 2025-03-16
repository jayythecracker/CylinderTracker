const { FillingLine, FillingBatch, FillingDetail } = require('../models/filling');
const Cylinder = require('../models/cylinder');
const User = require('../models/user');
const { sequelize } = require('../config/db');
const { Op } = require('sequelize');

// Get all filling lines
const getAllFillingLines = async (req, res) => {
  try {
    const fillingLines = await FillingLine.findAll({
      where: { isActive: true },
      order: [['name', 'ASC']]
    });
    
    res.status(200).json({ fillingLines });
  } catch (error) {
    console.error('Get all filling lines error:', error);
    res.status(500).json({ message: 'Server error while fetching filling lines' });
  }
};

// Get filling line by ID
const getFillingLineById = async (req, res) => {
  try {
    const lineId = req.params.id;
    
    const fillingLine = await FillingLine.findOne({
      where: { id: lineId, isActive: true }
    });
    
    if (!fillingLine) {
      return res.status(404).json({ message: 'Filling line not found' });
    }
    
    res.status(200).json({ fillingLine });
  } catch (error) {
    console.error('Get filling line by ID error:', error);
    res.status(500).json({ message: 'Server error while fetching filling line' });
  }
};

// Create new filling line
const createFillingLine = async (req, res) => {
  try {
    const { name, capacity, gasType } = req.body;
    
    // Validate required fields
    if (!name || !capacity || !gasType) {
      return res.status(400).json({ 
        message: 'Name, capacity, and gas type are required' 
      });
    }
    
    // Create new filling line
    const newFillingLine = await FillingLine.create({
      name,
      capacity: parseInt(capacity),
      gasType,
      status: 'Idle'
    });
    
    res.status(201).json({
      message: 'Filling line created successfully',
      fillingLine: newFillingLine
    });
  } catch (error) {
    console.error('Create filling line error:', error);
    res.status(500).json({ message: 'Server error while creating filling line' });
  }
};

// Update filling line
const updateFillingLine = async (req, res) => {
  try {
    const lineId = req.params.id;
    const { name, capacity, gasType, status } = req.body;
    
    const fillingLine = await FillingLine.findOne({
      where: { id: lineId, isActive: true }
    });
    
    if (!fillingLine) {
      return res.status(404).json({ message: 'Filling line not found' });
    }
    
    // Update fields if provided
    if (name) fillingLine.name = name;
    if (capacity) fillingLine.capacity = parseInt(capacity);
    if (gasType) fillingLine.gasType = gasType;
    if (status) fillingLine.status = status;
    
    await fillingLine.save();
    
    res.status(200).json({
      message: 'Filling line updated successfully',
      fillingLine
    });
  } catch (error) {
    console.error('Update filling line error:', error);
    res.status(500).json({ message: 'Server error while updating filling line' });
  }
};

// Delete filling line (soft delete)
const deleteFillingLine = async (req, res) => {
  try {
    const lineId = req.params.id;
    
    const fillingLine = await FillingLine.findByPk(lineId);
    if (!fillingLine) {
      return res.status(404).json({ message: 'Filling line not found' });
    }
    
    // Soft delete
    fillingLine.isActive = false;
    await fillingLine.save();
    
    res.status(200).json({ message: 'Filling line deleted successfully' });
  } catch (error) {
    console.error('Delete filling line error:', error);
    res.status(500).json({ message: 'Server error while deleting filling line' });
  }
};

// Start new filling batch
const startFillingBatch = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { fillingLineId, cylinderIds, notes } = req.body;
    const userId = req.user.id;
    
    // Validate required fields
    if (!fillingLineId || !cylinderIds || !cylinderIds.length) {
      await transaction.rollback();
      return res.status(400).json({ 
        message: 'Filling line ID and at least one cylinder are required' 
      });
    }
    
    // Check if filling line exists and is available
    const fillingLine = await FillingLine.findOne({
      where: { id: fillingLineId, isActive: true, status: 'Idle' },
      transaction
    });
    
    if (!fillingLine) {
      await transaction.rollback();
      return res.status(404).json({ 
        message: 'Filling line not found or is currently in use' 
      });
    }
    
    // Check if number of cylinders exceeds line capacity
    if (cylinderIds.length > fillingLine.capacity) {
      await transaction.rollback();
      return res.status(400).json({ 
        message: `Filling line capacity (${fillingLine.capacity}) exceeded` 
      });
    }
    
    // Check if all cylinders exist, are empty, and match line gas type
    const cylinders = await Cylinder.findAll({
      where: { 
        id: { [Op.in]: cylinderIds },
        isActive: true,
        status: 'Empty',
        gasType: fillingLine.gasType
      },
      transaction
    });
    
    if (cylinders.length !== cylinderIds.length) {
      await transaction.rollback();
      return res.status(400).json({ 
        message: 'One or more cylinders are not available for filling or do not match line gas type' 
      });
    }
    
    // Generate batch number
    const batchNumber = `FILL-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    
    // Create filling batch
    const newBatch = await FillingBatch.create({
      batchNumber,
      fillingLineId,
      startedById: userId,
      status: 'In Progress',
      notes
    }, { transaction });
    
    // Create filling details for each cylinder
    const fillingDetails = await Promise.all(
      cylinders.map(cylinder => 
        FillingDetail.create({
          fillingBatchId: newBatch.id,
          cylinderId: cylinder.id,
          initialPressure: 0,
          status: 'In Progress'
        }, { transaction })
      )
    );
    
    // Update cylinders status
    await Promise.all(
      cylinders.map(cylinder => {
        cylinder.status = 'In Filling';
        return cylinder.save({ transaction });
      })
    );
    
    // Update filling line status
    fillingLine.status = 'Active';
    await fillingLine.save({ transaction });
    
    await transaction.commit();
    
    res.status(201).json({
      message: 'Filling batch started successfully',
      batch: newBatch,
      details: fillingDetails
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Start filling batch error:', error);
    res.status(500).json({ message: 'Server error while starting filling batch' });
  }
};

// Complete filling batch
const completeFillingBatch = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const batchId = req.params.id;
    const { cylinderResults, notes } = req.body;
    const userId = req.user.id;
    
    // Validate required fields
    if (!cylinderResults || !Array.isArray(cylinderResults)) {
      await transaction.rollback();
      return res.status(400).json({ message: 'Cylinder results are required' });
    }
    
    // Check if batch exists and is in progress
    const batch = await FillingBatch.findOne({
      where: { id: batchId, status: 'In Progress' },
      include: [
        { model: FillingLine }
      ],
      transaction
    });
    
    if (!batch) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Filling batch not found or already completed' });
    }
    
    // Get all filling details for this batch
    const fillingDetails = await FillingDetail.findAll({
      where: { fillingBatchId: batchId },
      include: [{ model: Cylinder }],
      transaction
    });
    
    // Create a map for quick lookup
    const detailsMap = new Map();
    fillingDetails.forEach(detail => {
      detailsMap.set(detail.cylinderId.toString(), detail);
    });
    
    // Process each cylinder result
    for (const result of cylinderResults) {
      const { cylinderId, finalPressure, status, notes: cylinderNotes } = result;
      
      const detail = detailsMap.get(cylinderId.toString());
      if (!detail) {
        await transaction.rollback();
        return res.status(400).json({ 
          message: `Cylinder ID ${cylinderId} is not part of this batch` 
        });
      }
      
      // Update filling detail
      detail.finalPressure = finalPressure;
      detail.status = status;
      if (cylinderNotes) detail.notes = cylinderNotes;
      await detail.save({ transaction });
      
      // Update cylinder status based on filling result
      const cylinder = detail.Cylinder;
      cylinder.status = status === 'Success' ? 'Full' : status === 'Failed' ? 'Error' : 'Empty';
      if (status === 'Success') {
        cylinder.lastFilledDate = new Date();
      }
      await cylinder.save({ transaction });
    }
    
    // Complete the batch
    batch.endTime = new Date();
    batch.endedById = userId;
    batch.status = 'Completed';
    if (notes) batch.notes = notes;
    await batch.save({ transaction });
    
    // Update filling line status
    const fillingLine = batch.FillingLine;
    fillingLine.status = 'Idle';
    await fillingLine.save({ transaction });
    
    await transaction.commit();
    
    res.status(200).json({
      message: 'Filling batch completed successfully',
      batch
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Complete filling batch error:', error);
    res.status(500).json({ message: 'Server error while completing filling batch' });
  }
};

// Get filling batch by ID
const getFillingBatchById = async (req, res) => {
  try {
    const batchId = req.params.id;
    
    const batch = await FillingBatch.findOne({
      where: { id: batchId },
      include: [
        { model: FillingLine },
        { model: User, as: 'StartedBy', attributes: ['id', 'name'] },
        { model: User, as: 'EndedBy', attributes: ['id', 'name'] },
        { 
          model: FillingDetail,
          include: [{ model: Cylinder }]
        }
      ]
    });
    
    if (!batch) {
      return res.status(404).json({ message: 'Filling batch not found' });
    }
    
    res.status(200).json({ batch });
  } catch (error) {
    console.error('Get filling batch by ID error:', error);
    res.status(500).json({ message: 'Server error while fetching filling batch' });
  }
};

// Get all filling batches with pagination and filters
const getAllFillingBatches = async (req, res) => {
  try {
    const { 
      status,
      fillingLineId,
      startDate,
      endDate,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter conditions
    const whereConditions = {};
    
    if (status) whereConditions.status = status;
    if (fillingLineId) whereConditions.fillingLineId = fillingLineId;
    
    if (startDate && endDate) {
      whereConditions.startTime = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    } else if (startDate) {
      whereConditions.startTime = {
        [Op.gte]: new Date(startDate)
      };
    } else if (endDate) {
      whereConditions.startTime = {
        [Op.lte]: new Date(endDate)
      };
    }
    
    // Pagination
    const offset = (page - 1) * limit;
    
    const { count, rows: batches } = await FillingBatch.findAndCountAll({
      where: whereConditions,
      include: [
        { model: FillingLine },
        { model: User, as: 'StartedBy', attributes: ['id', 'name'] },
        { model: User, as: 'EndedBy', attributes: ['id', 'name'] }
      ],
      order: [['startTime', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    res.status(200).json({
      batches,
      totalCount: count,
      currentPage: parseInt(page),
      totalPages: Math.ceil(count / limit)
    });
  } catch (error) {
    console.error('Get all filling batches error:', error);
    res.status(500).json({ message: 'Server error while fetching filling batches' });
  }
};

module.exports = {
  getAllFillingLines,
  getFillingLineById,
  createFillingLine,
  updateFillingLine,
  deleteFillingLine,
  startFillingBatch,
  completeFillingBatch,
  getFillingBatchById,
  getAllFillingBatches
};
