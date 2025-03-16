const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Customer = sequelize.define('Customer', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  type: {
    type: DataTypes.ENUM('Hospital', 'Individual', 'Shop', 'Factory', 'Workshop'),
    allowNull: false
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  contact: {
    type: DataTypes.STRING,
    allowNull: false
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
    validate: {
      isEmail: true
    }
  },
  paymentType: {
    type: DataTypes.ENUM('Cash', 'Credit'),
    defaultValue: 'Cash'
  },
  priceGroup: {
    type: DataTypes.STRING,
    defaultValue: 'Standard',
    comment: 'Price category for this customer'
  },
  creditLimit: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
    comment: 'Maximum credit amount for credit customers'
  },
  balance: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
    comment: 'Current balance for credit customers'
  },
  active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
});

module.exports = Customer;
