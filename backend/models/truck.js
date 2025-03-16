const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Truck = sequelize.define('Truck', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  licenseNumber: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  type: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Type of truck (e.g., small, medium, large)'
  },
  owner: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Owner of the truck (company or individual)'
  },
  capacity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: 'Maximum number of cylinders the truck can carry'
  },
  driver: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: 'Name of the driver'
  },
  driverContact: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: 'Contact number of the driver'
  },
  status: {
    type: DataTypes.ENUM('Available', 'InTransit', 'Maintenance', 'OutOfService'),
    defaultValue: 'Available'
  },
  lastMaintenance: {
    type: DataTypes.DATE,
    allowNull: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
});

module.exports = Truck;
