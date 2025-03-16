const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
// Import will be done in index.js

const CYLINDER_STATUSES = {
  EMPTY: 'empty',
  FILLED: 'filled',
  INSPECTION: 'inspection',
  ERROR: 'error',
  MAINTENANCE: 'maintenance'
};

const CYLINDER_TYPES = {
  MEDICAL: 'medical',
  INDUSTRIAL: 'industrial'
};

const Cylinder = sequelize.define('Cylinder', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  serialNumber: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  size: {
    type: DataTypes.FLOAT,
    allowNull: false,
    comment: 'Size in liters'
  },
  importDate: {
    type: DataTypes.DATEONLY,
    allowNull: true
  },
  productionDate: {
    type: DataTypes.DATEONLY,
    allowNull: true
  },
  originalNumber: {
    type: DataTypes.STRING,
    allowNull: true
  },
  workingPressure: {
    type: DataTypes.FLOAT,
    allowNull: false,
    comment: 'Pressure in MPa'
  },
  designPressure: {
    type: DataTypes.FLOAT,
    allowNull: false,
    comment: 'Pressure in MPa'
  },
  type: {
    type: DataTypes.ENUM,
    values: Object.values(CYLINDER_TYPES),
    allowNull: false,
    defaultValue: CYLINDER_TYPES.INDUSTRIAL
  },
  status: {
    type: DataTypes.ENUM,
    values: Object.values(CYLINDER_STATUSES),
    allowNull: false,
    defaultValue: CYLINDER_STATUSES.EMPTY
  },
  lastFilled: {
    type: DataTypes.DATE,
    allowNull: true
  },
  lastInspected: {
    type: DataTypes.DATE,
    allowNull: true
  },
  factoryId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'Factories',
      key: 'id'
    },
    allowNull: false
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  qrCode: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true
  }
}, {
  timestamps: true
});

// Relationships will be defined in index.js

module.exports = (sequelize, DataTypes) => {
  // Add constants to the model for access elsewhere
  Cylinder.CYLINDER_STATUSES = CYLINDER_STATUSES;
  Cylinder.CYLINDER_TYPES = CYLINDER_TYPES;
  return Cylinder;
};
