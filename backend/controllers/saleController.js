const { Sale, SaleItem } = require('../models/sale');
const Customer = require('../models/customer');
const Cylinder = require('../models/cylinder');
const Truck = require('../models/truck');
const User = require('../models/user');
const { sequelize } = require('../config/db');
const { Op } = require('sequelize');

// Generate a unique invoice number
const generateInvoiceNumber = () => {
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const randomNum = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `INV-${dateStr}-${randomNum}`;
};

// Get all sales with pagination and filters
const getAllSales = async (req, res) => {
  try {
    const { 
      status,
      customerId,
      sellerId,
      deliveryType,
      paymentStatus,
      startDate,
      endDate,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter conditions
    const whereConditions = {};
    
    if (status) whereConditions.status = status;
    if (customerId) whereConditions.customerId = customerId;
    if (sellerId) whereConditions.sellerId = sellerId;
    if (deliveryType) whereConditions.deliveryType = deliveryType;
    if (paymentStatus) whereConditions.paymentStatus = paymentStatus;
    
    if (startDate && endDate) {
      whereConditions.saleDate = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    } else if (startDate) {
      whereConditions.saleDate = {
        [Op.gte]: new Date(startDate)
      };
    } else if (endDate) {
      whereConditions.saleDate = {
        [Op.lte]: new Date(endDate)
      };
    }
    
    // Pagination
    const offset = (page - 1) * limit;
    
    const { count, rows: sales } = await Sale.findAndCountAll({
      where: whereConditions,
      include: [
        { model: Customer },
        { model: User, as: 'Seller', attributes: ['id', 'name'] },
        { model: Truck }
      ],
      order: [['saleDate', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    res.status(200).json({
      sales,
      totalCount: count,
      currentPage: parseInt(page),
      totalPages: Math.ceil(count / limit)
    });
  } catch (error) {
    console.error('Get all sales error:', error);
    res.status(500).json({ message: 'Server error while fetching sales' });
  }
};

// Get sale by ID
const getSaleById = async (req, res) => {
  try {
    const saleId = req.params.id;
    
    const sale = await Sale.findOne({
      where: { id: saleId },
      include: [
        { model: Customer },
        { model: User, as: 'Seller', attributes: ['id', 'name'] },
        { model: Truck },
        { 
          model: SaleItem,
          include: [{ model: Cylinder }]
        }
      ]
    });
    
    if (!sale) {
      return res.status(404).json({ message: 'Sale not found' });
    }
    
    res.status(200).json({ sale });
  } catch (error) {
    console.error('Get sale by ID error:', error);
    res.status(500).json({ message: 'Server error while fetching sale' });
  }
};

// Create new sale
const createSale = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { 
      customerId,
      deliveryType,
      truckId,
      items,
      totalAmount,
      paidAmount,
      paymentMethod,
      notes,
      deliveryAddress
    } = req.body;
    
    const sellerId = req.user.id;
    
    // Validate required fields
    if (!customerId || !deliveryType || !items || !items.length || totalAmount === undefined) {
      await transaction.rollback();
      return res.status(400).json({ 
        message: 'Customer ID, delivery type, items, and total amount are required' 
      });
    }
    
    // Check if customer exists
    const customer = await Customer.findOne({
      where: { id: customerId, isActive: true },
      transaction
    });
    
    if (!customer) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Customer not found' });
    }
    
    // Check if truck exists and is available if delivery type is Truck Delivery
    if (deliveryType === 'Truck Delivery') {
      if (!truckId) {
        await transaction.rollback();
        return res.status(400).json({ message: 'Truck ID is required for truck delivery' });
      }
      
      const truck = await Truck.findOne({
        where: { id: truckId, isActive: true, status: 'Available' },
        transaction
      });
      
      if (!truck) {
        await transaction.rollback();
        return res.status(404).json({ message: 'Truck not found or not available' });
      }
      
      // Update truck status
      truck.status = 'On Delivery';
      await truck.save({ transaction });
    }
    
    // Calculate payment status
    let paymentStatus = 'Unpaid';
    if (paidAmount >= totalAmount) {
      paymentStatus = 'Paid';
    } else if (paidAmount > 0) {
      paymentStatus = 'Partial';
    }
    
    // Generate invoice number
    const invoiceNumber = generateInvoiceNumber();
    
    // Create new sale
    const newSale = await Sale.create({
      invoiceNumber,
      customerId,
      sellerId,
      deliveryType,
      truckId: deliveryType === 'Truck Delivery' ? truckId : null,
      status: 'Pending',
      totalAmount,
      paidAmount: paidAmount || 0,
      paymentStatus,
      paymentMethod: paymentMethod || 'Cash',
      notes,
      deliveryAddress: deliveryAddress || customer.address
    }, { transaction });
    
    // Check if all cylinders exist and are available
    const cylinderIds = items.map(item => item.cylinderId);
    const cylinders = await Cylinder.findAll({
      where: { 
        id: { [Op.in]: cylinderIds },
        isActive: true,
        status: 'Full'
      },
      transaction
    });
    
    if (cylinders.length !== cylinderIds.length) {
      await transaction.rollback();
      return res.status(400).json({ 
        message: 'One or more cylinders are not available for sale' 
      });
    }
    
    // Create sale items
    const saleItems = await Promise.all(
      items.map(item => 
        SaleItem.create({
          saleId: newSale.id,
          cylinderId: item.cylinderId,
          price: item.price
        }, { transaction })
      )
    );
    
    // Update cylinders status and current customer
    await Promise.all(
      cylinders.map(cylinder => {
        cylinder.status = 'In Delivery';
        cylinder.currentCustomerId = customerId;
        return cylinder.save({ transaction });
      })
    );
    
    // Update customer credit if payment method is Credit
    if (paymentMethod === 'Credit') {
      const unpaidAmount = totalAmount - (paidAmount || 0);
      if (unpaidAmount > 0) {
        customer.currentCredit += unpaidAmount;
        await customer.save({ transaction });
      }
    }
    
    await transaction.commit();
    
    res.status(201).json({
      message: 'Sale created successfully',
      sale: newSale,
      items: saleItems
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Create sale error:', error);
    res.status(500).json({ message: 'Server error while creating sale' });
  }
};

// Update sale status
const updateSaleStatus = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const saleId = req.params.id;
    const { status, customerSignature, deliveryDate } = req.body;
    
    // Validate input
    if (!status) {
      await transaction.rollback();
      return res.status(400).json({ message: 'Status is required' });
    }
    
    // Check if sale exists
    const sale = await Sale.findOne({
      where: { id: saleId },
      include: [
        { model: SaleItem, include: [{ model: Cylinder }] },
        { model: Truck }
      ],
      transaction
    });
    
    if (!sale) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Sale not found' });
    }
    
    // Update sale
    sale.status = status;
    if (customerSignature) sale.customerSignature = customerSignature;
    if (deliveryDate) sale.deliveryDate = deliveryDate;
    
    // Update related records based on status change
    if (status === 'Delivered' || status === 'Completed') {
      // Update cylinders status
      for (const item of sale.SaleItems) {
        const cylinder = item.Cylinder;
        cylinder.status = 'Full'; // Stays full but now at customer
        await cylinder.save({ transaction });
      }
      
      // Update truck status if delivery was by truck
      if (sale.deliveryType === 'Truck Delivery' && sale.Truck) {
        const truck = sale.Truck;
        truck.status = 'Available';
        await truck.save({ transaction });
      }
    } else if (status === 'Cancelled') {
      // Return cylinders to inventory
      for (const item of sale.SaleItems) {
        const cylinder = item.Cylinder;
        cylinder.status = 'Full';
        cylinder.currentCustomerId = null;
        await cylinder.save({ transaction });
      }
      
      // Make truck available again if delivery was by truck
      if (sale.deliveryType === 'Truck Delivery' && sale.Truck) {
        const truck = sale.Truck;
        truck.status = 'Available';
        await truck.save({ transaction });
      }
      
      // Reduce customer credit if payment was by credit
      if (sale.paymentMethod === 'Credit' && sale.paymentStatus !== 'Paid') {
        const customer = await Customer.findByPk(sale.customerId, { transaction });
        if (customer) {
          const unpaidAmount = sale.totalAmount - sale.paidAmount;
          if (unpaidAmount > 0 && customer.currentCredit >= unpaidAmount) {
            customer.currentCredit -= unpaidAmount;
            await customer.save({ transaction });
          }
        }
      }
    }
    
    await sale.save({ transaction });
    
    await transaction.commit();
    
    res.status(200).json({
      message: 'Sale status updated successfully',
      sale
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Update sale status error:', error);
    res.status(500).json({ message: 'Server error while updating sale status' });
  }
};

// Record cylinder return
const recordCylinderReturn = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const saleItemId = req.params.itemId;
    const { returnDate } = req.body;
    
    if (!returnDate) {
      await transaction.rollback();
      return res.status(400).json({ message: 'Return date is required' });
    }
    
    // Check if sale item exists
    const saleItem = await SaleItem.findOne({
      where: { id: saleItemId },
      include: [
        { model: Cylinder },
        { model: Sale }
      ],
      transaction
    });
    
    if (!saleItem) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Sale item not found' });
    }
    
    // Check if cylinder is already returned
    if (saleItem.returnedEmpty) {
      await transaction.rollback();
      return res.status(400).json({ message: 'Cylinder already returned' });
    }
    
    // Update sale item
    saleItem.returnedEmpty = true;
    saleItem.returnDate = new Date(returnDate);
    await saleItem.save({ transaction });
    
    // Update cylinder status
    const cylinder = saleItem.Cylinder;
    cylinder.status = 'Empty';
    cylinder.currentCustomerId = null;
    await cylinder.save({ transaction });
    
    await transaction.commit();
    
    res.status(200).json({
      message: 'Cylinder return recorded successfully',
      saleItem
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Record cylinder return error:', error);
    res.status(500).json({ message: 'Server error while recording cylinder return' });
  }
};

// Update sale payment
const updateSalePayment = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const saleId = req.params.id;
    const { paidAmount, paymentMethod, notes } = req.body;
    
    // Validate input
    if (paidAmount === undefined) {
      await transaction.rollback();
      return res.status(400).json({ message: 'Paid amount is required' });
    }
    
    // Check if sale exists
    const sale = await Sale.findOne({
      where: { id: saleId },
      transaction
    });
    
    if (!sale) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Sale not found' });
    }
    
    // Check if sale is already paid in full
    if (sale.paymentStatus === 'Paid') {
      await transaction.rollback();
      return res.status(400).json({ message: 'Sale is already paid in full' });
    }
    
    // Update payment amount
    const newPaidAmount = sale.paidAmount + parseFloat(paidAmount);
    sale.paidAmount = newPaidAmount;
    
    // Update payment status
    if (newPaidAmount >= sale.totalAmount) {
      sale.paymentStatus = 'Paid';
    } else if (newPaidAmount > 0) {
      sale.paymentStatus = 'Partial';
    }
    
    // Update payment method if provided
    if (paymentMethod) sale.paymentMethod = paymentMethod;
    
    // Update notes if provided
    if (notes) {
      sale.notes = sale.notes 
        ? `${sale.notes}\n${new Date().toISOString()}: Payment update - ${notes}` 
        : `${new Date().toISOString()}: Payment update - ${notes}`;
    }
    
    // Update customer credit if this payment reduces credit
    if (sale.paymentMethod === 'Credit') {
      const customer = await Customer.findByPk(sale.customerId, { transaction });
      if (customer) {
        const creditReduction = Math.min(
          parseFloat(paidAmount),
          customer.currentCredit
        );
        if (creditReduction > 0) {
          customer.currentCredit -= creditReduction;
          await customer.save({ transaction });
        }
      }
    }
    
    await sale.save({ transaction });
    
    await transaction.commit();
    
    res.status(200).json({
      message: 'Sale payment updated successfully',
      sale
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Update sale payment error:', error);
    res.status(500).json({ message: 'Server error while updating sale payment' });
  }
};

module.exports = {
  getAllSales,
  getSaleById,
  createSale,
  updateSaleStatus,
  recordCylinderReturn,
  updateSalePayment
};
