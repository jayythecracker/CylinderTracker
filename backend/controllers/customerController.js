const { Customer, Sale } = require('../models');
const { Op } = require('sequelize');

/**
 * Get all customers with pagination and filtering
 */
exports.getAllCustomers = async (req, res) => {
  try {
    // Get query parameters for filtering and pagination
    const { 
      type, 
      paymentType, 
      active,
      search,
      page = 1, 
      limit = 20 
    } = req.query;
    
    // Build filter object
    const filter = {};
    
    if (type) {
      filter.type = type;
    }
    
    if (paymentType) {
      filter.paymentType = paymentType;
    }
    
    if (active !== undefined) {
      filter.active = active === 'true';
    }
    
    if (search) {
      filter[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { contact: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
        { address: { [Op.iLike]: `%${search}%` } }
      ];
    }
    
    // Calculate pagination
    const offset = (page - 1) * limit;
    
    // Find customers with pagination
    const { count, rows: customers } = await Customer.findAndCountAll({
      where: filter,
      order: [['name', 'ASC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    // Calculate total pages
    const totalPages = Math.ceil(count / limit);
    
    // Send response
    res.json({
      success: true,
      data: { 
        customers,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages
        }
      }
    });
  } catch (error) {
    console.error('Get all customers error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving customers',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get customer by ID
 */
exports.getCustomerById = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find customer
    const customer = await Customer.findByPk(id);
    
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }
    
    // Get sales count and total amount
    const salesStats = await Sale.findOne({
      attributes: [
        [sequelize.fn('COUNT', sequelize.col('id')), 'totalSales'],
        [sequelize.fn('SUM', sequelize.col('totalAmount')), 'totalAmount']
      ],
      where: { customerId: id }
    });
    
    // Send response
    res.json({
      success: true,
      data: { 
        customer,
        stats: {
          totalSales: salesStats.getDataValue('totalSales') || 0,
          totalAmount: salesStats.getDataValue('totalAmount') || 0
        }
      }
    });
  } catch (error) {
    console.error('Get customer by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving customer',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Create new customer
 */
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
    
    // Validate input
    if (!name || !type || !address || !contact) {
      return res.status(400).json({
        success: false,
        message: 'Name, type, address, and contact are required'
      });
    }
    
    // Create new customer
    const customer = await Customer.create({
      name,
      type,
      address,
      contact,
      email,
      paymentType: paymentType || 'Cash',
      priceGroup: priceGroup || 'Standard',
      creditLimit: creditLimit || null,
      notes: notes || null
    });
    
    // Send response
    res.status(201).json({
      success: true,
      data: { customer }
    });
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while creating customer',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Update customer
 */
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
      active,
      notes
    } = req.body;
    
    // Find customer
    const customer = await Customer.findByPk(id);
    
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }
    
    // Update customer fields
    await customer.update({
      name: name || customer.name,
      type: type || customer.type,
      address: address || customer.address,
      contact: contact || customer.contact,
      email: email !== undefined ? email : customer.email,
      paymentType: paymentType || customer.paymentType,
      priceGroup: priceGroup || customer.priceGroup,
      creditLimit: creditLimit !== undefined ? creditLimit : customer.creditLimit,
      active: active !== undefined ? active : customer.active,
      notes: notes !== undefined ? notes : customer.notes
    });
    
    // Send response
    res.json({
      success: true,
      data: { customer }
    });
  } catch (error) {
    console.error('Update customer error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating customer',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Delete customer
 */
exports.deleteCustomer = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find customer
    const customer = await Customer.findByPk(id);
    
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }
    
    // Check if customer has sales
    const salesCount = await Sale.count({
      where: { customerId: id }
    });
    
    if (salesCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete customer with ${salesCount} sales records. Consider deactivating instead.`
      });
    }
    
    // Delete customer
    await customer.destroy();
    
    // Send response
    res.json({
      success: true,
      message: 'Customer deleted successfully'
    });
  } catch (error) {
    console.error('Delete customer error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while deleting customer',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Get customer sales history
 */
exports.getCustomerSales = async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20 } = req.query;
    
    // Find customer
    const customer = await Customer.findByPk(id);
    
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }
    
    // Calculate pagination
    const offset = (page - 1) * limit;
    
    // Find sales with pagination
    const { count, rows: sales } = await Sale.findAndCountAll({
      where: { customerId: id },
      order: [['saleDate', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset),
      include: [
        { model: User, as: 'seller', attributes: ['id', 'name'] },
        { model: Truck, as: 'truck', attributes: ['id', 'licenseNumber'] }
      ]
    });
    
    // Calculate total pages
    const totalPages = Math.ceil(count / limit);
    
    // Send response
    res.json({
      success: true,
      data: { 
        customer,
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
    console.error('Get customer sales error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving customer sales',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Update customer balance
 */
exports.updateBalance = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, notes, operation } = req.body;
    
    // Validate input
    if (!amount || !operation) {
      return res.status(400).json({
        success: false,
        message: 'Amount and operation (add/subtract) are required'
      });
    }
    
    // Find customer
    const customer = await Customer.findByPk(id);
    
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }
    
    let newBalance;
    
    // Update balance based on operation
    if (operation === 'add') {
      newBalance = parseFloat(customer.balance) + parseFloat(amount);
    } else if (operation === 'subtract') {
      newBalance = parseFloat(customer.balance) - parseFloat(amount);
    } else {
      return res.status(400).json({
        success: false,
        message: 'Operation must be either "add" or "subtract"'
      });
    }
    
    // Update customer balance
    await customer.update({
      balance: newBalance,
      notes: notes ? (customer.notes ? `${customer.notes}\n${notes}` : notes) : customer.notes
    });
    
    // Send response
    res.json({
      success: true,
      data: { 
        customer,
        balanceAdjustment: {
          previousBalance: parseFloat(customer.balance) - (operation === 'add' ? parseFloat(amount) : -parseFloat(amount)),
          adjustment: operation === 'add' ? parseFloat(amount) : -parseFloat(amount),
          newBalance
        }
      }
    });
  } catch (error) {
    console.error('Update customer balance error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating customer balance',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};
