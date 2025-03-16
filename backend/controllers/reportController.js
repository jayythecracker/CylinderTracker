const { sequelize } = require('../config/db');
const { QueryTypes } = require('sequelize');
const { Sale, SaleItem } = require('../models/sale');
const { FillingBatch, FillingDetail } = require('../models/filling');
const Cylinder = require('../models/cylinder');
const Customer = require('../models/customer');

// Get daily sales report
const getDailySalesReport = async (req, res) => {
  try {
    const { date } = req.query;
    
    let reportDate = date ? new Date(date) : new Date();
    
    // Set to start of day
    reportDate.setHours(0, 0, 0, 0);
    
    // Set to end of day
    const endDate = new Date(reportDate);
    endDate.setHours(23, 59, 59, 999);
    
    // Get sales for the day
    const sales = await Sale.findAll({
      where: {
        saleDate: {
          [sequelize.Op.between]: [reportDate, endDate]
        }
      },
      include: [
        { model: Customer, attributes: ['id', 'name', 'type'] },
        { 
          model: SaleItem,
          include: [{ model: Cylinder, attributes: ['id', 'serialNumber', 'size', 'gasType'] }]
        }
      ]
    });
    
    // Calculate total amounts
    const totalSales = sales.length;
    const totalAmount = sales.reduce((sum, sale) => sum + sale.totalAmount, 0);
    const totalPaid = sales.reduce((sum, sale) => sum + sale.paidAmount, 0);
    const totalOutstanding = totalAmount - totalPaid;
    
    // Count by payment method
    const cashSales = sales.filter(sale => sale.paymentMethod === 'Cash').length;
    const creditSales = sales.filter(sale => sale.paymentMethod === 'Credit').length;
    
    // Count by customer type
    const customerTypeCounts = {};
    sales.forEach(sale => {
      const type = sale.Customer?.type || 'Unknown';
      customerTypeCounts[type] = (customerTypeCounts[type] || 0) + 1;
    });
    
    // Count cylinders by size and type
    const cylinderCounts = {};
    sales.forEach(sale => {
      sale.SaleItems.forEach(item => {
        const cylinder = item.Cylinder;
        const key = `${cylinder.size}-${cylinder.gasType}`;
        cylinderCounts[key] = (cylinderCounts[key] || 0) + 1;
      });
    });
    
    res.status(200).json({
      date: reportDate.toISOString().split('T')[0],
      totalSales,
      totalAmount,
      totalPaid,
      totalOutstanding,
      paymentMethods: {
        Cash: cashSales,
        Credit: creditSales
      },
      customerTypes: customerTypeCounts,
      cylinderCounts,
      sales
    });
  } catch (error) {
    console.error('Daily sales report error:', error);
    res.status(500).json({ message: 'Server error while generating daily sales report' });
  }
};

// Get monthly sales report
const getMonthlySalesReport = async (req, res) => {
  try {
    const { month, year } = req.query;
    
    // Default to current month and year if not provided
    const currentDate = new Date();
    const reportMonth = month ? parseInt(month) - 1 : currentDate.getMonth();
    const reportYear = year ? parseInt(year) : currentDate.getFullYear();
    
    // Create start and end dates for the month
    const startDate = new Date(reportYear, reportMonth, 1);
    const endDate = new Date(reportYear, reportMonth + 1, 0, 23, 59, 59, 999);
    
    // Get sales for the month
    const sales = await Sale.findAll({
      where: {
        saleDate: {
          [sequelize.Op.between]: [startDate, endDate]
        }
      },
      include: [
        { model: Customer, attributes: ['id', 'name', 'type'] }
      ]
    });
    
    // Calculate total amounts
    const totalSales = sales.length;
    const totalAmount = sales.reduce((sum, sale) => sum + sale.totalAmount, 0);
    const totalPaid = sales.reduce((sum, sale) => sum + sale.paidAmount, 0);
    const totalOutstanding = totalAmount - totalPaid;
    
    // Group by day
    const dailySales = {};
    sales.forEach(sale => {
      const day = new Date(sale.saleDate).getDate();
      dailySales[day] = dailySales[day] || { count: 0, amount: 0 };
      dailySales[day].count += 1;
      dailySales[day].amount += sale.totalAmount;
    });
    
    // Group by customer type
    const salesByCustomerType = {};
    sales.forEach(sale => {
      const type = sale.Customer?.type || 'Unknown';
      salesByCustomerType[type] = salesByCustomerType[type] || { count: 0, amount: 0 };
      salesByCustomerType[type].count += 1;
      salesByCustomerType[type].amount += sale.totalAmount;
    });
    
    // Group by payment method
    const salesByPaymentMethod = {
      Cash: { count: 0, amount: 0 },
      Credit: { count: 0, amount: 0 }
    };
    
    sales.forEach(sale => {
      const method = sale.paymentMethod;
      salesByPaymentMethod[method].count += 1;
      salesByPaymentMethod[method].amount += sale.totalAmount;
    });
    
    // Group by payment status
    const salesByPaymentStatus = {
      Paid: { count: 0, amount: 0 },
      Partial: { count: 0, amount: 0 },
      Unpaid: { count: 0, amount: 0 }
    };
    
    sales.forEach(sale => {
      const status = sale.paymentStatus;
      salesByPaymentStatus[status].count += 1;
      salesByPaymentStatus[status].amount += sale.totalAmount;
    });
    
    res.status(200).json({
      month: reportMonth + 1,
      year: reportYear,
      totalSales,
      totalAmount,
      totalPaid,
      totalOutstanding,
      dailySales,
      salesByCustomerType,
      salesByPaymentMethod,
      salesByPaymentStatus
    });
  } catch (error) {
    console.error('Monthly sales report error:', error);
    res.status(500).json({ message: 'Server error while generating monthly sales report' });
  }
};

