const { Sale, SaleItem } = require('../models/Sale');
const { Customer } = require('../models/Customer');
const { Cylinder } = require('../models/Cylinder');
const { FillingSession, FillingSessionCylinder } = require('../models/FillingLine');
const { sequelize } = require('../config/db');
const { Op } = require('sequelize');

// Daily sales report
exports.dailySalesReport = async (req, res) => {
  try {
    const { date } = req.query;
    let targetDate = date ? new Date(date) : new Date();
    
    // Set to start of day
    targetDate.setHours(0, 0, 0, 0);
    const nextDay = new Date(targetDate);
    nextDay.setDate(nextDay.getDate() + 1);

    // Get sales for the target date
    const sales = await Sale.findAll({
      where: {
        saleDate: {
          [Op.gte]: targetDate,
          [Op.lt]: nextDay
        }
      },
      include: [
        {
          model: Customer,
          as: 'customer',
          attributes: ['id', 'name', 'type']
        }
      ]
    });

    // Calculate totals
    const totalSales = sales.length;
    const totalAmount = sales.reduce((sum, sale) => sum + parseFloat(sale.totalAmount), 0);
    const totalPaid = sales.reduce((sum, sale) => sum + parseFloat(sale.paidAmount), 0);
    const totalOutstanding = totalAmount - totalPaid;

    // Get sales by customer type
    const salesByCustomerType = {};
    sales.forEach(sale => {
      const customerType = sale.customer.type;
      if (!salesByCustomerType[customerType]) {
        salesByCustomerType[customerType] = {
          count: 0,
          amount: 0
        };
      }
      salesByCustomerType[customerType].count++;
      salesByCustomerType[customerType].amount += parseFloat(sale.totalAmount);
    });

    res.status(200).json({
      date: targetDate.toISOString().split('T')[0],
      totalSales,
      totalAmount,
      totalPaid,
      totalOutstanding,
      salesByCustomerType,
      sales
    });
  } catch (error) {
    console.error('Daily sales report error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Monthly sales report
exports.monthlySalesReport = async (req, res) => {
  try {
    const { year, month } = req.query;
    const currentDate = new Date();
    const targetYear = year ? parseInt(year) : currentDate.getFullYear();
    const targetMonth = month ? parseInt(month) - 1 : currentDate.getMonth();
    
    // Create date range for the month
    const startDate = new Date(targetYear, targetMonth, 1);
    const endDate = new Date(targetYear, targetMonth + 1, 0);
    endDate.setHours(23, 59, 59, 999);

    // Get sales for the month
    const sales = await Sale.findAll({
      where: {
        saleDate: {
          [Op.between]: [startDate, endDate]
        }
      },
      include: [
        {
          model: Customer,
          as: 'customer',
          attributes: ['id', 'name', 'type']
        }
      ]
    });

    // Calculate totals
    const totalSales = sales.length;
    const totalAmount = sales.reduce((sum, sale) => sum + parseFloat(sale.totalAmount), 0);
    const totalPaid = sales.reduce((sum, sale) => sum + parseFloat(sale.paidAmount), 0);
    const totalOutstanding = totalAmount - totalPaid;

    // Get daily breakdown
    const dailySales = {};
    sales.forEach(sale => {
      const saleDate = sale.saleDate.toISOString().split('T')[0];
      if (!dailySales[saleDate]) {
        dailySales[saleDate] = {
          count: 0,
          amount: 0
        };
      }
      dailySales[saleDate].count++;
      dailySales[saleDate].amount += parseFloat(sale.totalAmount);
    });

    // Get sales by customer type
    const salesByCustomerType = {};
    sales.forEach(sale => {
      const customerType = sale.customer.type;
      if (!salesByCustomerType[customerType]) {
        salesByCustomerType[customerType] = {
          count: 0,
          amount: 0
        };
      }
      salesByCustomerType[customerType].count++;
      salesByCustomerType[customerType].amount += parseFloat(sale.totalAmount);
    });

    res.status(200).json({
      year: targetYear,
      month: targetMonth + 1,
      totalSales,
      totalAmount,
      totalPaid,
      totalOutstanding,
      dailySales,
      salesByCustomerType
    });
  } catch (error) {
    console.error('Monthly sales report error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Cylinder status report
exports.cylinderStatusReport = async (req, res) => {
  try {
    // Get cylinder counts by status
    const statusCounts = await Cylinder.findAll({
      attributes: ['status', [sequelize.fn('COUNT', sequelize.col('id')), 'count']],
      group: ['status']
    });

    // Get cylinder counts by type
    const typeCounts = await Cylinder.findAll({
      attributes: ['type', [sequelize.fn('COUNT', sequelize.col('id')), 'count']],
      group: ['type']
    });

    // Get factory distribution
    const factoryDistribution = await Cylinder.findAll({
      attributes: ['factoryId', [sequelize.fn('COUNT', sequelize.col('id')), 'count']],
      group: ['factoryId'],
      include: [
        {
          model: require('../models/Factory').Factory,
          as: 'factory',
          attributes: ['id', 'name']
        }
      ]
    });

    res.status(200).json({
      statusCounts,
      typeCounts,
      factoryDistribution,
      totalCylinders: statusCounts.reduce((sum, item) => sum + parseInt(item.dataValues.count), 0)
    });
  } catch (error) {
    console.error('Cylinder status report error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Filling activity report
exports.fillingActivityReport = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    let dateFilter = {};
    if (startDate && endDate) {
      dateFilter = {
        startTime: {
          [Op.between]: [new Date(startDate), new Date(endDate)]
        }
      };
    } else if (startDate) {
      dateFilter = {
        startTime: {
          [Op.gte]: new Date(startDate)
        }
      };
    } else if (endDate) {
      dateFilter = {
        startTime: {
          [Op.lte]: new Date(endDate)
        }
      };
    } else {
      // Default to last 30 days
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      dateFilter = {
        startTime: {
          [Op.gte]: thirtyDaysAgo
        }
      };
    }

    // Get filling sessions in date range
    const sessions = await FillingSession.findAll({
      where: dateFilter,
      include: [
        {
          model: require('../models/FillingLine').FillingLine,
          as: 'fillingLine'
        }
      ],
      order: [['startTime', 'DESC']]
    });

    // Get cylinder counts for each session
    const sessionsWithStats = await Promise.all(sessions.map(async (session) => {
      const cylinders = await FillingSessionCylinder.findAll({
        where: { fillingSessionId: session.id },
        attributes: ['status', [sequelize.fn('COUNT', sequelize.col('id')), 'count']],
        group: ['status']
      });

      const stats = {
        total: 0,
        pending: 0,
        filling: 0,
        success: 0,
        failed: 0
      };

      cylinders.forEach(cylinder => {
        const count = parseInt(cylinder.dataValues.count);
        stats[cylinder.status] = count;
        stats.total += count;
      });

      return {
        ...session.toJSON(),
        stats
      };
    }));

    // Calculate overall statistics
    const overall = {
      totalSessions: sessions.length,
      totalCylinders: 0,
      successfulFills: 0,
      failedFills: 0,
      successRate: 0
    };

    sessionsWithStats.forEach(session => {
      overall.totalCylinders += session.stats.total;
      overall.successfulFills += session.stats.success;
      overall.failedFills += session.stats.failed;
    });

    overall.successRate = overall.totalCylinders > 0 
      ? ((overall.successfulFills / overall.totalCylinders) * 100).toFixed(2) 
      : 0;

    res.status(200).json({
      startDate: startDate || 'Last 30 days',
      endDate: endDate || 'Today',
      overall,
      sessions: sessionsWithStats
    });
  } catch (error) {
    console.error('Filling activity report error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Customer activity report
exports.customerActivityReport = async (req, res) => {
  try {
    const { customerId, startDate, endDate } = req.query;

    // Validate customerId
    if (!customerId) {
      return res.status(400).json({ message: 'Please provide customer ID' });
    }

    // Find customer
    const customer = await Customer.findByPk(customerId);
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    let dateFilter = { customerId };
    if (startDate && endDate) {
      dateFilter.saleDate = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    } else if (startDate) {
      dateFilter.saleDate = {
        [Op.gte]: new Date(startDate)
      };
    } else if (endDate) {
      dateFilter.saleDate = {
        [Op.lte]: new Date(endDate)
      };
    }

    // Get sales for this customer
    const sales = await Sale.findAll({
      where: dateFilter,
      include: [
        {
          model: SaleItem,
          as: 'items',
          include: [
            {
              model: Cylinder,
              as: 'cylinder',
              attributes: ['id', 'serialNumber', 'type', 'size']
            }
          ]
        }
      ],
      order: [['saleDate', 'DESC']]
    });

    // Calculate statistics
    const stats = {
      totalSales: sales.length,
      totalAmount: sales.reduce((sum, sale) => sum + parseFloat(sale.totalAmount), 0),
      totalPaid: sales.reduce((sum, sale) => sum + parseFloat(sale.paidAmount), 0),
      outstandingBalance: customer.balance,
      cylindersPurchased: 0,
      cylindersReturned: 0,
      cylinderTypes: {}
    };

    sales.forEach(sale => {
      sale.items.forEach(item => {
        if (!item.isReturn) {
          stats.cylindersPurchased++;
          const type = item.cylinder.type;
          if (!stats.cylinderTypes[type]) {
            stats.cylinderTypes[type] = 0;
          }
          stats.cylinderTypes[type]++;
        } else {
          stats.cylindersReturned++;
        }
      });
    });

    res.status(200).json({
      customer: {
        id: customer.id,
        name: customer.name,
        type: customer.type,
        paymentType: customer.paymentType
      },
      startDate: startDate || 'All time',
      endDate: endDate || 'Today',
      stats,
      sales
    });
  } catch (error) {
    console.error('Customer activity report error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
