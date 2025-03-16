const { 
  FillingLine, 
  FillingSession, 
  FillingSessionCylinder,
  FILLING_LINE_STATUS 
} = require('../models/FillingLine');
const { Cylinder, CYLINDER_STATUSES } = require('../models/Cylinder');
const { User } = require('../models/User');
const { Op } = require('sequelize');
const { sequelize } = require('../config/db');

// Get all filling lines
exports.getAllFillingLines = async (req, res) => {
  try {
    const fillingLines = await FillingLine.findAll({
      order: [['name', 'ASC']]
    });

    res.status(200).json({ fillingLines });
  } catch (error) {
    console.error('Get all filling lines error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get filling line by ID
exports.getFillingLineById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const fillingLine = await FillingLine.findByPk(id);
    if (!fillingLine) {
      return res.status(404).json({ message: 'Filling line not found' });
    }

    // Get active session if exists
    const activeSession = await FillingSession.findOne({
      where: { 
        fillingLineId: id,
        endTime: null
      },
      include: [
        {
          model: User,
          as: 'startedBy',
          attributes: ['id', 'name']
        }
      ],
      order: [['startTime', 'DESC']]
    });

    res.status(200).json({ 
      fillingLine,
      activeSession
    });
  } catch (error) {
    console.error('Get filling line by ID error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Create filling line
exports.createFillingLine = async (req, res) => {
  try {
    const {
      name,
      capacity,
      cylinderType,
      notes
    } = req.body;

    // Validate required fields
    if (!name || !cylinderType) {
      return res.status(400).json({ message: 'Please provide name and cylinder type' });
    }

    // Create filling line
    const fillingLine = await FillingLine.create({
      name,
      capacity: capacity || 10,
      status: FILLING_LINE_STATUS.IDLE,
      cylinderType,
      notes: notes || ''
    });

    res.status(201).json({
      message: 'Filling line created successfully',
      fillingLine
    });
  } catch (error) {
    console.error('Create filling line error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update filling line
exports.updateFillingLine = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      capacity,
      status,
      cylinderType,
      isActive,
      notes
    } = req.body;

    // Find filling line
    const fillingLine = await FillingLine.findByPk(id);
    if (!fillingLine) {
      return res.status(404).json({ message: 'Filling line not found' });
    }

    // Update fields
    if (name) fillingLine.name = name;
    if (capacity) fillingLine.capacity = capacity;
    if (status && Object.values(FILLING_LINE_STATUS).includes(status)) {
      fillingLine.status = status;
    }
    if (cylinderType) fillingLine.cylinderType = cylinderType;
    if (isActive !== undefined) fillingLine.isActive = isActive;
    if (notes !== undefined) fillingLine.notes = notes;

    await fillingLine.save();

    res.status(200).json({
      message: 'Filling line updated successfully',
      fillingLine
    });
  } catch (error) {
    console.error('Update filling line error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Start filling session
exports.startFillingSession = async (req, res) => {
  try {
    const { fillingLineId } = req.body;
    const userId = req.user.userId;

    // Validate input
    if (!fillingLineId) {
      return res.status(400).json({ message: 'Please provide filling line ID' });
    }

    // Find filling line
    const fillingLine = await FillingLine.findByPk(fillingLineId);
    if (!fillingLine) {
      return res.status(404).json({ message: 'Filling line not found' });
    }

    // Check if filling line is available
    if (fillingLine.status !== FILLING_LINE_STATUS.IDLE) {
      return res.status(400).json({ message: 'Filling line is not available' });
    }

    // Check if there's already an active session
    const activeSession = await FillingSession.findOne({
      where: { 
        fillingLineId,
        endTime: null
      }
    });

    if (activeSession) {
      return res.status(400).json({ message: 'Filling line already has an active session' });
    }

    // Update filling line status
    fillingLine.status = FILLING_LINE_STATUS.ACTIVE;
    await fillingLine.save();

    // Create filling session
    const fillingSession = await FillingSession.create({
      fillingLineId,
      startedById: userId,
      startTime: new Date()
    });

    res.status(201).json({
      message: 'Filling session started successfully',
      fillingSession
    });
  } catch (error) {
    console.error('Start filling session error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Add cylinder to filling session
exports.addCylinderToSession = async (req, res) => {
  try {
    const { sessionId, cylinderId, pressureBeforeFilling } = req.body;

    // Validate input
    if (!sessionId || !cylinderId) {
      return res.status(400).json({ message: 'Please provide session ID and cylinder ID' });
    }

    // Find session
    const session = await FillingSession.findByPk(sessionId);
    if (!session) {
      return res.status(404).json({ message: 'Filling session not found' });
    }

    // Check if session is active
    if (session.endTime) {
      return res.status(400).json({ message: 'Filling session is already completed' });
    }

    // Find cylinder
    const cylinder = await Cylinder.findByPk(cylinderId);
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }

    // Check if cylinder is already in session
    const existingSessionCylinder = await FillingSessionCylinder.findOne({
      where: {
        fillingSessionId: sessionId,
        cylinderId
      }
    });

    if (existingSessionCylinder) {
      return res.status(400).json({ message: 'Cylinder is already in this session' });
    }

    // Add cylinder to session
    const sessionCylinder = await FillingSessionCylinder.create({
      fillingSessionId: sessionId,
      cylinderId,
      status: 'pending',
      pressureBeforeFilling: pressureBeforeFilling || 0
    });

    // Update cylinder status
    cylinder.status = CYLINDER_STATUSES.INSPECTION;
    await cylinder.save();

    res.status(201).json({
      message: 'Cylinder added to filling session successfully',
      sessionCylinder
    });
  } catch (error) {
    console.error('Add cylinder to session error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update cylinder filling status
exports.updateCylinderFilling = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, pressureAfterFilling, notes } = req.body;

    // Validate input
    if (!status || !['pending', 'filling', 'success', 'failed'].includes(status)) {
      return res.status(400).json({ message: 'Please provide a valid status' });
    }

    // Find session cylinder
    const sessionCylinder = await FillingSessionCylinder.findByPk(id);
    if (!sessionCylinder) {
      return res.status(404).json({ message: 'Session cylinder not found' });
    }

    // Update session cylinder
    sessionCylinder.status = status;
    sessionCylinder.filledAt = new Date();
    if (pressureAfterFilling) sessionCylinder.pressureAfterFilling = pressureAfterFilling;
    if (notes) sessionCylinder.notes = notes;
    await sessionCylinder.save();

    // Update cylinder status based on filling result
    const cylinder = await Cylinder.findByPk(sessionCylinder.cylinderId);
    if (cylinder) {
      if (status === 'success') {
        cylinder.status = CYLINDER_STATUSES.FILLED;
        cylinder.lastFilled = new Date();
      } else if (status === 'failed') {
        cylinder.status = CYLINDER_STATUSES.ERROR;
      }
      await cylinder.save();
    }

    res.status(200).json({
      message: 'Cylinder filling status updated successfully',
      sessionCylinder
    });
  } catch (error) {
    console.error('Update cylinder filling status error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// End filling session
exports.endFillingSession = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    const { notes } = req.body;

    // Find session
    const session = await FillingSession.findByPk(id);
    if (!session) {
      return res.status(404).json({ message: 'Filling session not found' });
    }

    // Check if session is already ended
    if (session.endTime) {
      return res.status(400).json({ message: 'Filling session is already completed' });
    }

    // Update session
    session.endTime = new Date();
    session.endedById = userId;
    if (notes) session.notes = notes;
    await session.save();

    // Update filling line status
    const fillingLine = await FillingLine.findByPk(session.fillingLineId);
    if (fillingLine) {
      fillingLine.status = FILLING_LINE_STATUS.IDLE;
      await fillingLine.save();
    }

    // Get all pending cylinders in this session
    const pendingCylinders = await FillingSessionCylinder.findAll({
      where: {
        fillingSessionId: id,
        status: 'pending'
      }
    });

    // Mark all pending cylinders as failed
    if (pendingCylinders.length > 0) {
      await Promise.all(pendingCylinders.map(async (sc) => {
        sc.status = 'failed';
        sc.notes = 'Session ended before processing';
        await sc.save();

        // Update cylinder status
        const cylinder = await Cylinder.findByPk(sc.cylinderId);
        if (cylinder) {
          cylinder.status = CYLINDER_STATUSES.ERROR;
          await cylinder.save();
        }
      }));
    }

    res.status(200).json({
      message: 'Filling session ended successfully',
      session
    });
  } catch (error) {
    console.error('End filling session error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get session details
exports.getSessionDetails = async (req, res) => {
  try {
    const { id } = req.params;

    // Find session with related data
    const session = await FillingSession.findByPk(id, {
      include: [
        {
          model: FillingLine,
          as: 'fillingLine'
        },
        {
          model: User,
          as: 'startedBy',
          attributes: ['id', 'name']
        },
        {
          model: User,
          as: 'endedBy',
          attributes: ['id', 'name']
        },
        {
          model: FillingSessionCylinder,
          as: 'cylinders',
          include: [
            {
              model: Cylinder,
              as: 'cylinder'
            }
          ]
        }
      ]
    });

    if (!session) {
      return res.status(404).json({ message: 'Filling session not found' });
    }

    // Calculate statistics
    const stats = {
      total: session.cylinders.length,
      pending: 0,
      filling: 0,
      success: 0,
      failed: 0
    };

    session.cylinders.forEach(cylinder => {
      stats[cylinder.status]++;
    });

    res.status(200).json({
      session,
      stats
    });
  } catch (error) {
    console.error('Get session details error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get filling sessions
exports.getFillingSessionsList = async (req, res) => {
  try {
    const { page = 1, limit = 20, fillingLineId, status } = req.query;
    const offset = (page - 1) * limit;
    let whereClause = {};

    // Apply filters
    if (fillingLineId) {
      whereClause.fillingLineId = fillingLineId;
    }

    if (status === 'active') {
      whereClause.endTime = null;
    } else if (status === 'completed') {
      whereClause.endTime = { [Op.not]: null };
    }

    // Get sessions with pagination
    const { count, rows: sessions } = await FillingSession.findAndCountAll({
      where: whereClause,
      include: [
        {
          model: FillingLine,
          as: 'fillingLine'
        },
        {
          model: User,
          as: 'startedBy',
          attributes: ['id', 'name']
        },
        {
          model: User,
          as: 'endedBy',
          attributes: ['id', 'name']
        }
      ],
      order: [['startTime', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    // Get cylinder counts for each session
    const sessionsWithCounts = await Promise.all(sessions.map(async (session) => {
      const cylinders = await FillingSessionCylinder.findAll({
        where: { fillingSessionId: session.id },
        attributes: ['status', [sequelize.fn('COUNT', sequelize.col('id')), 'count']],
        group: ['status']
      });

      const stats = {
        total: 0,
        pending: 0,
        filling: 0,
        success: 0,
        failed: 0
      };

      cylinders.forEach(cylinder => {
        const count = parseInt(cylinder.dataValues.count);
        stats[cylinder.status] = count;
        stats.total += count;
      });

      return {
        ...session.toJSON(),
        stats
      };
    }));

    res.status(200).json({
      sessions: sessionsWithCounts,
      totalCount: count,
      totalPages: Math.ceil(count / limit),
      currentPage: parseInt(page)
    });
  } catch (error) {
    console.error('Get filling sessions list error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
