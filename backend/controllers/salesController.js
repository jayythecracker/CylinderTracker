const { Sale, SaleItem, SALE_STATUS, DELIVERY_TYPE } = require('../models/Sale');
const { Customer } = require('../models/Customer');
const { Cylinder, CYLINDER_STATUSES } = require('../models/Cylinder');
const { Truck, DeliveryTrip } = require('../models/Truck');
const { User } = require('../models/User');
const { sequelize } = require('../config/db');
const { Op } = require('sequelize');

// Generate invoice number
const generateInvoiceNumber = async () => {
  const prefix = 'INV';
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  
  // Find latest invoice number
  const latestSale = await Sale.findOne({
    where: {
      invoiceNumber: {
        [Op.like]: `${prefix}-${date}%`
      }
    },
    order: [['invoiceNumber', 'DESC']]
  });

  let counter = 1;
  if (latestSale) {
    const latestCounter = parseInt(latestSale.invoiceNumber.split('-')[2]);
    counter = latestCounter + 1;
  }

  return `${prefix}-${date}-${counter.toString().padStart(3, '0')}`;
};

// Get all sales with pagination and filters
exports.getAllSales = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      status,
      customerId,
      deliveryType,
      startDate,
      endDate,
      search
    } = req.query;

    const offset = (page - 1) * limit;
    let whereClause = {};

    // Apply filters
    if (status && Object.values(SALE_STATUS).includes(status)) {
      whereClause.status = status;
    }

    if (customerId) {
      whereClause.customerId = customerId;
    }

    if (deliveryType && Object.values(DELIVERY_TYPE).includes(deliveryType)) {
      whereClause.deliveryType = deliveryType;
    }

    // Date range filter
    if (startDate && endDate) {
      whereClause.saleDate = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    } else if (startDate) {
      whereClause.saleDate = {
        [Op.gte]: new Date(startDate)
      };
    } else if (endDate) {
      whereClause.saleDate = {
        [Op.lte]: new Date(endDate)
      };
    }

    // Search by invoice number
    if (search) {
      whereClause.invoiceNumber = {
        [Op.iLike]: `%${search}%`
      };
    }

    // Get sales with pagination
    const { count, rows: sales } = await Sale.findAndCountAll({
      where: whereClause,
      include: [
        {
          model: Customer,
          as: 'customer',
          attributes: ['id', 'name', 'type']
        },
        {
          model: User,
          as: 'seller',
          attributes: ['id', 'name']
        }
      ],
      order: [['saleDate', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.status(200).json({
      sales,
      totalCount: count,
      totalPages: Math.ceil(count / limit),
      currentPage: parseInt(page)
    });
  } catch (error) {
    console.error('Get all sales error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get sale by ID
exports.getSaleById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const sale = await Sale.findByPk(id, {
      include: [
        {
          model: Customer,
          as: 'customer'
        },
        {
          model: User,
          as: 'seller',
          attributes: ['id', 'name']
        },
        {
          model: DeliveryTrip,
          as: 'deliveryTrip',
          include: [
            {
              model: Truck,
              as: 'truck',
              attributes: ['id', 'licenseNumber', 'type']
            }
          ]
        },
        {
          model: SaleItem,
          as: 'items',
          include: [
            {
              model: Cylinder,
              as: 'cylinder'
            }
          ]
        }
      ]
    });

    if (!sale) {
      return res.status(404).json({ message: 'Sale not found' });
    }

    res.status(200).json({ sale });
  } catch (error) {
    console.error('Get sale by ID error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Create sale
exports.createSale = async (req, res) => {
  const transaction = await sequelize.transaction();

  try {
    const {
      customerId,
      cylinderIds,
      deliveryType,
      deliveryTripId,
      notes
    } = req.body;

    // Validate required fields
    if (!customerId || !cylinderIds || !Array.isArray(cylinderIds) || cylinderIds.length === 0) {
      return res.status(400).json({ message: 'Please provide customer ID and cylinder IDs' });
    }

    if (!deliveryType || !Object.values(DELIVERY_TYPE).includes(deliveryType)) {
      return res.status(400).json({ message: 'Please provide a valid delivery type' });
    }

    // Check if customer exists
    const customer = await Customer.findByPk(customerId);
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    // Check delivery trip if provided
    if (deliveryType === DELIVERY_TYPE.DELIVERY && deliveryTripId) {
      const deliveryTrip = await DeliveryTrip.findByPk(deliveryTripId);
      if (!deliveryTrip) {
        return res.status(404).json({ message: 'Delivery trip not found' });
      }
    }

    // Check if all cylinders exist and are available
    const cylinders = await Cylinder.findAll({
      where: {
        id: cylinderIds,
        status: CYLINDER_STATUSES.FILLED
      }
    });

    if (cylinders.length !== cylinderIds.length) {
      await transaction.rollback();
      return res.status(400).json({ 
        message: 'Some cylinders are not available for sale',
        found: cylinders.length,
        requested: cylinderIds.length
      });
    }

    // Generate invoice number
    const invoiceNumber = await generateInvoiceNumber();

    // Calculate total amount (simplified - in reality would depend on customer price group and cylinder type)
    const totalAmount = cylinders.length * 100; // Example price calculation

    // Create sale
    const sale = await Sale.create({
      invoiceNumber,
      customerId,
      sellerId: req.user.userId,
      saleDate: new Date(),
      totalAmount,
      paidAmount: 0,
      deliveryType,
      deliveryTripId: deliveryType === DELIVERY_TYPE.DELIVERY ? deliveryTripId : null,
      status: deliveryType === DELIVERY_TYPE.PICKUP ? SALE_STATUS.PENDING : SALE_STATUS.PROCESSING,
      notes: notes || ''
    }, { transaction });

    // Create sale items
    const saleItems = await Promise.all(cylinders.map(async (cylinder) => {
      // Update cylinder status
      cylinder.status = CYLINDER_STATUSES.INSPECTION;
      await cylinder.save({ transaction });

      // Create sale item
      return SaleItem.create({
        saleId: sale.id,
        cylinderId: cylinder.id,
        price: 100, // Example price
        isReturn: false,
        status: 'pending'
      }, { transaction });
    }));

    // Update customer balance if credit type
    if (customer.paymentType === 'credit') {
      customer.balance += totalAmount;
      await customer.save({ transaction });
    }

    await transaction.commit();

    res.status(201).json({
      message: 'Sale created successfully',
      sale: {
        ...sale.toJSON(),
        items: saleItems
      }
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Create sale error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update sale status
exports.updateSaleStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, paidAmount, customerSignature, notes } = req.body;

    // Find sale
    const sale = await Sale.findByPk(id);
    if (!sale) {
      return res.status(404).json({ message: 'Sale not found' });
    }

    // Validate status
    if (status && !Object.values(SALE_STATUS).includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    // Update fields
    if (status) sale.status = status;
    if (paidAmount !== undefined) {
      // Update payment
      const additionalPayment = paidAmount - sale.paidAmount;
      sale.paidAmount = paidAmount;

      // Update customer balance if payment was made
      if (additionalPayment > 0) {
        const customer = await Customer.findByPk(sale.customerId);
        if (customer) {
          customer.balance -= additionalPayment;
          await customer.save();
        }
      }
    }
    if (customerSignature !== undefined) sale.customerSignature = customerSignature;
    if (notes) sale.notes = notes;

    // Set delivery date if status is delivered
    if (status === SALE_STATUS.DELIVERED && !sale.deliveryDate) {
      sale.deliveryDate = new Date();
    }

    await sale.save();

    res.status(200).json({
      message: 'Sale status updated successfully',
      sale
    });
  } catch (error) {
    console.error('Update sale status error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Add cylinder returns
exports.addCylinderReturns = async (req, res) => {
  const transaction = await sequelize.transaction();

  try {
    const { id } = req.params;
    const { cylinderIds, notes } = req.body;

    // Validate input
    if (!cylinderIds || !Array.isArray(cylinderIds) || cylinderIds.length === 0) {
      return res.status(400).json({ message: 'Please provide cylinderIds array' });
    }

    // Find sale
    const sale = await Sale.findByPk(id);
    if (!sale) {
      return res.status(404).json({ message: 'Sale not found' });
    }

    // Check if all cylinders exist
    const cylinders = await Cylinder.findAll({
      where: { id: cylinderIds }
    });

    if (cylinders.length !== cylinderIds.length) {
      await transaction.rollback();
      return res.status(400).json({ 
        message: 'Some cylinders were not found',
        found: cylinders.length,
        requested: cylinderIds.length
      });
    }

    // Create return items
    const returnItems = await Promise.all(cylinders.map(async (cylinder) => {
      // Update cylinder status
      cylinder.status = CYLINDER_STATUSES.EMPTY;
      await cylinder.save({ transaction });

      // Create sale item for return
      return SaleItem.create({
        saleId: sale.id,
        cylinderId: cylinder.id,
        price: 0, // Return is free
        isReturn: true,
        status: 'returned'
      }, { transaction });
    }));

    // Update sale notes if provided
    if (notes) {
      sale.notes = sale.notes ? `${sale.notes}\n${notes}` : notes;
      await sale.save({ transaction });
    }

    await transaction.commit();

    res.status(201).json({
      message: 'Cylinder returns processed successfully',
      returnItems
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Add cylinder returns error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Cancel sale
exports.cancelSale = async (req, res) => {
  const transaction = await sequelize.transaction();

  try {
    const { id } = req.params;
    const { reason } = req.body;

    // Validate input
    if (!reason) {
      return res.status(400).json({ message: 'Please provide cancellation reason' });
    }

    // Find sale
    const sale = await Sale.findByPk(id, {
      include: [
        {
          model: SaleItem,
          as: 'items'
        }
      ]
    });

    if (!sale) {
      return res.status(404).json({ message: 'Sale not found' });
    }

    // Check if sale can be cancelled
    if (sale.status === SALE_STATUS.DELIVERED || sale.status === SALE_STATUS.CANCELLED) {
      await transaction.rollback();
      return res.status(400).json({ message: `Sale cannot be cancelled. Current status: ${sale.status}` });
    }

    // Update cylinder statuses
    for (const item of sale.items) {
      if (!item.isReturn) {
        const cylinder = await Cylinder.findByPk(item.cylinderId);
        if (cylinder) {
          cylinder.status = CYLINDER_STATUSES.FILLED;
          await cylinder.save({ transaction });
        }
      }
    }

    // Update customer balance if credit was used
    if (sale.paidAmount < sale.totalAmount) {
      const amountToCredit = sale.totalAmount - sale.paidAmount;
      const customer = await Customer.findByPk(sale.customerId);
      if (customer) {
        customer.balance -= amountToCredit;
        await customer.save({ transaction });
      }
    }

    // Update sale
    sale.status = SALE_STATUS.CANCELLED;
    sale.notes = sale.notes 
      ? `${sale.notes}\nCancelled reason: ${reason}`
      : `Cancelled reason: ${reason}`;
    await sale.save({ transaction });

    await transaction.commit();

    res.status(200).json({
      message: 'Sale cancelled successfully',
      sale
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Cancel sale error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
