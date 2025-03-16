const { Inspection, Cylinder, User } = require('../models');
const { Op } = require('sequelize');

/**
 * Get all inspections with pagination and filtering
 */
exports.getAllInspections = async (req, res) => {
  try {
    // Get query parameters for filtering and pagination
    const { 
      result, 
      inspectedById,
      startDate, 
      endDate,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter object
    const filter = {};
    
    if (result) {
      filter.result = result;
    }
    
    if (inspectedById) {
      filter.inspectedById = inspectedById;
    }
    
    // Date range filter
    if (startDate || endDate) {
      filter.inspectionDate = {};
      
      if (startDate) {
        filter.inspectionDate[Op.gte] = new Date(startDate);
      }
      
      if (endDate) {
        const endDateTime = new Date(endDate);
        endDateTime.setHours(23, 59, 59, 999);
        filter.inspectionDate[Op.lte] = endDateTime;
      }
    }
    
    // Calculate pagination
    const offset = (page - 1) * limit;
    
    // Find inspections with pagination
    const { count, rows: inspections } = await Inspection.findAndCountAll({
      where: filter,
      include: [
        { model: Cylinder, as: 'cylinder', attributes: ['id', 'serialNumber', 'size', 'type', 'status'] },
        { model: User, as: 'inspectedBy', attributes: ['id', 'name'] }
      ],
      order: [['inspectionDate', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    // Calculate total pages
    const totalPages = Math.ceil(count / limit);
    
    // Send response
    res.json({
      success: true,
      data: { 
        inspections,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages
        }
      }
    });
  } catch (error) {
    console.error('Get all inspections error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving inspections',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get inspection by ID
 */
exports.getInspectionById = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find inspection
    const inspection = await Inspection.findByPk(id, {
      include: [
        { model: Cylinder, as: 'cylinder', attributes: ['id', 'serialNumber', 'size', 'type', 'status', 'factoryId'] },
        { model: User, as: 'inspectedBy', attributes: ['id', 'name'] }
      ]
    });
    
    if (!inspection) {
      return res.status(404).json({
        success: false,
        message: 'Inspection not found'
      });
    }
    
    // Send response
    res.json({
      success: true,
      data: { inspection }
    });
  } catch (error) {
    console.error('Get inspection by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving inspection',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Create new inspection
 */
exports.createInspection = async (req, res) => {
  try {
    const { 
      cylinderId, 
      pressureCheck, 
      visualCheck, 
      valveCheck, 
      result, 
      rejectionReason, 
      notes 
    } = req.body;
    
    // Validate input
    if (!cylinderId || pressureCheck === undefined || visualCheck === undefined || valveCheck === undefined || !result) {
      return res.status(400).json({
        success: false,
        message: 'Cylinder ID, pressure check, visual check, valve check, and result are required'
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
    
    // Check if result is valid
    if (!['Approved', 'Rejected'].includes(result)) {
      return res.status(400).json({
        success: false,
        message: 'Result must be either "Approved" or "Rejected"'
      });
    }
    
    // If result is Rejected, rejection reason is required
    if (result === 'Rejected' && !rejectionReason) {
      return res.status(400).json({
        success: false,
        message: 'Rejection reason is required when result is Rejected'
      });
    }
    
    // Create new inspection
    const inspection = await Inspection.create({
      cylinderId,
      inspectedById: req.user.id,
      pressureCheck,
      visualCheck,
      valveCheck,
      result,
      rejectionReason: rejectionReason || null,
      notes: notes || null
    });
    
    // Get detailed inspection info
    const detailedInspection = await Inspection.findByPk(inspection.id, {
      include: [
        { model: Cylinder, as: 'cylinder', attributes: ['id', 'serialNumber', 'size', 'type', 'status'] },
        { model: User, as: 'inspectedBy', attributes: ['id', 'name'] }
      ]
    });
    
    // Send response
    res.status(201).json({
      success: true,
      data: { inspection: detailedInspection }
    });
  } catch (error) {
    console.error('Create inspection error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while creating inspection',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Batch create inspections (approve all)
 */
exports.batchCreateInspections = async (req, res) => {
  try {
    const { 
      cylinderIds, 
      pressureCheck, 
      visualCheck, 
      valveCheck, 
      result, 
      notes 
    } = req.body;
    
    // Validate input
    if (!cylinderIds || !Array.isArray(cylinderIds) || cylinderIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one cylinder ID is required'
      });
    }
    
    if (pressureCheck === undefined || visualCheck === undefined || valveCheck === undefined || !result) {
      return res.status(400).json({
        success: false,
        message: 'Pressure check, visual check, valve check, and result are required'
      });
    }
    
    // Check if result is valid
    if (!['Approved', 'Rejected'].includes(result)) {
      return res.status(400).json({
        success: false,
        message: 'Result must be either "Approved" or "Rejected"'
      });
    }
    
    // Create inspections for each cylinder
    const inspections = await Promise.all(
      cylinderIds.map(async (cylinderId) => {
        // Check if cylinder exists
        const cylinder = await Cylinder.findByPk(cylinderId);
        
        if (!cylinder) {
          return {
            cylinderId,
            success: false,
            message: 'Cylinder not found'
          };
        }
        
        try {
          // Create inspection
          const inspection = await Inspection.create({
            cylinderId,
            inspectedById: req.user.id,
            pressureCheck,
            visualCheck,
            valveCheck,
            result,
            notes: notes || null
          });
          
          return {
            cylinderId,
            inspectionId: inspection.id,
            success: true
          };
        } catch (error) {
          return {
            cylinderId,
            success: false,
            message: error.message
          };
        }
      })
    );
    
    // Count successes and failures
    const successCount = inspections.filter(item => item.success).length;
    const failureCount = inspections.length - successCount;
    
    // Send response
    res.status(201).json({
      success: true,
      data: { 
        inspections,
        summary: {
          total: inspections.length,
          success: successCount,
          failure: failureCount
        }
      }
    });
  } catch (error) {
    console.error('Batch create inspections error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while creating batch inspections',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get inspection stats (daily, weekly, monthly)
 */
exports.getInspectionStats = async (req, res) => {
  try {
    const { period = 'daily' } = req.query;
    
    let timeGroup, timeRange;
    const now = new Date();
    
    // Set time grouping based on period
    if (period === 'weekly') {
      timeGroup = 'day';
      // Last 7 days
      timeRange = new Date(now.setDate(now.getDate() - 7));
    } else if (period === 'monthly') {
      timeGroup = 'day';
      // Last 30 days
      timeRange = new Date(now.setDate(now.getDate() - 30));
    } else {
      // daily - default
      timeGroup = 'hour';
      // Last 24 hours
      timeRange = new Date(now.setHours(now.getHours() - 24));
    }
    
    // Get approved inspections stats
    const approvedStats = await Inspection.findAll({
      attributes: [
        [sequelize.fn('date_trunc', timeGroup, sequelize.col('inspectionDate')), 'time'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        result: 'Approved',
        inspectionDate: {
          [Op.gte]: timeRange
        }
      },
      group: [sequelize.fn('date_trunc', timeGroup, sequelize.col('inspectionDate'))],
      order: [[sequelize.fn('date_trunc', timeGroup, sequelize.col('inspectionDate')), 'ASC']]
    });
    
    // Get rejected inspections stats
    const rejectedStats = await Inspection.findAll({
      attributes: [
        [sequelize.fn('date_trunc', timeGroup, sequelize.col('inspectionDate')), 'time'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        result: 'Rejected',
        inspectionDate: {
          [Op.gte]: timeRange
        }
      },
      group: [sequelize.fn('date_trunc', timeGroup, sequelize.col('inspectionDate'))],
      order: [[sequelize.fn('date_trunc', timeGroup, sequelize.col('inspectionDate')), 'ASC']]
    });
    
    // Send response
    res.json({
      success: true,
      data: { 
        period,
        stats: {
          approved: approvedStats,
          rejected: rejectedStats
        }
      }
    });
  } catch (error) {
    console.error('Get inspection stats error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving inspection statistics',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};
