const { Truck, Sale } = require('../models');
const { Op } = require('sequelize');

/**
 * Get all trucks with pagination and filtering
 */
exports.getAllTrucks = async (req, res) => {
  try {
    // Get query parameters for filtering and pagination
    const { 
      status, 
      search,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter object
    const filter = {};
    
    if (status) {
      filter.status = status;
    }
    
    if (search) {
      filter[Op.or] = [
        { licenseNumber: { [Op.iLike]: `%${search}%` } },
        { driver: { [Op.iLike]: `%${search}%` } },
        { owner: { [Op.iLike]: `%${search}%` } }
      ];
    }
    
    // Calculate pagination
    const offset = (page - 1) * limit;
    
    // Find trucks with pagination
    const { count, rows: trucks } = await Truck.findAndCountAll({
      where: filter,
      order: [['licenseNumber', 'ASC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    // Calculate total pages
    const totalPages = Math.ceil(count / limit);
    
    // Send response
    res.json({
      success: true,
      data: { 
        trucks,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages
        }
      }
    });
  } catch (error) {
    console.error('Get all trucks error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving trucks',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get truck by ID
 */
exports.getTruckById = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find truck
    const truck = await Truck.findByPk(id);
    
    if (!truck) {
      return res.status(404).json({
        success: false,
        message: 'Truck not found'
      });
    }
    
    // Get active sales count
    const activeSalesCount = await Sale.count({
      where: { 
        truckId: id,
        deliveryStatus: {
          [Op.in]: ['Pending', 'InTransit']
        }
      }
    });
    
    // Send response
    res.json({
      success: true,
      data: { 
        truck,
        activeSalesCount
      }
    });
  } catch (error) {
    console.error('Get truck by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving truck',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Create new truck
 */
exports.createTruck = async (req, res) => {
  try {
    const { 
      licenseNumber, 
      type, 
      owner, 
      capacity, 
      driver, 
      driverContact, 
      notes 
    } = req.body;
    
    // Validate input
    if (!licenseNumber || !type || !owner || !capacity) {
      return res.status(400).json({
        success: false,
        message: 'License number, type, owner, and capacity are required'
      });
    }
    
    // Check if truck with same license number already exists
    const existingTruck = await Truck.findOne({
      where: { licenseNumber }
    });
    
    if (existingTruck) {
      return res.status(400).json({
        success: false,
        message: 'A truck with this license number already exists'
      });
    }
    
    // Create new truck
    const truck = await Truck.create({
      licenseNumber,
      type,
      owner,
      capacity,
      driver: driver || null,
      driverContact: driverContact || null,
      notes: notes || null
    });
    
    // Send response
    res.status(201).json({
      success: true,
      data: { truck }
    });
  } catch (error) {
    console.error('Create truck error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while creating truck',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Update truck
 */
exports.updateTruck = async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      licenseNumber, 
      type, 
      owner, 
      capacity, 
      driver, 
      driverContact, 
      status,
      lastMaintenance,
      notes 
    } = req.body;
    
    // Find truck
    const truck = await Truck.findByPk(id);
    
    if (!truck) {
      return res.status(404).json({
        success: false,
        message: 'Truck not found'
      });
    }
    
    // Check if new license number is already in use by another truck
    if (licenseNumber && licenseNumber !== truck.licenseNumber) {
      const existingTruck = await Truck.findOne({
        where: { 
          licenseNumber,
          id: { [Op.ne]: id }
        }
      });
      
      if (existingTruck) {
        return res.status(400).json({
          success: false,
          message: 'A truck with this license number already exists'
        });
      }
    }
    
    // Update truck fields
    await truck.update({
      licenseNumber: licenseNumber || truck.licenseNumber,
      type: type || truck.type,
      owner: owner || truck.owner,
      capacity: capacity || truck.capacity,
      driver: driver !== undefined ? driver : truck.driver,
      driverContact: driverContact !== undefined ? driverContact : truck.driverContact,
      status: status || truck.status,
      lastMaintenance: lastMaintenance !== undefined ? lastMaintenance : truck.lastMaintenance,
      notes: notes !== undefined ? notes : truck.notes
    });
    
    // Send response
    res.json({
      success: true,
      data: { truck }
    });
  } catch (error) {
    console.error('Update truck error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating truck',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Delete truck
 */
exports.deleteTruck = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find truck
    const truck = await Truck.findByPk(id);
    
    if (!truck) {
      return res.status(404).json({
        success: false,
        message: 'Truck not found'
      });
    }
    
    // Check if truck has active sales
    const activeSalesCount = await Sale.count({
      where: { 
        truckId: id,
        deliveryStatus: {
          [Op.in]: ['Pending', 'InTransit']
        }
      }
    });
    
    if (activeSalesCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete truck with ${activeSalesCount} active sales/deliveries. Complete or cancel these first.`
      });
    }
    
    // Delete truck
    await truck.destroy();
    
    // Send response
    res.json({
      success: true,
      message: 'Truck deleted successfully'
    });
  } catch (error) {
    console.error('Delete truck error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while deleting truck',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Update truck status
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
    
    // Check if status is valid
    if (!['Available', 'InTransit', 'Maintenance', 'OutOfService'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status value'
      });
    }
    
    // Find truck
    const truck = await Truck.findByPk(id);
    
    if (!truck) {
      return res.status(404).json({
        success: false,
        message: 'Truck not found'
      });
    }
    
    // If changing to Maintenance or OutOfService, check if truck has active sales
    if ((status === 'Maintenance' || status === 'OutOfService') && truck.status !== status) {
      const activeSalesCount = await Sale.count({
        where: { 
          truckId: id,
          deliveryStatus: {
            [Op.in]: ['Pending', 'InTransit']
          }
        }
      });
      
      if (activeSalesCount > 0) {
        return res.status(400).json({
          success: false,
          message: `Cannot change truck status to ${status} with ${activeSalesCount} active sales/deliveries. Complete or cancel these first.`
        });
      }
    }
    
    // Update truck status
    await truck.update({
      status,
      lastMaintenance: status === 'Maintenance' ? new Date() : truck.lastMaintenance,
      notes: notes !== undefined ? (truck.notes ? `${truck.notes}\n${notes}` : notes) : truck.notes
    });
    
    // Send response
    res.json({
      success: true,
      data: { truck }
    });
  } catch (error) {
    console.error('Update truck status error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating truck status',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get truck delivery history
 */
exports.getTruckDeliveries = async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20 } = req.query;
    
    // Find truck
    const truck = await Truck.findByPk(id);
    
    if (!truck) {
      return res.status(404).json({
        success: false,
        message: 'Truck not found'
      });
    }
    
    // Calculate pagination
    const offset = (page - 1) * limit;
    
    // Find sales with pagination
    const { count, rows: deliveries } = await Sale.findAndCountAll({
      where: { truckId: id },
      order: [['saleDate', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset),
      include: [
        { model: Customer, as: 'customer', attributes: ['id', 'name', 'type'] },
        { model: User, as: 'seller', attributes: ['id', 'name'] }
      ]
    });
    
    // Calculate total pages
    const totalPages = Math.ceil(count / limit);
    
    // Send response
    res.json({
      success: true,
      data: { 
        truck,
        deliveries,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages
        }
      }
    });
  } catch (error) {
    console.error('Get truck deliveries error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving truck deliveries',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};
