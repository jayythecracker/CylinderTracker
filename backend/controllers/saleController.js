const { Sale, SaleCylinder, Cylinder, Customer, User, Truck } = require('../models');
const { Op } = require('sequelize');
const sequelize = require('../config/database');

/**
 * Get all sales with pagination and filtering
 */
exports.getAllSales = async (req, res) => {
  try {
    // Get query parameters for filtering and pagination
    const { 
      customerId, 
      sellerId, 
      deliveryMethod,
      deliveryStatus,
      paymentStatus,
      startDate, 
      endDate,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter object
    const filter = {};
    
    if (customerId) {
      filter.customerId = customerId;
    }
    
    if (sellerId) {
      filter.sellerId = sellerId;
    }
    
    if (deliveryMethod) {
      filter.deliveryMethod = deliveryMethod;
    }
    
    if (deliveryStatus) {
      filter.deliveryStatus = deliveryStatus;
    }
    
    if (paymentStatus) {
      filter.paymentStatus = paymentStatus;
    }
    
    // Date range filter
    if (startDate || endDate) {
      filter.saleDate = {};
      
      if (startDate) {
        filter.saleDate[Op.gte] = new Date(startDate);
      }
      
      if (endDate) {
        const endDateTime = new Date(endDate);
        endDateTime.setHours(23, 59, 59, 999);
        filter.saleDate[Op.lte] = endDateTime;
      }
    }
    
    // Calculate pagination
    const offset = (page - 1) * limit;
    
    // Find sales with pagination
    const { count, rows: sales } = await Sale.findAndCountAll({
      where: filter,
      include: [
        { model: Customer, as: 'customer', attributes: ['id', 'name', 'type'] },
        { model: User, as: 'seller', attributes: ['id', 'name'] },
        { model: Truck, as: 'truck', attributes: ['id', 'licenseNumber'], required: false }
      ],
      order: [['saleDate', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    // Calculate total pages
    const totalPages = Math.ceil(count / limit);
    
    // Send response
    res.json({
      success: true,
      data: { 
        sales,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages
        }
      }
    });
  } catch (error) {
    console.error('Get all sales error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving sales',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get sale by ID
 */
exports.getSaleById = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find sale
    const sale = await Sale.findByPk(id, {
      include: [
        { model: Customer, as: 'customer' },
        { model: User, as: 'seller', attributes: ['id', 'name'] },
        { model: Truck, as: 'truck', required: false },
        { 
          model: Cylinder, 
          as: 'cylinders',
          through: {
            attributes: ['id', 'quantity']
          }
        }
      ]
    });
    
    if (!sale) {
      return res.status(404).json({
        success: false,
        message: 'Sale not found'
      });
    }
    
    // Send response
    res.json({
      success: true,
      data: { sale }
    });
  } catch (error) {
    console.error('Get sale by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving sale',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Create new sale
 */
exports.createSale = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { 
      customerId, 
      deliveryMethod, 
      truckId, 
      cylinders, 
      totalAmount,
      paidAmount,
      notes 
    } = req.body;
    
    // Validate input
    if (!customerId || !deliveryMethod || !cylinders || !Array.isArray(cylinders) || cylinders.length === 0) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: 'Customer ID, delivery method, and at least one cylinder are required'
      });
    }
    
    // Check if truck is required for delivery and provided
    if (deliveryMethod === 'Delivery' && !truckId) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: 'Truck ID is required for delivery method "Delivery"'
      });
    }
    
    // Check if customer exists
    const customer = await Customer.findByPk(customerId);
    
    if (!customer) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }
    
    // If delivery by truck, check if truck exists and is available
    if (deliveryMethod === 'Delivery') {
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
          message: `Truck is not available (current status: ${truck.status})`
        });
      }
    }
    
    // Validate cylinders array
    for (const item of cylinders) {
      if (!item.cylinderId || !item.quantity || item.quantity <= 0) {
        await transaction.rollback();
        return res.status(400).json({
          success: false,
          message: 'Each cylinder item must have cylinderId and positive quantity'
        });
      }
      
      // Check if cylinder exists and is full
      const cylinder = await Cylinder.findByPk(item.cylinderId);
      
      if (!cylinder) {
        await transaction.rollback();
        return res.status(404).json({
          success: false,
          message: `Cylinder with ID ${item.cylinderId} not found`
        });
      }
      
      if (cylinder.status !== 'Full') {
        await transaction.rollback();
        return res.status(400).json({
          success: false,
          message: `Cylinder with ID ${item.cylinderId} is not full (current status: ${cylinder.status})`
        });
      }
    }
    
    // Determine payment status
    let paymentStatus = 'Pending';
    if (paidAmount && paidAmount > 0) {
      if (paidAmount >= totalAmount) {
        paymentStatus = 'Paid';
      } else {
        paymentStatus = 'Partial';
      }
    }
    
    // Create new sale
    const sale = await Sale.create({
      customerId,
      sellerId: req.user.id, // Current authenticated user
      deliveryMethod,
      truckId: deliveryMethod === 'Delivery' ? truckId : null,
      totalAmount: totalAmount || 0,
      paidAmount: paidAmount || 0,
      paymentStatus,
      deliveryStatus: 'Pending',
      notes: notes || null
    }, { transaction });
    
    // Associate cylinders with quantities
    for (const item of cylinders) {
      await SaleCylinder.create({
        saleId: sale.id,
        cylinderId: item.cylinderId,
        quantity: item.quantity
      }, { transaction });
      
      // Update cylinder status to InTransit
      await Cylinder.update(
        { status: 'InTransit' },
        { 
          where: { id: item.cylinderId },
          transaction
        }
      );
    }
    
    // If delivery by truck, update truck status
    if (deliveryMethod === 'Delivery') {
      await Truck.update(
        { status: 'InTransit' },
        { 
          where: { id: truckId },
          transaction
        }
      );
    }
    
    // If credit customer, update balance
    if (customer.paymentType === 'Credit' && paymentStatus !== 'Paid') {
      const remainingAmount = totalAmount - (paidAmount || 0);
      await customer.update(
        { balance: customer.balance + remainingAmount },
        { transaction }
      );
    }
    
    await transaction.commit();
    
    // Get detailed sale info
    const detailedSale = await Sale.findByPk(sale.id, {
      include: [
        { model: Customer, as: 'customer', attributes: ['id', 'name', 'type'] },
        { model: User, as: 'seller', attributes: ['id', 'name'] },
        { model: Truck, as: 'truck', required: false, attributes: ['id', 'licenseNumber'] },
        { 
          model: Cylinder, 
          as: 'cylinders',
          through: {
            attributes: ['id', 'quantity']
          }
        }
      ]
    });
    
    // Send response
    res.status(201).json({
      success: true,
      data: { sale: detailedSale }
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Create sale error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while creating sale',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Update sale delivery status
 */
exports.updateDeliveryStatus = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { id } = req.params;
    const { 
      deliveryStatus, 
      deliveryDate,
      signatureImage,
      notes 
    } = req.body;
    
    // Validate input
    if (!deliveryStatus) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: 'Delivery status is required'
      });
    }
    
    // Check if status is valid
    if (!['Pending', 'InTransit', 'Delivered', 'Cancelled'].includes(deliveryStatus)) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: 'Invalid delivery status'
      });
    }
    
    // Find sale
    const sale = await Sale.findByPk(id, {
      include: [
        { 
          model: Cylinder, 
          as: 'cylinders',
          through: {
            attributes: ['id', 'quantity']
          }
        }
      ]
    });
    
    if (!sale) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        message: 'Sale not found'
      });
    }
    
    // If delivered, signature is required
    if (deliveryStatus === 'Delivered' && !signatureImage) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: 'Signature image is required for delivered status'
      });
    }
    
    // Update sale delivery status
    await sale.update({
      deliveryStatus,
      deliveryDate: deliveryStatus === 'Delivered' ? (deliveryDate || new Date()) : sale.deliveryDate,
      signatureImage: signatureImage || sale.signatureImage,
      notes: notes !== undefined ? (sale.notes ? `${sale.notes}\n${notes}` : notes) : sale.notes
    }, { transaction });
    
    // Handle cylinder status updates based on delivery status
    if (deliveryStatus === 'Delivered') {
      // Update cylinders to Empty status
      for (const cylinder of sale.cylinders) {
        await Cylinder.update(
          { status: 'Empty' },
          { 
            where: { id: cylinder.id },
            transaction
          }
        );
      }
      
      // If truck involved, update truck status to Available
      if (sale.truckId) {
        await Truck.update(
          { status: 'Available' },
          { 
            where: { id: sale.truckId },
            transaction
          }
        );
      }
    } else if (deliveryStatus === 'Cancelled') {
      // Update cylinders back to Full status
      for (const cylinder of sale.cylinders) {
        await Cylinder.update(
          { status: 'Full' },
          { 
            where: { id: cylinder.id },
            transaction
          }
        );
      }
      
      // If truck involved, update truck status to Available
      if (sale.truckId) {
        await Truck.update(
          { status: 'Available' },
          { 
            where: { id: sale.truckId },
            transaction
          }
        );
      }
      
      // If credit customer, update balance by removing charge
      const customer = await Customer.findByPk(sale.customerId);
      if (customer.paymentType === 'Credit' && sale.paymentStatus !== 'Paid') {
        const remainingAmount = sale.totalAmount - sale.paidAmount;
        await customer.update(
          { balance: customer.balance - remainingAmount },
          { transaction }
        );
      }
    }
    
    await transaction.commit();
    
    // Get updated sale info
    const updatedSale = await Sale.findByPk(id, {
      include: [
        { model: Customer, as: 'customer', attributes: ['id', 'name', 'type'] },
        { model: User, as: 'seller', attributes: ['id', 'name'] },
        { model: Truck, as: 'truck', required: false }
      ]
    });
    
    // Send response
    res.json({
      success: true,
      data: { sale: updatedSale }
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Update delivery status error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating delivery status',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Update sale payment status
 */
exports.updatePaymentStatus = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { id } = req.params;
    const { 
      paymentStatus, 
      paidAmount,
      notes 
    } = req.body;
    
    // Validate input
    if (!paymentStatus) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: 'Payment status is required'
      });
    }
    
    // Check if status is valid
    if (!['Paid', 'Pending', 'Partial'].includes(paymentStatus)) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: 'Invalid payment status'
      });
    }
    
    // Find sale
    const sale = await Sale.findByPk(id, {
      include: [
        { model: Customer, as: 'customer' }
      ]
    });
    
    if (!sale) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        message: 'Sale not found'
      });
    }
    
    // Calculate new paid amount
    let newPaidAmount = sale.paidAmount;
    if (paidAmount !== undefined) {
      newPaidAmount = paidAmount;
    } else if (paymentStatus === 'Paid') {
      newPaidAmount = sale.totalAmount;
    }
    
    // Validate new paid amount based on payment status
    if (paymentStatus === 'Paid' && newPaidAmount < sale.totalAmount) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: 'Paid amount must equal total amount for status "Paid"'
      });
    }
    
    if (paymentStatus === 'Partial' && (newPaidAmount <= 0 || newPaidAmount >= sale.totalAmount)) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: 'Paid amount must be greater than 0 and less than total amount for status "Partial"'
      });
    }
    
    // Calculate balance adjustment for credit customers
    let balanceAdjustment = 0;
    if (sale.customer.paymentType === 'Credit') {
      const previousUnpaid = sale.totalAmount - sale.paidAmount;
      const newUnpaid = sale.totalAmount - newPaidAmount;
      balanceAdjustment = newUnpaid - previousUnpaid;
    }
    
    // Update sale payment status
    await sale.update({
      paymentStatus,
      paidAmount: newPaidAmount,
      notes: notes !== undefined ? (sale.notes ? `${sale.notes}\n${notes}` : notes) : sale.notes
    }, { transaction });
    
    // Update customer balance if needed
    if (sale.customer.paymentType === 'Credit' && balanceAdjustment !== 0) {
      await sale.customer.update(
        { balance: sale.customer.balance + balanceAdjustment },
        { transaction }
      );
    }
    
    await transaction.commit();
    
    // Get updated sale info
    const updatedSale = await Sale.findByPk(id, {
      include: [
        { model: Customer, as: 'customer' },
        { model: User, as: 'seller', attributes: ['id', 'name'] }
      ]
    });
    
    // Send response
    res.json({
      success: true,
      data: { 
        sale: updatedSale,
        balanceAdjustment: balanceAdjustment !== 0 ? {
          customer: {
            id: sale.customer.id,
            name: sale.customer.name,
            previousBalance: sale.customer.balance,
            newBalance: sale.customer.balance + balanceAdjustment
          },
          adjustment: balanceAdjustment
        } : null
      }
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Update payment status error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating payment status',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get sales statistics
 */
exports.getSalesStats = async (req, res) => {
  try {
    const { period = 'daily', startDate, endDate } = req.query;
    
    let timeGroup, timeRange;
    const now = new Date();
    
    // Set time grouping based on period
    if (period === 'weekly') {
      timeGroup = 'day';
      // Last 7 days (if dates not provided)
      timeRange = startDate ? new Date(startDate) : new Date(now.setDate(now.getDate() - 7));
    } else if (period === 'monthly') {
      timeGroup = 'day';
      // Last 30 days (if dates not provided)
      timeRange = startDate ? new Date(startDate) : new Date(now.setDate(now.getDate() - 30));
    } else if (period === 'yearly') {
      timeGroup = 'month';
      // Last 12 months (if dates not provided)
      timeRange = startDate ? new Date(startDate) : new Date(now.setMonth(now.getMonth() - 12));
    } else {
      // daily - default
      timeGroup = 'hour';
      // Last 24 hours (if dates not provided)
      timeRange = startDate ? new Date(startDate) : new Date(now.setHours(now.getHours() - 24));
    }
    
    const endDateTime = endDate ? new Date(endDate) : new Date();
    if (endDate) {
      endDateTime.setHours(23, 59, 59, 999);
    }
    
    // Get sales count and amount stats
    const salesStats = await Sale.findAll({
      attributes: [
        [sequelize.fn('date_trunc', timeGroup, sequelize.col('saleDate')), 'time'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
        [sequelize.fn('SUM', sequelize.col('totalAmount')), 'totalAmount'],
        [sequelize.fn('SUM', sequelize.col('paidAmount')), 'paidAmount']
      ],
      where: {
        saleDate: {
          [Op.gte]: timeRange,
          [Op.lte]: endDateTime
        }
      },
      group: [sequelize.fn('date_trunc', timeGroup, sequelize.col('saleDate'))],
      order: [[sequelize.fn('date_trunc', timeGroup, sequelize.col('saleDate')), 'ASC']]
    });
    
    // Get summary statistics
    const summary = await Sale.findAll({
      attributes: [
        [sequelize.fn('COUNT', sequelize.col('id')), 'totalSales'],
        [sequelize.fn('SUM', sequelize.col('totalAmount')), 'totalAmount'],
        [sequelize.fn('SUM', sequelize.col('paidAmount')), 'paidAmount'],
        [
          sequelize.literal('SUM(CASE WHEN "deliveryStatus" = \'Delivered\' THEN 1 ELSE 0 END)'),
          'deliveredCount'
        ],
        [
          sequelize.literal('SUM(CASE WHEN "paymentStatus" = \'Paid\' THEN 1 ELSE 0 END)'),
          'paidCount'
        ]
      ],
      where: {
        saleDate: {
          [Op.gte]: timeRange,
          [Op.lte]: endDateTime
        }
      }
    });
    
    // Send response
    res.json({
      success: true,
      data: { 
        period,
        timeRange: {
          start: timeRange,
          end: endDateTime
        },
        stats: salesStats,
        summary: summary[0]
      }
    });
  } catch (error) {
    console.error('Get sales stats error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving sales statistics',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};
