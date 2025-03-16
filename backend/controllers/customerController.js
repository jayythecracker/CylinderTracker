const { Customer, CUSTOMER_TYPES, PAYMENT_TYPES } = require('../models/Customer');
const { Sale } = require('../models/Sale');
const { Op } = require('sequelize');

// Get all customers with pagination and filters
exports.getAllCustomers = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      type, 
      paymentType, 
      search,
      sortBy = 'createdAt',
      order = 'DESC'
    } = req.query;

    const offset = (page - 1) * limit;
    let whereClause = {};

    // Apply filters
    if (type && Object.values(CUSTOMER_TYPES).includes(type)) {
      whereClause.type = type;
    }

    if (paymentType && Object.values(PAYMENT_TYPES).includes(paymentType)) {
      whereClause.paymentType = paymentType;
    }

    if (search) {
      whereClause = {
        ...whereClause,
        [Op.or]: [
          { name: { [Op.iLike]: `%${search}%` } },
          { contact: { [Op.iLike]: `%${search}%` } },
          { email: { [Op.iLike]: `%${search}%` } }
        ]
      };
    }

    // Get customers with pagination
    const { count, rows: customers } = await Customer.findAndCountAll({
      where: whereClause,
      order: [[sortBy, order]],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.status(200).json({
      customers,
      totalCount: count,
      totalPages: Math.ceil(count / limit),
      currentPage: parseInt(page)
    });
  } catch (error) {
    console.error('Get all customers error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get customer by ID
exports.getCustomerById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const customer = await Customer.findByPk(id);
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    // Get recent sales for this customer
    const recentSales = await Sale.findAll({
      where: { customerId: id },
      order: [['createdAt', 'DESC']],
      limit: 5
    });

    res.status(200).json({ 
      customer,
      recentSales
    });
  } catch (error) {
    console.error('Get customer by ID error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Create customer
exports.createCustomer = async (req, res) => {
  try {
    const {
      name,
      type,
      address,
      contact,
      email,
      paymentType,
      priceGroup,
      creditLimit,
      notes
    } = req.body;

    // Validate required fields
    if (!name || !type) {
      return res.status(400).json({ message: 'Please provide name and customer type' });
    }

    // Validate type
    if (!Object.values(CUSTOMER_TYPES).includes(type)) {
      return res.status(400).json({ message: 'Invalid customer type' });
    }

    // Validate payment type
    const validPaymentType = paymentType && Object.values(PAYMENT_TYPES).includes(paymentType)
      ? paymentType
      : PAYMENT_TYPES.CASH;

    // Create customer
    const customer = await Customer.create({
      name,
      type,
      address: address || '',
      contact: contact || '',
      email: email || null,
      paymentType: validPaymentType,
      priceGroup: priceGroup || null,
      creditLimit: creditLimit || 0,
      notes: notes || ''
    });

    res.status(201).json({
      message: 'Customer created successfully',
      customer
    });
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update customer
exports.updateCustomer = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      type,
      address,
      contact,
      email,
      paymentType,
      priceGroup,
      creditLimit,
      balance,
      isActive,
      notes
    } = req.body;

    // Find customer
    const customer = await Customer.findByPk(id);
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    // Update fields
    if (name) customer.name = name;
    
    if (type && Object.values(CUSTOMER_TYPES).includes(type)) {
      customer.type = type;
    }
    
    if (address !== undefined) customer.address = address;
    if (contact !== undefined) customer.contact = contact;
    if (email !== undefined) customer.email = email;
    
    if (paymentType && Object.values(PAYMENT_TYPES).includes(paymentType)) {
      customer.paymentType = paymentType;
    }
    
    if (priceGroup !== undefined) customer.priceGroup = priceGroup;
    if (creditLimit !== undefined) customer.creditLimit = creditLimit;
    if (balance !== undefined) customer.balance = balance;
    if (isActive !== undefined) customer.isActive = isActive;
    if (notes !== undefined) customer.notes = notes;

    await customer.save();

    res.status(200).json({
      message: 'Customer updated successfully',
      customer
    });
  } catch (error) {
    console.error('Update customer error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Delete customer
exports.deleteCustomer = async (req, res) => {
  try {
    const { id } = req.params;

    // Find customer
    const customer = await Customer.findByPk(id);
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    // Check if customer has associated sales
    const salesCount = await Sale.count({ where: { customerId: id } });
    if (salesCount > 0) {
      // Don't delete, just mark as inactive
      customer.isActive = false;
      await customer.save();
      
      return res.status(200).json({ 
        message: 'Customer has sales history and cannot be deleted. Marked as inactive instead.'
      });
    }

    await customer.destroy();
    res.status(200).json({ message: 'Customer deleted successfully' });
  } catch (error) {
    console.error('Delete customer error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update customer balance
exports.updateBalance = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, operation, notes } = req.body;

    // Validate input
    if (!amount || !operation || !['add', 'subtract', 'set'].includes(operation)) {
      return res.status(400).json({ message: 'Please provide amount and valid operation (add, subtract, or set)' });
    }

    // Find customer
    const customer = await Customer.findByPk(id);
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    // Update balance
    let newBalance = customer.balance;
    if (operation === 'add') {
      newBalance += parseFloat(amount);
    } else if (operation === 'subtract') {
      newBalance -= parseFloat(amount);
    } else if (operation === 'set') {
      newBalance = parseFloat(amount);
    }

    customer.balance = newBalance;
    if (notes) customer.notes = notes;
    await customer.save();

    res.status(200).json({
      message: 'Customer balance updated successfully',
      customer: {
        id: customer.id,
        name: customer.name,
        balance: customer.balance
      }
    });
  } catch (error) {
    console.error('Update customer balance error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
