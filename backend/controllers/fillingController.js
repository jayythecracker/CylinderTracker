const { Filling, Cylinder, User } = require('../models');
const { Op } = require('sequelize');

/**
 * Get all fillings with pagination and filtering
 */
exports.getAllFillings = async (req, res) => {
  try {
    // Get query parameters for filtering and pagination
    const { 
      status, 
      lineNumber, 
      startDate, 
      endDate,
      startedById,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter object
    const filter = {};
    
    if (status) {
      filter.status = status;
    }
    
    if (lineNumber) {
      filter.lineNumber = lineNumber;
    }
    
    if (startedById) {
      filter.startedById = startedById;
    }
    
    // Date range filter
    if (startDate || endDate) {
      filter.startTime = {};
      
      if (startDate) {
        filter.startTime[Op.gte] = new Date(startDate);
      }
      
      if (endDate) {
        const endDateTime = new Date(endDate);
        endDateTime.setHours(23, 59, 59, 999);
        filter.startTime[Op.lte] = endDateTime;
      }
    }
    
    // Calculate pagination
    const offset = (page - 1) * limit;
    
    // Find fillings with pagination
    const { count, rows: fillings } = await Filling.findAndCountAll({
      where: filter,
      include: [
        { model: Cylinder, as: 'cylinder', attributes: ['id', 'serialNumber', 'size', 'type'] },
        { model: User, as: 'startedBy', attributes: ['id', 'name'] },
        { model: User, as: 'endedBy', attributes: ['id', 'name'] }
      ],
      order: [['startTime', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    // Calculate total pages
    const totalPages = Math.ceil(count / limit);
    
    // Send response
    res.json({
      success: true,
      data: { 
        fillings,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages
        }
      }
    });
  } catch (error) {
    console.error('Get all fillings error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving fillings',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get filling by ID
 */
exports.getFillingById = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find filling
    const filling = await Filling.findByPk(id, {
      include: [
        { model: Cylinder, as: 'cylinder', attributes: ['id', 'serialNumber', 'size', 'type', 'status', 'factoryId'] },
        { model: User, as: 'startedBy', attributes: ['id', 'name'] },
        { model: User, as: 'endedBy', attributes: ['id', 'name'] }
      ]
    });
    
    if (!filling) {
      return res.status(404).json({
        success: false,
        message: 'Filling not found'
      });
    }
    
    // Send response
    res.json({
      success: true,
      data: { filling }
    });
  } catch (error) {
    console.error('Get filling by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving filling',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Start filling process
 */
exports.startFilling = async (req, res) => {
  try {
    const { 
      cylinderId, 
      lineNumber, 
      initialPressure, 
      targetPressure, 
      gasType, 
      notes 
    } = req.body;
    
    // Validate input
    if (!cylinderId || !lineNumber || initialPressure === undefined || !targetPressure || !gasType) {
      return res.status(400).json({
        success: false,
        message: 'Cylinder ID, line number, initial pressure, target pressure, and gas type are required'
      });
    }
    
    // Check if cylinder exists
    const cylinder = await Cylinder.findByPk(cylinderId);
    
    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }
    
    // Check if cylinder is available for filling (not in error or already full)
    if (cylinder.status === 'Full') {
      return res.status(400).json({
        success: false,
        message: 'Cylinder is already full'
      });
    }
    
    if (cylinder.status === 'Error' || cylinder.status === 'InMaintenance') {
      return res.status(400).json({
        success: false,
        message: `Cannot fill cylinder with status: ${cylinder.status}`
      });
    }
    
    // Check if cylinder is already in a filling process
    const existingFilling = await Filling.findOne({
      where: {
        cylinderId,
        status: 'InProgress'
      }
    });
    
    if (existingFilling) {
      return res.status(400).json({
        success: false,
        message: 'Cylinder is already in a filling process'
      });
    }
    
    // Create new filling
    const filling = await Filling.create({
      cylinderId,
      startedById: req.user.id,
      lineNumber,
      initialPressure,
      targetPressure,
      gasType,
      status: 'InProgress',
      notes: notes || null
    });
    
    // Update cylinder status to in transit
    await cylinder.update({ status: 'InTransit' });
    
    // Get detailed filling info
    const detailedFilling = await Filling.findByPk(filling.id, {
      include: [
        { model: Cylinder, as: 'cylinder', attributes: ['id', 'serialNumber', 'size', 'type'] },
        { model: User, as: 'startedBy', attributes: ['id', 'name'] }
      ]
    });
    
    // Send response
    res.status(201).json({
      success: true,
      data: { filling: detailedFilling }
    });
  } catch (error) {
    console.error('Start filling error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while starting filling process',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Complete filling process
 */
exports.completeFilling = async (req, res) => {
  try {
    const { id } = req.params;
    const { finalPressure, status, notes } = req.body;
    
    // Validate input
    if (finalPressure === undefined || !status) {
      return res.status(400).json({
        success: false,
        message: 'Final pressure and status are required'
      });
    }
    
    // Check if status is valid
    if (!['Completed', 'Failed'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Status must be either "Completed" or "Failed"'
      });
    }
    
    // Find filling
    const filling = await Filling.findByPk(id);
    
    if (!filling) {
      return res.status(404).json({
        success: false,
        message: 'Filling not found'
      });
    }
    
    // Check if filling is already completed
    if (filling.status !== 'InProgress') {
      return res.status(400).json({
        success: false,
        message: 'Filling is already completed or failed'
      });
    }
    
    // Update filling
    await filling.update({
      finalPressure,
      endedById: req.user.id,
      endTime: new Date(),
      status,
      notes: notes !== undefined ? (filling.notes ? `${filling.notes}\n${notes}` : notes) : filling.notes
    });
    
    // Get detailed filling info
    const detailedFilling = await Filling.findByPk(id, {
      include: [
        { model: Cylinder, as: 'cylinder', attributes: ['id', 'serialNumber', 'size', 'type', 'status'] },
        { model: User, as: 'startedBy', attributes: ['id', 'name'] },
        { model: User, as: 'endedBy', attributes: ['id', 'name'] }
      ]
    });
    
    // Send response
    res.json({
      success: true,
      data: { filling: detailedFilling }
    });
  } catch (error) {
    console.error('Complete filling error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while completing filling process',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get current active filling lines
 */
exports.getActiveLines = async (req, res) => {
  try {
    // Find distinct active line numbers
    const activeLines = await Filling.findAll({
      attributes: [
        'lineNumber',
        [sequelize.fn('COUNT', sequelize.col('id')), 'cylinderCount']
      ],
      where: { status: 'InProgress' },
      group: ['lineNumber'],
      order: [['lineNumber', 'ASC']]
    });
    
    // Get cylinders for each line
    const lines = await Promise.all(
      activeLines.map(async (line) => {
        const fillings = await Filling.findAll({
          where: {
            lineNumber: line.lineNumber,
            status: 'InProgress'
          },
          include: [
            { model: Cylinder, as: 'cylinder', attributes: ['id', 'serialNumber', 'size', 'type'] },
            { model: User, as: 'startedBy', attributes: ['id', 'name'] }
          ],
          order: [['startTime', 'ASC']]
        });
        
        return {
          lineNumber: line.lineNumber,
          cylinderCount: fillings.length,
          fillings
        };
      })
    );
    
    // Send response
    res.json({
      success: true,
      data: { lines }
    });
  } catch (error) {
    console.error('Get active lines error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving active filling lines',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get filling stats (daily, weekly, monthly)
 */
exports.getFillingStats = async (req, res) => {
  try {
    const { period = 'daily' } = req.query;
    
    let timeGroup, format, timeRange;
    const now = new Date();
    
    // Set time grouping based on period
    if (period === 'weekly') {
      timeGroup = 'day';
      format = '%Y-%m-%d';
      // Last 7 days
      timeRange = new Date(now.setDate(now.getDate() - 7));
    } else if (period === 'monthly') {
      timeGroup = 'day';
      format = '%Y-%m-%d';
      // Last 30 days
      timeRange = new Date(now.setDate(now.getDate() - 30));
    } else {
      // daily - default
      timeGroup = 'hour';
      format = '%Y-%m-%d %H:00';
      // Last 24 hours
      timeRange = new Date(now.setHours(now.getHours() - 24));
    }
    
    // Get completed fillings stats
    const completedStats = await Filling.findAll({
      attributes: [
        [sequelize.fn('date_trunc', timeGroup, sequelize.col('endTime')), 'time'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        status: 'Completed',
        endTime: {
          [Op.gte]: timeRange
        }
      },
      group: [sequelize.fn('date_trunc', timeGroup, sequelize.col('endTime'))],
      order: [[sequelize.fn('date_trunc', timeGroup, sequelize.col('endTime')), 'ASC']]
    });
    
    // Get failed fillings stats
    const failedStats = await Filling.findAll({
      attributes: [
        [sequelize.fn('date_trunc', timeGroup, sequelize.col('endTime')), 'time'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        status: 'Failed',
        endTime: {
          [Op.gte]: timeRange
        }
      },
      group: [sequelize.fn('date_trunc', timeGroup, sequelize.col('endTime'))],
      order: [[sequelize.fn('date_trunc', timeGroup, sequelize.col('endTime')), 'ASC']]
    });
    
    // Send response
    res.json({
      success: true,
      data: { 
        period,
        stats: {
          completed: completedStats,
          failed: failedStats
        }
      }
    });
  } catch (error) {
    console.error('Get filling stats error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving filling statistics',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};
