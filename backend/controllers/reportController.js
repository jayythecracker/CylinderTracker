const { 
  Sale, 
  Filling, 
  Inspection, 
  Cylinder, 
  Customer, 
  Factory, 
  User 
} = require('../models');
const { Op } = require('sequelize');
const sequelize = require('../config/database');

/**
 * Generate dashboard overview report
 */
exports.getDashboardOverview = async (req, res) => {
  try {
    // Get today's date range
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    // Get counts
    const totalCylinders = await Cylinder.count();
    const totalCustomers = await Customer.count();
    const totalFactories = await Factory.count();
    
    // Get cylinder status counts
    const cylinderStatusCounts = await Cylinder.findAll({
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      group: ['status']
    });
    
    // Get today's activity counts
    const todaySales = await Sale.count({
      where: {
        saleDate: {
          [Op.gte]: today,
          [Op.lt]: tomorrow
        }
      }
    });
    
    const todayFillings = await Filling.count({
      where: {
        startTime: {
          [Op.gte]: today,
          [Op.lt]: tomorrow
        }
      }
    });
    
    const todayInspections = await Inspection.count({
      where: {
        inspectionDate: {
          [Op.gte]: today,
          [Op.lt]: tomorrow
        }
      }
    });
    
    // Get current month's sales total
    const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    const monthSalesTotal = await Sale.sum('totalAmount', {
      where: {
        saleDate: {
          [Op.gte]: firstDayOfMonth,
          [Op.lt]: tomorrow
        }
      }
    });
    
    // Get active cylinders in filling/delivery
    const activeCylinders = await Cylinder.count({
      where: {
        status: {
          [Op.in]: ['InTransit']
        }
      }
    });
    
    // Format cylinder status counts
    const cylinderStatus = cylinderStatusCounts.reduce((acc, item) => {
      acc[item.status] = parseInt(item.getDataValue('count'));
      return acc;
    }, {});
    
    // Send response
    res.json({
      success: true,
      data: {
        counts: {
          totalCylinders,
          totalCustomers,
          totalFactories,
          cylinderStatus,
          activeCylinders
        },
        today: {
          sales: todaySales,
          fillings: todayFillings,
          inspections: todayInspections
        },
        monthSalesTotal: monthSalesTotal || 0
      }
    });
  } catch (error) {
    console.error('Dashboard overview error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while generating dashboard overview',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Generate inventory report
 */
exports.getInventoryReport = async (req, res) => {
  try {
    const { factoryId, status, type } = req.query;
    
    // Build filter
    const filter = {};
    
    if (factoryId) {
      filter.factoryId = factoryId;
    }
    
    if (status) {
      filter.status = status;
    }
    
    if (type) {
      filter.type = type;
    }
    
    // Get cylinder counts by status
    const statusCounts = await Cylinder.findAll({
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: filter,
      group: ['status']
    });
    
    // Get cylinder counts by factory
    const factoryCounts = await Cylinder.findAll({
      attributes: [
        'factoryId',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: filter,
      include: [
        { model: Factory, as: 'factory', attributes: ['name'] }
      ],
      group: ['factoryId', 'factory.id', 'factory.name']
    });
    
    // Get cylinder counts by type
    const typeCounts = await Cylinder.findAll({
      attributes: [
        'type',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: filter,
      group: ['type']
    });
    
    // Get cylinders that haven't been filled in 3 months
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);
    
    const inactiveCylinders = await Cylinder.findAll({
      where: {
        ...filter,
        [Op.or]: [
          { lastFilled: null },
          { lastFilled: { [Op.lt]: threeMonthsAgo } }
        ]
      },
      include: [
        { model: Factory, as: 'factory', attributes: ['id', 'name'] }
      ],
      limit: 50
    });
    
    // Format status counts
    const cylinderStatus = statusCounts.reduce((acc, item) => {
      acc[item.status] = parseInt(item.getDataValue('count'));
      return acc;
    }, {});
    
    // Send response
    res.json({
      success: true,
      data: {
        statusBreakdown: cylinderStatus,
        factoryBreakdown: factoryCounts,
        typeBreakdown: typeCounts,
        inactiveCylinders: {
          count: inactiveCylinders.length,
          cylinders: inactiveCylinders
        }
      }
    });
  } catch (error) {
    console.error('Inventory report error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while generating inventory report',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Generate sales report
 */
exports.getSalesReport = async (req, res) => {
  try {
    const { 
      startDate, 
      endDate, 
      customerId, 
      sellerId, 
      deliveryMethod,
      groupBy = 'day'
    } = req.query;
    
    // Build date filter
    const dateFilter = {};
    
    if (startDate || endDate) {
      dateFilter.saleDate = {};
      
      if (startDate) {
        dateFilter.saleDate[Op.gte] = new Date(startDate);
      }
      
      if (endDate) {
        const endDateTime = new Date(endDate);
        endDateTime.setHours(23, 59, 59, 999);
        dateFilter.saleDate[Op.lte] = endDateTime;
      }
    } else {
      // Default to last 30 days
      const today = new Date();
      const thirtyDaysAgo = new Date(today);
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      dateFilter.saleDate = {
        [Op.gte]: thirtyDaysAgo,
        [Op.lte]: today
      };
    }
    
    // Build additional filters
    const filter = { ...dateFilter };
    
    if (customerId) {
      filter.customerId = customerId;
    }
    
    if (sellerId) {
      filter.sellerId = sellerId;
    }
    
    if (deliveryMethod) {
      filter.deliveryMethod = deliveryMethod;
    }
    
    // Get sales data grouped by specified time period
    const salesByTime = await Sale.findAll({
      attributes: [
        [sequelize.fn('date_trunc', groupBy, sequelize.col('saleDate')), 'date'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
        [sequelize.fn('SUM', sequelize.col('totalAmount')), 'totalAmount'],
        [sequelize.fn('SUM', sequelize.col('paidAmount')), 'paidAmount']
      ],
      where: filter,
      group: [sequelize.fn('date_trunc', groupBy, sequelize.col('saleDate'))],
      order: [[sequelize.fn('date_trunc', groupBy, sequelize.col('saleDate')), 'ASC']]
    });
    
    // Get sales data grouped by customer
    const salesByCustomer = await Sale.findAll({
      attributes: [
        'customerId',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
        [sequelize.fn('SUM', sequelize.col('totalAmount')), 'totalAmount'],
        [sequelize.fn('SUM', sequelize.col('paidAmount')), 'paidAmount']
      ],
      where: filter,
      include: [
        { model: Customer, as: 'customer', attributes: ['name', 'type'] }
      ],
      group: ['customerId', 'customer.id', 'customer.name', 'customer.type'],
      order: [[sequelize.fn('SUM', sequelize.col('totalAmount')), 'DESC']],
      limit: 10
    });
    
    // Get sales data grouped by payment status
    const salesByPaymentStatus = await Sale.findAll({
      attributes: [
        'paymentStatus',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
        [sequelize.fn('SUM', sequelize.col('totalAmount')), 'totalAmount']
      ],
      where: filter,
      group: ['paymentStatus']
    });
    
    // Get sales data grouped by delivery status
    const salesByDeliveryStatus = await Sale.findAll({
      attributes: [
        'deliveryStatus',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
        [sequelize.fn('SUM', sequelize.col('totalAmount')), 'totalAmount']
      ],
      where: filter,
      group: ['deliveryStatus']
    });
    
    // Get overall totals
    const totals = await Sale.findOne({
      attributes: [
        [sequelize.fn('COUNT', sequelize.col('id')), 'totalSales'],
        [sequelize.fn('SUM', sequelize.col('totalAmount')), 'totalAmount'],
        [sequelize.fn('SUM', sequelize.col('paidAmount')), 'paidAmount'],
        [
          sequelize.literal('SUM("totalAmount") - SUM("paidAmount")'),
          'outstandingAmount'
        ]
      ],
      where: filter
    });
    
    // Send response
    res.json({
      success: true,
      data: {
        dateRange: {
          start: dateFilter.saleDate?.[Op.gte] || null,
          end: dateFilter.saleDate?.[Op.lte] || null
        },
        totals: {
          sales: parseInt(totals.getDataValue('totalSales') || 0),
          amount: parseFloat(totals.getDataValue('totalAmount') || 0),
          paid: parseFloat(totals.getDataValue('paidAmount') || 0),
          outstanding: parseFloat(totals.getDataValue('outstandingAmount') || 0)
        },
        salesByTime,
        salesByCustomer,
        salesByPaymentStatus,
        salesByDeliveryStatus
      }
    });
  } catch (error) {
    console.error('Sales report error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while generating sales report',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Generate operations report
 */
exports.getOperationsReport = async (req, res) => {
  try {
    const { 
      startDate, 
      endDate,
      userId
    } = req.query;
    
    // Build date filter
    const dateFilter = {};
    
    if (startDate || endDate) {
      const startTimeFilter = {};
      const inspectionDateFilter = {};
      
      if (startDate) {
        startTimeFilter[Op.gte] = new Date(startDate);
        inspectionDateFilter[Op.gte] = new Date(startDate);
      }
      
      if (endDate) {
        const endDateTime = new Date(endDate);
        endDateTime.setHours(23, 59, 59, 999);
        startTimeFilter[Op.lte] = endDateTime;
        inspectionDateFilter[Op.lte] = endDateTime;
      }
      
      dateFilter.filling = { startTime: startTimeFilter };
      dateFilter.inspection = { inspectionDate: inspectionDateFilter };
    } else {
      // Default to last 30 days
      const today = new Date();
      const thirtyDaysAgo = new Date(today);
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      dateFilter.filling = { 
        startTime: {
          [Op.gte]: thirtyDaysAgo,
          [Op.lte]: today
        }
      };
      
      dateFilter.inspection = { 
        inspectionDate: {
          [Op.gte]: thirtyDaysAgo,
          [Op.lte]: today
        }
      };
    }
    
    // Build user filter
    const userFilter = {};
    
    if (userId) {
      userFilter.filling = {
        [Op.or]: [
          { startedById: userId },
          { endedById: userId }
        ]
      };
      
      userFilter.inspection = { inspectedById: userId };
    }
    
    // Get filling data
    const fillingStats = await Filling.findAll({
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        ...dateFilter.filling,
        ...userFilter.filling
      },
      group: ['status']
    });
    
    // Get filling data by day
    const fillingByDay = await Filling.findAll({
      attributes: [
        [sequelize.fn('date_trunc', 'day', sequelize.col('startTime')), 'date'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        ...dateFilter.filling,
        ...userFilter.filling
      },
      group: [sequelize.fn('date_trunc', 'day', sequelize.col('startTime'))],
      order: [[sequelize.fn('date_trunc', 'day', sequelize.col('startTime')), 'ASC']]
    });
    
    // Get inspection data
    const inspectionStats = await Inspection.findAll({
      attributes: [
        'result',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        ...dateFilter.inspection,
        ...userFilter.inspection
      },
      group: ['result']
    });
    
    // Get inspection data by day
    const inspectionByDay = await Inspection.findAll({
      attributes: [
        [sequelize.fn('date_trunc', 'day', sequelize.col('inspectionDate')), 'date'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        ...dateFilter.inspection,
        ...userFilter.inspection
      },
      group: [sequelize.fn('date_trunc', 'day', sequelize.col('inspectionDate'))],
      order: [[sequelize.fn('date_trunc', 'day', sequelize.col('inspectionDate')), 'ASC']]
    });
    
    // Get top filling lines
    const topFillingLines = await Filling.findAll({
      attributes: [
        'lineNumber',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        ...dateFilter.filling,
        ...userFilter.filling
      },
      group: ['lineNumber'],
      order: [[sequelize.fn('COUNT', sequelize.col('id')), 'DESC']],
      limit: 5
    });
    
    // Get top users for filling
    const topFillersData = await Filling.findAll({
      attributes: [
        'startedById',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: dateFilter.filling,
      include: [
        { model: User, as: 'startedBy', attributes: ['name'] }
      ],
      group: ['startedById', 'startedBy.id', 'startedBy.name'],
      order: [[sequelize.fn('COUNT', sequelize.col('id')), 'DESC']],
      limit: 5
    });
    
    // Get top users for inspection
    const topInspectorsData = await Inspection.findAll({
      attributes: [
        'inspectedById',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: dateFilter.inspection,
      include: [
        { model: User, as: 'inspectedBy', attributes: ['name'] }
      ],
      group: ['inspectedById', 'inspectedBy.id', 'inspectedBy.name'],
      order: [[sequelize.fn('COUNT', sequelize.col('id')), 'DESC']],
      limit: 5
    });
    
    // Format the data
    const fillingStatusBreakdown = fillingStats.reduce((acc, item) => {
      acc[item.status] = parseInt(item.getDataValue('count'));
      return acc;
    }, {});
    
    const inspectionResultBreakdown = inspectionStats.reduce((acc, item) => {
      acc[item.result] = parseInt(item.getDataValue('count'));
      return acc;
    }, {});
    
    const topFillers = topFillersData.map(item => ({
      userId: item.startedById,
      name: item.startedBy.name,
      count: parseInt(item.getDataValue('count'))
    }));
    
    const topInspectors = topInspectorsData.map(item => ({
      userId: item.inspectedById,
      name: item.inspectedBy.name,
      count: parseInt(item.getDataValue('count'))
    }));
    
    // Send response
    res.json({
      success: true,
      data: {
        dateRange: {
          start: dateFilter.filling.startTime?.[Op.gte] || null,
          end: dateFilter.filling.startTime?.[Op.lte] || null
        },
        filling: {
          statusBreakdown: fillingStatusBreakdown,
          byDay: fillingByDay,
          topLines: topFillingLines,
          topFillers
        },
        inspection: {
          resultBreakdown: inspectionResultBreakdown,
          byDay: inspectionByDay,
          topInspectors
        }
      }
    });
  } catch (error) {
    console.error('Operations report error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while generating operations report',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

/**
 * Generate customer accounts report
 */
exports.getCustomerAccountsReport = async (req, res) => {
  try {
    // Get customers with outstanding balances
    const creditCustomers = await Customer.findAll({
      where: {
        paymentType: 'Credit',
        balance: {
          [Op.gt]: 0
        }
      },
      order: [['balance', 'DESC']]
    });
    
    // Get total outstanding balance
    const totalOutstanding = creditCustomers.reduce(
      (sum, customer) => sum + parseFloat(customer.balance),
      0
    );
    
    // Get overdue payments (sales that are delivered but not fully paid, older than 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const overduePayments = await Sale.findAll({
      where: {
        deliveryStatus: 'Delivered',
        paymentStatus: {
          [Op.in]: ['Pending', 'Partial']
        },
        saleDate: {
          [Op.lt]: thirtyDaysAgo
        }
      },
      include: [
        { model: Customer, as: 'customer', attributes: ['id', 'name', 'type'] }
      ],
      order: [['saleDate', 'ASC']]
    });
    
    // Get payment statistics by customer type
    const paymentStatsByType = await Customer.findAll({
      attributes: [
        'type',
        [sequelize.fn('COUNT', sequelize.col('id')), 'customerCount'],
        [sequelize.fn('SUM', sequelize.col('balance')), 'totalBalance']
      ],
      where: {
        paymentType: 'Credit'
      },
      group: ['type']
    });
    
    // Send response
    res.json({
      success: true,
      data: {
        summary: {
          totalCreditCustomers: creditCustomers.length,
          totalOutstandingBalance: totalOutstanding,
          overduePaymentsCount: overduePayments.length
        },
        creditCustomers,
        overduePayments,
        paymentStatsByType
      }
    });
  } catch (error) {
    console.error('Customer accounts report error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while generating customer accounts report',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};