// Get cylinder statistics
const getCylinderStatistics = async (req, res) => {
  try {
    // Count cylinders by status
    const cylindersByStatus = await Cylinder.findAll({
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: { isActive: true },
      group: ['status']
    });
    
    // Count cylinders by gas type
    const cylindersByGasType = await Cylinder.findAll({
      attributes: [
        'gasType',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: { isActive: true },
      group: ['gasType']
    });
    
    // Count cylinders by size
    const cylindersBySize = await Cylinder.findAll({
      attributes: [
        'size',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: { isActive: true },
      group: ['size']
    });
    
    // Get cylinders needing inspection (not inspected in last 90 days)
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
    
    const cylindersNeedingInspection = await Cylinder.count({
      where: {
        isActive: true,
        [sequelize.Op.or]: [
          { lastInspectionDate: null },
          { lastInspectionDate: { [sequelize.Op.lt]: ninetyDaysAgo } }
        ]
      }
    });
    
    // Get cylinders at customer locations
    const cylindersAtCustomers = await Cylinder.count({
      where: {
        isActive: true,
        currentCustomerId: { [sequelize.Op.not]: null }
      }
    });
    
    // Get cylinders in error state
    const cylindersInError = await Cylinder.count({
      where: {
        isActive: true,
        status: 'Error'
      }
    });
    
    // Get total cylinder count
    const totalCylinders = await Cylinder.count({
      where: { isActive: true }
    });
    
    res.status(200).json({
      totalCylinders,
      cylindersByStatus: cylindersByStatus.map(item => ({
        status: item.status,
        count: parseInt(item.get('count'))
      })),
      cylindersByGasType: cylindersByGasType.map(item => ({
        gasType: item.gasType,
        count: parseInt(item.get('count'))
      })),
      cylindersBySize: cylindersBySize.map(item => ({
        size: item.size,
        count: parseInt(item.get('count'))
      })),
      cylindersNeedingInspection,
      cylindersAtCustomers,
      cylindersInError
    });
  } catch (error) {
    console.error('Cylinder statistics error:', error);
    res.status(500).json({ message: 'Server error while generating cylinder statistics' });
  }
};

// Get filling operations report
const getFillingReport = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    // Default to last 30 days if dates not provided
    const today = new Date();
    const defaultStartDate = new Date();
    defaultStartDate.setDate(today.getDate() - 30);
    
    const reportStartDate = startDate ? new Date(startDate) : defaultStartDate;
    const reportEndDate = endDate ? new Date(endDate) : today;
    
    // Set end date to end of day
    reportEndDate.setHours(23, 59, 59, 999);
    
    // Get filling batches for the period
    const fillingBatches = await FillingBatch.findAll({
      where: {
        startTime: {
          [sequelize.Op.between]: [reportStartDate, reportEndDate]
        }
      },
      include: [
        { 
          model: FillingDetail,
          include: [{ model: Cylinder, attributes: ['id', 'serialNumber', 'size', 'gasType'] }]
        }
      ]
    });
    
    // Calculate success and failure rates
    let totalCylinders = 0;
    let successfulFills = 0;
    let failedFills = 0;
    
    fillingBatches.forEach(batch => {
      batch.FillingDetails.forEach(detail => {
        totalCylinders++;
        if (detail.status === 'Success') {
          successfulFills++;
        } else if (detail.status === 'Failed') {
          failedFills++;
        }
      });
    });
    
    const successRate = totalCylinders > 0 ? (successfulFills / totalCylinders) * 100 : 0;
    const failureRate = totalCylinders > 0 ? (failedFills / totalCylinders) * 100 : 0;
    
    // Group fills by gas type
    const fillsByGasType = {};
    fillingBatches.forEach(batch => {
      batch.FillingDetails.forEach(detail => {
        const gasType = detail.Cylinder.gasType;
        fillsByGasType[gasType] = fillsByGasType[gasType] || { total: 0, success: 0, failed: 0 };
        fillsByGasType[gasType].total++;
        
        if (detail.status === 'Success') {
          fillsByGasType[gasType].success++;
        } else if (detail.status === 'Failed') {
          fillsByGasType[gasType].failed++;
        }
      });
    });
    
    // Group by day
    const fillsByDay = {};
    fillingBatches.forEach(batch => {
      const day = new Date(batch.startTime).toISOString().split('T')[0];
      fillsByDay[day] = fillsByDay[day] || { total: 0, success: 0, failed: 0 };
      
      batch.FillingDetails.forEach(detail => {
        fillsByDay[day].total++;
        
        if (detail.status === 'Success') {
          fillsByDay[day].success++;
        } else if (detail.status === 'Failed') {
          fillsByDay[day].failed++;
        }
      });
    });
    
    res.status(200).json({
      startDate: reportStartDate.toISOString().split('T')[0],
      endDate: reportEndDate.toISOString().split('T')[0],
      totalBatches: fillingBatches.length,
      totalCylinders,
      successfulFills,
      failedFills,
      successRate,
      failureRate,
      fillsByGasType,
      fillsByDay
    });
  } catch (error) {
    console.error('Filling report error:', error);
    res.status(500).json({ message: 'Server error while generating filling report' });
  }
};

