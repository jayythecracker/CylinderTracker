const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const CUSTOMER_TYPES = {
  HOSPITAL: 'hospital',
  INDIVIDUAL: 'individual',
  SHOP: 'shop',
  FACTORY: 'factory',
  WORKSHOP: 'workshop'
};

const PAYMENT_TYPES = {
  CASH: 'cash',
  CREDIT: 'credit'
};

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
    type: DataTypes.ENUM,
    values: Object.values(CUSTOMER_TYPES),
    allowNull: false
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  contact: {
    type: DataTypes.STRING,
    allowNull: true
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
    validate: {
      isEmail: true
    }
  },
  paymentType: {
    type: DataTypes.ENUM,
    values: Object.values(PAYMENT_TYPES),
    allowNull: false,
    defaultValue: PAYMENT_TYPES.CASH
  },
  priceGroup: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: 'Price group classification for customers'
  },
  creditLimit: {
    type: DataTypes.FLOAT,
    allowNull: true,
    defaultValue: 0
  },
  balance: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 0
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  timestamps: true
});

module.exports = {
  Customer,
  CUSTOMER_TYPES,
  PAYMENT_TYPES
};
