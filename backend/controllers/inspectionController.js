const { Cylinder, CYLINDER_STATUSES } = require('../models/Cylinder');
const { FillingSessionCylinder } = require('../models/FillingLine');
const { sequelize } = require('../config/db');
const { Op } = require('sequelize');

// Get cylinders for inspection
exports.getCylindersForInspection = async (req, res) => {
  try {
    const { page = 1, limit = 20, status, search } = req.query;
    const offset = (page - 1) * limit;
    
    let whereClause = {
      status: status || CYLINDER_STATUSES.INSPECTION
    };

    // Search by serial number
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
      order: [['lastFilled', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    // Get last filling details for each cylinder
    const cylindersWithFillingDetails = await Promise.all(cylinders.map(async (cylinder) => {
      const lastFilling = await FillingSessionCylinder.findOne({
        where: { cylinderId: cylinder.id },
        order: [['filledAt', 'DESC']]
      });

      return {
        ...cylinder.toJSON(),
        lastFilling: lastFilling || null
      };
    }));

    res.status(200).json({
      cylinders: cylindersWithFillingDetails,
      totalCount: count,
      totalPages: Math.ceil(count / limit),
      currentPage: parseInt(page)
    });
  } catch (error) {
    console.error('Get cylinders for inspection error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get cylinder inspection details
exports.getCylinderInspectionDetails = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find cylinder
    const cylinder = await Cylinder.findByPk(id);
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }

    // Get filling history
    const fillingHistory = await FillingSessionCylinder.findAll({
      where: { cylinderId: id },
      order: [['filledAt', 'DESC']],
      limit: 5
    });

    res.status(200).json({
      cylinder,
      fillingHistory
    });
  } catch (error) {
    console.error('Get cylinder inspection details error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Approve cylinder
exports.approveCylinder = async (req, res) => {
  try {
    const { id } = req.params;
    const { notes } = req.body;

    // Find cylinder
    const cylinder = await Cylinder.findByPk(id);
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }

    // Check if cylinder is in inspection
    if (cylinder.status !== CYLINDER_STATUSES.INSPECTION) {
      return res.status(400).json({ message: 'Cylinder is not in inspection status' });
    }

    // Update cylinder
    cylinder.status = CYLINDER_STATUSES.FILLED;
    cylinder.lastInspected = new Date();
    if (notes) cylinder.notes = notes;
    await cylinder.save();

    res.status(200).json({
      message: 'Cylinder approved successfully',
      cylinder
    });
  } catch (error) {
    console.error('Approve cylinder error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Reject cylinder
exports.rejectCylinder = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason, notes } = req.body;

    // Validate input
    if (!reason) {
      return res.status(400).json({ message: 'Please provide rejection reason' });
    }

    // Find cylinder
    const cylinder = await Cylinder.findByPk(id);
    if (!cylinder) {
      return res.status(404).json({ message: 'Cylinder not found' });
    }

    // Update cylinder
    cylinder.status = CYLINDER_STATUSES.ERROR;
    cylinder.lastInspected = new Date();
    cylinder.notes = notes ? `Rejection reason: ${reason}. ${notes}` : `Rejection reason: ${reason}`;
    await cylinder.save();

    res.status(200).json({
      message: 'Cylinder rejected successfully',
      cylinder
    });
  } catch (error) {
    console.error('Reject cylinder error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Batch approve cylinders
exports.batchApproveCylinders = async (req, res) => {
  try {
    const { cylinderIds, notes } = req.body;

    // Validate input
    if (!cylinderIds || !Array.isArray(cylinderIds) || cylinderIds.length === 0) {
      return res.status(400).json({ message: 'Please provide cylinderIds array' });
    }

    // Update all cylinders
    const now = new Date();
    const [updatedCount] = await Cylinder.update(
      {
        status: CYLINDER_STATUSES.FILLED,
        lastInspected: now,
        notes: notes || null
      },
      {
        where: {
          id: cylinderIds,
          status: CYLINDER_STATUSES.INSPECTION
        }
      }
    );

    res.status(200).json({
      message: 'Cylinders approved successfully',
      updatedCount
    });
  } catch (error) {
    console.error('Batch approve cylinders error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Batch reject cylinders
exports.batchRejectCylinders = async (req, res) => {
  try {
    const { cylinderIds, reason, notes } = req.body;

    // Validate input
    if (!cylinderIds || !Array.isArray(cylinderIds) || cylinderIds.length === 0) {
      return res.status(400).json({ message: 'Please provide cylinderIds array' });
    }

    if (!reason) {
      return res.status(400).json({ message: 'Please provide rejection reason' });
    }

    // Update all cylinders
    const now = new Date();
    const noteText = notes ? `Rejection reason: ${reason}. ${notes}` : `Rejection reason: ${reason}`;
    
    const [updatedCount] = await Cylinder.update(
      {
        status: CYLINDER_STATUSES.ERROR,
        lastInspected: now,
        notes: noteText
      },
      {
        where: {
          id: cylinderIds,
          status: CYLINDER_STATUSES.INSPECTION
        }
      }
    );

    res.status(200).json({
      message: 'Cylinders rejected successfully',
      updatedCount
    });
  } catch (error) {
    console.error('Batch reject cylinders error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