// Get customer activity report
const getCustomerActivityReport = async (req, res) => {
  try {
    const { customerId, startDate, endDate } = req.query;
    
    if (!customerId) {
      return res.status(400).json({ message: 'Customer ID is required' });
    }
    
    // Check if customer exists
    const customer = await Customer.findOne({
      where: { id: customerId, isActive: true }
    });
    
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    
    // Default to last 90 days if dates not provided
    const today = new Date();
    const defaultStartDate = new Date();
    defaultStartDate.setDate(today.getDate() - 90);
    
    const reportStartDate = startDate ? new Date(startDate) : defaultStartDate;
    const reportEndDate = endDate ? new Date(endDate) : today;
    
    // Set end date to end of day
    reportEndDate.setHours(23, 59, 59, 999);
    
    // Get sales for this customer in the period
    const sales = await Sale.findAll({
      where: {
        customerId,
        saleDate: {
          [sequelize.Op.between]: [reportStartDate, reportEndDate]
        }
      },
      include: [
        { 
          model: SaleItem,
          include: [{ model: Cylinder, attributes: ['id', 'serialNumber', 'size', 'gasType'] }]
        }
      ],
      order: [['saleDate', 'DESC']]
    });
    
    // Calculate totals
    const totalSales = sales.length;
    const totalAmount = sales.reduce((sum, sale) => sum + sale.totalAmount, 0);
    const totalPaid = sales.reduce((sum, sale) => sum + sale.paidAmount, 0);
    const outstanding = totalAmount - totalPaid;
    
    // Count cylinders by type
    const cylindersByType = {};
    let totalCylinders = 0;
    
    sales.forEach(sale => {
      sale.SaleItems.forEach(item => {
        totalCylinders++;
        const gasType = item.Cylinder.gasType;
        cylindersByType[gasType] = (cylindersByType[gasType] || 0) + 1;
      });
    });
    
    // Count cylinders by size
    const cylindersBySize = {};
    
    sales.forEach(sale => {
      sale.SaleItems.forEach(item => {
        const size = item.Cylinder.size;
        cylindersBySize[size] = (cylindersBySize[size] || 0) + 1;
      });
    });
    
    // Calculate returns
    const totalReturns = sales.reduce((sum, sale) => {
      return sum + sale.SaleItems.filter(item => item.returnedEmpty).length;
    }, 0);
    
    const returnRate = totalCylinders > 0 ? (totalReturns / totalCylinders) * 100 : 0;
    
    // Get cylinders currently with this customer
    const cylindersWithCustomer = await Cylinder.findAll({
      where: {
        isActive: true,
        currentCustomerId: customerId
      },
      attributes: ['id', 'serialNumber', 'size', 'gasType', 'status', 'lastFilledDate']
    });
    
    res.status(200).json({
      customer: {
        id: customer.id,
        name: customer.name,
        type: customer.type,
        currentCredit: customer.currentCredit,
        creditLimit: customer.creditLimit
      },
      startDate: reportStartDate.toISOString().split('T')[0],
      endDate: reportEndDate.toISOString().split('T')[0],
      totalSales,
      totalAmount,
      totalPaid,
      outstanding,
      totalCylinders,
      totalReturns,
      returnRate,
      cylindersByType,
      cylindersBySize,
      cylindersWithCustomer,
      sales
    });
  } catch (error) {
    console.error('Customer activity report error:', error);
    res.status(500).json({ message: 'Server error while generating customer activity report' });
  }
};

module.exports = {
  getDailySalesReport,
  getMonthlySalesReport,
  getCylinderStatistics,
  getFillingReport,
  getCustomerActivityReport
};
