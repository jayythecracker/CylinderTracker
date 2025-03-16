const { sequelize, Sequelize } = require('../config/db');

const Truck = sequelize.define('Truck', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  licenseNumber: {
    type: Sequelize.STRING,
    allowNull: false,
    unique: true
  },
  type: {
    type: Sequelize.STRING,
    allowNull: false
  },
  owner: {
    type: Sequelize.STRING,
    allowNull: false
  },
  capacity: {
    type: Sequelize.INTEGER,
    allowNull: false
  },
  status: {
    type: Sequelize.ENUM('Available', 'On Delivery', 'Maintenance'),
    defaultValue: 'Available'
  },
  driverName: {
    type: Sequelize.STRING,
    allowNull: true
  },
  driverContact: {
    type: Sequelize.STRING,
    allowNull: true
  },
  isActive: {
    type: Sequelize.BOOLEAN,
    defaultValue: true
  }
}, {
  timestamps: true
});

module.exports = Truck;
