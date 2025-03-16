const { sequelize, Sequelize } = require('../config/db');

const Customer = sequelize.define('Customer', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: Sequelize.STRING,
    allowNull: false
  },
  type: {
    type: Sequelize.ENUM('Hospital', 'Individual', 'Shop', 'Factory', 'Workshop'),
    allowNull: false
  },
  address: {
    type: Sequelize.TEXT,
    allowNull: false
  },
  contactPerson: {
    type: Sequelize.STRING,
    allowNull: true
  },
  contactNumber: {
    type: Sequelize.STRING,
    allowNull: false
  },
  email: {
    type: Sequelize.STRING,
    allowNull: true,
    validate: {
      isEmail: true
    }
  },
  paymentType: {
    type: Sequelize.ENUM('Cash', 'Credit'),
    defaultValue: 'Cash'
  },
  priceGroup: {
    type: Sequelize.STRING,
    allowNull: true
  },
  creditLimit: {
    type: Sequelize.FLOAT,
    defaultValue: 0
  },
  currentCredit: {
    type: Sequelize.FLOAT,
    defaultValue: 0
  },
  isActive: {
    type: Sequelize.BOOLEAN,
    defaultValue: true
  }
}, {
  timestamps: true
});

module.exports = Customer;
