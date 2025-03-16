const { Maintenance, Cylinder, User } = require('../models');
const { Op } = require('sequelize');

// @desc    Get all maintenance records
// @route   GET /api/maintenance
// @access  Private
exports.getAllMaintenanceRecords = async (req, res) => {
  try {
    const { status, cylinderId, startDate, endDate } = req.query;
    const whereClause = {};

    if (status) whereClause.status = status;
    if (cylinderId) whereClause.cylinderId = cylinderId;
    
    if (startDate && endDate) {
      whereClause.maintenanceDate = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    } else if (startDate) {
      whereClause.maintenanceDate = {
        [Op.gte]: new Date(startDate)
      };
    } else if (endDate) {
      whereClause.maintenanceDate = {
        [Op.lte]: new Date(endDate)
      };
    }

    const maintenanceRecords = await Maintenance.findAll({
      where: whereClause,
      include: [
        { 
          model: Cylinder,
          attributes: ['id', 'serialNumber', 'size', 'gasType', 'status'] 
        },
        { 
          model: User, 
          as: 'technician',
          attributes: ['id', 'name']
        }
      ],
      order: [['maintenanceDate', 'DESC']]
    });

    res.status(200).json({
      success: true,
      count: maintenanceRecords.length,
      maintenanceRecords
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Get maintenance record by ID
// @route   GET /api/maintenance/:id
// @access  Private
exports.getMaintenanceById = async (req, res) => {
  try {
    const maintenance = await Maintenance.findByPk(req.params.id, {
      include: [
        { model: Cylinder },
        { model: User, as: 'technician', attributes: ['id', 'name'] }
      ]
    });

    if (!maintenance) {
      return res.status(404).json({
        success: false,
        message: 'Maintenance record not found'
      });
    }

    res.status(200).json({
      success: true,
      maintenance
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Create a new maintenance record
// @route   POST /api/maintenance
// @access  Private (Admin, Manager, Filler)
exports.createMaintenance = async (req, res) => {
  try {
    const {
      cylinderId,
      issueDescription,
      actionTaken,
      status,
      cost,
      notes
    } = req.body;

    // Check if cylinder exists
    const cylinder = await Cylinder.findByPk(cylinderId);

    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }

    // Create maintenance record
    const maintenance = await Maintenance.create({
      cylinderId,
      technicianId: req.user.id,
      issueDescription,
      actionTaken,
      status: status || 'Pending',
      cost,
      notes
    });

    // Update cylinder status to InMaintenance
    cylinder.status = 'InMaintenance';
    await cylinder.save();

    res.status(201).json({
      success: true,
      maintenance
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Update maintenance record
// @route   PUT /api/maintenance/:id
// @access  Private (Admin, Manager, Filler)
exports.updateMaintenance = async (req, res) => {
  try {
    const {
      issueDescription,
      actionTaken,
      status,
      cost,
      completionDate,
      notes
    } = req.body;

    const maintenance = await Maintenance.findByPk(req.params.id, {
      include: [{ model: Cylinder }]
    });

    if (!maintenance) {
      return res.status(404).json({
        success: false,
        message: 'Maintenance record not found'
      });
    }

    // Update maintenance record
    maintenance.issueDescription = issueDescription || maintenance.issueDescription;
    maintenance.actionTaken = actionTaken || maintenance.actionTaken;
    maintenance.status = status || maintenance.status;
    maintenance.cost = cost !== undefined ? cost : maintenance.cost;
    maintenance.completionDate = completionDate || maintenance.completionDate;
    maintenance.notes = notes || maintenance.notes;

    await maintenance.save();

    // Update cylinder status based on maintenance status
    const cylinder = maintenance.Cylinder;
    
    if (status === 'Completed') {
      cylinder.status = 'Empty'; // Ready for inspection
      await cylinder.save();
    } else if (status === 'Unrepairable') {
      cylinder.status = 'Error';
      cylinder.isActive = false;
      cylinder.notes = (cylinder.notes ? cylinder.notes + '\n' : '') + 
                      'Cylinder marked as unrepairable';
      await cylinder.save();
    }

    res.status(200).json({
      success: true,
      maintenance
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Complete maintenance
// @route   PUT /api/maintenance/:id/complete
// @access  Private (Admin, Manager, Filler)
exports.completeMaintenance = async (req, res) => {
  try {
    const {
      actionTaken,
      cost,
      notes
    } = req.body;

    const maintenance = await Maintenance.findByPk(req.params.id, {
      include: [{ model: Cylinder }]
    });

    if (!maintenance) {
      return res.status(404).json({
        success: false,
        message: 'Maintenance record not found'
      });
    }

    if (maintenance.status === 'Completed' || maintenance.status === 'Unrepairable') {
      return res.status(400).json({
        success: false,
        message: `Maintenance is already ${maintenance.status}`
      });
    }

    // Update maintenance record
    maintenance.actionTaken = actionTaken || maintenance.actionTaken;
    maintenance.status = 'Completed';
    maintenance.cost = cost !== undefined ? cost : maintenance.cost;
    maintenance.completionDate = new Date();
    maintenance.notes = notes || maintenance.notes;

    await maintenance.save();

    // Update cylinder status to Empty (ready for inspection)
    const cylinder = maintenance.Cylinder;
    cylinder.status = 'Empty';
    await cylinder.save();

    res.status(200).json({
      success: true,
      maintenance
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Mark maintenance as unrepairable
// @route   PUT /api/maintenance/:id/unrepairable
// @access  Private (Admin, Manager)
exports.markUnrepairable = async (req, res) => {
  try {
    const { reason } = req.body;

    const maintenance = await Maintenance.findByPk(req.params.id, {
      include: [{ model: Cylinder }]
    });

    if (!maintenance) {
      return res.status(404).json({
        success: false,
        message: 'Maintenance record not found'
      });
    }

    if (maintenance.status === 'Completed' || maintenance.status === 'Unrepairable') {
      return res.status(400).json({
        success: false,
        message: `Maintenance is already ${maintenance.status}`
      });
    }

    // Update maintenance record
    maintenance.status = 'Unrepairable';
    maintenance.completionDate = new Date();
    maintenance.notes = (maintenance.notes ? maintenance.notes + '\n' : '') + 
                        `Unrepairable: ${reason || 'No reason provided'}`;

    await maintenance.save();

    // Update cylinder to inactive
    const cylinder = maintenance.Cylinder;
    cylinder.status = 'Error';
    cylinder.isActive = false;
    cylinder.notes = (cylinder.notes ? cylinder.notes + '\n' : '') + 
                    `Marked as unrepairable: ${reason || 'No reason provided'}`;
    await cylinder.save();

    res.status(200).json({
      success: true,
      maintenance
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};
