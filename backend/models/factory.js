const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Factory = sequelize.define('Factory', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  location: {
    type: DataTypes.STRING,
    allowNull: false
  },
  contact_person: {
    type: DataTypes.STRING,
    field: 'contact_person',
    allowNull: true
  },
  contact_phone: {
    type: DataTypes.STRING,
    field: 'contact_phone',
    allowNull: true
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
    validate: {
      isEmail: true
    }
  },
  active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  created_at: {
    type: DataTypes.DATE,
    field: 'created_at'
  },
  updated_at: {
    type: DataTypes.DATE,
    field: 'updated_at'
  }
}, {
  tableName: 'factories', // Set explicit table name to match Drizzle schema
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  underscored: true // Use snake_case for all fields
});

module.exports = Factory;
