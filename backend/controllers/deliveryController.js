const { Delivery, Cylinder, Customer, Truck, User, sequelize } = require('../models');
const { Op } = require('sequelize');

// @desc    Get all deliveries
// @route   GET /api/deliveries
// @access  Private
exports.getAllDeliveries = async (req, res) => {
  try {
    const { status, deliveryType, customerId, startDate, endDate } = req.query;
    const whereClause = {};

    if (status) whereClause.status = status;
    if (deliveryType) whereClause.deliveryType = deliveryType;
    if (customerId) whereClause.customerId = customerId;
    
    if (startDate && endDate) {
      whereClause.deliveryDate = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    } else if (startDate) {
      whereClause.deliveryDate = {
        [Op.gte]: new Date(startDate)
      };
    } else if (endDate) {
      whereClause.deliveryDate = {
        [Op.lte]: new Date(endDate)
      };
    }

    const deliveries = await Delivery.findAll({
      where: whereClause,
      include: [
        { 
          model: Customer,
          attributes: ['id', 'name', 'type'] 
        },
        { 
          model: User, 
          as: 'deliveryPerson',
          attributes: ['id', 'name']
        },
        { 
          model: Truck,
          attributes: ['id', 'licenseNumber', 'type']
        },
        {
          model: Cylinder,
          attributes: ['id', 'serialNumber', 'size', 'gasType'],
          through: { attributes: [] }
        }
      ],
      order: [['deliveryDate', 'DESC']]
    });

    res.status(200).json({
      success: true,
      count: deliveries.length,
      deliveries
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Get delivery by ID
// @route   GET /api/deliveries/:id
// @access  Private
exports.getDeliveryById = async (req, res) => {
  try {
    const delivery = await Delivery.findByPk(req.params.id, {
      include: [
        { model: Customer },
        { model: User, as: 'deliveryPerson', attributes: ['id', 'name'] },
        { model: Truck },
        {
          model: Cylinder,
          through: { attributes: [] }
        }
      ]
    });

    if (!delivery) {
      return res.status(404).json({
        success: false,
        message: 'Delivery record not found'
      });
    }

    res.status(200).json({
      success: true,
      delivery
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Create a new delivery
// @route   POST /api/deliveries
// @access  Private (Admin, Manager, Seller)
exports.createDelivery = async (req, res) => {
  const transaction = await sequelize.transaction();

  try {
    const {
      customerId,
      deliveryType,
      truckId,
      cylinderIds,
      totalAmount,
      notes
    } = req.body;

    // Check if customer exists
    const customer = await Customer.findByPk(customerId);

    if (!customer) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    // Check if truck exists if delivery by truck
    if (deliveryType === 'Truck' && truckId) {
      const truck = await Truck.findByPk(truckId);

      if (!truck) {
        await transaction.rollback();
        return res.status(404).json({
          success: false,
          message: 'Truck not found'
        });
      }

      if (truck.status !== 'Available') {
        await transaction.rollback();
        return res.status(400).json({
          success: false,
          message: `Truck is currently ${truck.status}`
        });
      }

      // Update truck status to InTransit
      truck.status = 'InTransit';
      await truck.save({ transaction });
    }

    // Create delivery record
    const delivery = await Delivery.create({
      customerId,
      deliveryType,
      truckId: deliveryType === 'Truck' ? truckId : null,
      deliveryPersonId: req.user.id,
      totalAmount,
      status: 'Pending',
      notes
    }, { transaction });

    // Add cylinders to delivery
    if (cylinderIds && cylinderIds.length > 0) {
      // Check if all cylinders exist and are Full
      const cylinders = await Cylinder.findAll({
        where: {
          id: { [Op.in]: cylinderIds }
        }
      });

      if (cylinders.length !== cylinderIds.length) {
        await transaction.rollback();
        return res.status(404).json({
          success: false,
          message: 'One or more cylinders not found'
        });
      }

      const invalidCylinders = cylinders.filter(c => c.status !== 'Full');
      if (invalidCylinders.length > 0) {
        await transaction.rollback();
        return res.status(400).json({
          success: false,
          message: 'One or more cylinders are not full and ready for delivery',
          invalidCylinders: invalidCylinders.map(c => ({
            id: c.id,
            serialNumber: c.serialNumber,
            status: c.status
          }))
        });
      }

      // Add cylinders to delivery
      await delivery.addCylinders(cylinders, { transaction });

      // Update cylinder status to InTransit
      for (const cylinder of cylinders) {
        cylinder.status = 'InTransit';
        await cylinder.save({ transaction });
      }
    }

    await transaction.commit();

    res.status(201).json({
      success: true,
      delivery
    });
  } catch (error) {
    await transaction.rollback();
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Complete a delivery
// @route   PUT /api/deliveries/:id/complete
// @access  Private (Admin, Manager, Seller)
exports.completeDelivery = async (req, res) => {
  const transaction = await sequelize.transaction();

  try {
    const {
      signature,
      receiptNumber,
      notes
    } = req.body;

    const delivery = await Delivery.findByPk(req.params.id, {
      include: [
        { model: Truck },
        { model: Cylinder }
      ]
    });

    if (!delivery) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        message: 'Delivery record not found'
      });
    }

    if (delivery.status !== 'Pending' && delivery.status !== 'InTransit') {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: `Delivery is already ${delivery.status}`
      });
    }

    // Update delivery record
    delivery.status = 'Delivered';
    delivery.signature = signature;
    delivery.receiptNumber = receiptNumber;
    delivery.notes = notes || delivery.notes;

    await delivery.save({ transaction });

    // Update truck status if applicable
    if (delivery.deliveryType === 'Truck' && delivery.Truck) {
      delivery.Truck.status = 'Available';
      await delivery.Truck.save({ transaction });
    }

    // Update cylinder status and customer
    for (const cylinder of delivery.Cylinders) {
      cylinder.status = 'Full';
      cylinder.currentCustomerId = delivery.customerId;
      await cylinder.save({ transaction });
    }

    await transaction.commit();

    res.status(200).json({
      success: true,
      delivery
    });
  } catch (error) {
    await transaction.rollback();
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Cancel a delivery
// @route   PUT /api/deliveries/:id/cancel
// @access  Private (Admin, Manager)
exports.cancelDelivery = async (req, res) => {
  const transaction = await sequelize.transaction();

  try {
    const { reason } = req.body;

    const delivery = await Delivery.findByPk(req.params.id, {
      include: [
        { model: Truck },
        { model: Cylinder }
      ]
    });

    if (!delivery) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        message: 'Delivery record not found'
      });
    }

    if (delivery.status === 'Delivered' || delivery.status === 'Cancelled') {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: `Delivery is already ${delivery.status}`
      });
    }

    // Update delivery record
    delivery.status = 'Cancelled';
    delivery.notes = (delivery.notes ? delivery.notes + '\n' : '') + 
                    `Cancelled: ${reason || 'No reason provided'}`;

    await delivery.save({ transaction });

    // Update truck status if applicable
    if (delivery.deliveryType === 'Truck' && delivery.Truck) {
      delivery.Truck.status = 'Available';
      await delivery.Truck.save({ transaction });
    }

    // Update cylinder status back to Full
    for (const cylinder of delivery.Cylinders) {
      cylinder.status = 'Full';
      await cylinder.save({ transaction });
    }

    await transaction.commit();

    res.status(200).json({
      success: true,
      delivery
    });
  } catch (error) {
    await transaction.rollback();
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};
