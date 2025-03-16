const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Sale = sequelize.define('Sale', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  customerId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Customers',
      key: 'id'
    }
  },
  sellerId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id'
    }
  },
  saleDate: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  deliveryMethod: {
    type: DataTypes.ENUM('Pickup', 'Delivery'),
    allowNull: false
  },
  truckId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'Trucks',
      key: 'id'
    },
    comment: 'Truck ID if delivery method is Delivery'
  },
  totalAmount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false
  },
  paymentStatus: {
    type: DataTypes.ENUM('Paid', 'Pending', 'Partial'),
    defaultValue: 'Pending'
  },
  paidAmount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    defaultValue: 0.00
  },
  deliveryStatus: {
    type: DataTypes.ENUM('Pending', 'InTransit', 'Delivered', 'Cancelled'),
    defaultValue: 'Pending'
  },
  deliveryDate: {
    type: DataTypes.DATE,
    allowNull: true
  },
  signatureImage: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Base64 encoded signature image'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
});

module.exports = Sale;
