const Customer = require('../models/customer');
const { Op } = require('sequelize');

// Get all customers with optional filters
const getAllCustomers = async (req, res) => {
  try {
    const { 
      type, 
      paymentType, 
      search,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter conditions
    const whereConditions = { isActive: true };
    
    if (type) whereConditions.type = type;
    if (paymentType) whereConditions.paymentType = paymentType;
    
    if (search) {
      whereConditions[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { contactPerson: { [Op.iLike]: `%${search}%` } },
        { contactNumber: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } }
      ];
    }
    
    // Pagination
    const offset = (page - 1) * limit;
    
    const { count, rows: customers } = await Customer.findAndCountAll({
      where: whereConditions,
      order: [['name', 'ASC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    res.status(200).json({
      customers,
      totalCount: count,
      currentPage: parseInt(page),
      totalPages: Math.ceil(count / limit)
    });
  } catch (error) {
    console.error('Get all customers error:', error);
    res.status(500).json({ message: 'Server error while fetching customers' });
  }
};

// Get customer by ID
const getCustomerById = async (req, res) => {
  try {
    const customerId = req.params.id;
    
    const customer = await Customer.findOne({
      where: { id: customerId, isActive: true }
    });
    
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    
    res.status(200).json({ customer });
  } catch (error) {
    console.error('Get customer by ID error:', error);
    res.status(500).json({ message: 'Server error while fetching customer' });
  }
};

// Create new customer
const createCustomer = async (req, res) => {
  try {
    const { 
      name, 
      type, 
      address, 
      contactPerson, 
      contactNumber,
      email,
      paymentType,
      priceGroup,
      creditLimit
    } = req.body;
    
    // Validate required fields
    if (!name || !type || !address || !contactNumber) {
      return res.status(400).json({ 
        message: 'Name, type, address, and contact number are required' 
      });
    }
    
    // Create new customer
    const newCustomer = await Customer.create({
      name,
      type,
      address,
      contactPerson,
      contactNumber,
      email,
      paymentType: paymentType || 'Cash',
      priceGroup,
      creditLimit: creditLimit || 0,
      currentCredit: 0
    });
    
    res.status(201).json({
      message: 'Customer created successfully',
      customer: newCustomer
    });
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({ message: 'Server error while creating customer' });
  }
};

// Update customer
const updateCustomer = async (req, res) => {
  try {
    const customerId = req.params.id;
    const { 
      name, 
      type, 
      address, 
      contactPerson, 
      contactNumber,
      email,
      paymentType,
      priceGroup,
      creditLimit
    } = req.body;
    
    const customer = await Customer.findOne({
      where: { id: customerId, isActive: true }
    });
    
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    
    // Update fields if provided
    if (name) customer.name = name;
    if (type) customer.type = type;
    if (address) customer.address = address;
    if (contactPerson !== undefined) customer.contactPerson = contactPerson;
    if (contactNumber) customer.contactNumber = contactNumber;
    if (email !== undefined) customer.email = email;
    if (paymentType) customer.paymentType = paymentType;
    if (priceGroup !== undefined) customer.priceGroup = priceGroup;
    if (creditLimit !== undefined) customer.creditLimit = creditLimit;
    
    await customer.save();
    
    res.status(200).json({
      message: 'Customer updated successfully',
      customer
    });
  } catch (error) {
    console.error('Update customer error:', error);
    res.status(500).json({ message: 'Server error while updating customer' });
  }
};

// Delete customer (soft delete)
const deleteCustomer = async (req, res) => {
  try {
    const customerId = req.params.id;
    
    const customer = await Customer.findByPk(customerId);
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    
    // Soft delete
    customer.isActive = false;
    await customer.save();
    
    res.status(200).json({ message: 'Customer deleted successfully' });
  } catch (error) {
    console.error('Delete customer error:', error);
    res.status(500).json({ message: 'Server error while deleting customer' });
  }
};

// Update customer credit
const updateCustomerCredit = async (req, res) => {
  try {
    const customerId = req.params.id;
    const { amount, operation } = req.body;
    
    if (amount === undefined || !operation) {
      return res.status(400).json({ 
        message: 'Amount and operation (add/subtract) are required' 
      });
    }
    
    const customer = await Customer.findOne({
      where: { id: customerId, isActive: true }
    });
    
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    
    // Update credit balance
    if (operation === 'add') {
      customer.currentCredit += parseFloat(amount);
    } else if (operation === 'subtract') {
      customer.currentCredit -= parseFloat(amount);
      
      // Ensure credit doesn't go below 0
      if (customer.currentCredit < 0) {
        customer.currentCredit = 0;
      }
    } else {
      return res.status(400).json({ message: 'Invalid operation, use "add" or "subtract"' });
    }
    
    await customer.save();
    
    res.status(200).json({
      message: 'Customer credit updated successfully',
      customer
    });
  } catch (error) {
    console.error('Update customer credit error:', error);
    res.status(500).json({ message: 'Server error while updating customer credit' });
  }
};

module.exports = {
  getAllCustomers,
  getCustomerById,
  createCustomer,
  updateCustomer,
  deleteCustomer,
  updateCustomerCredit
};
