const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Inspection = sequelize.define('Inspection', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  cylinderId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Cylinders',
      key: 'id'
    }
  },
  inspectedById: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id'
    }
  },
  inspectionDate: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  pressureCheck: {
    type: DataTypes.FLOAT,
    allowNull: false,
    comment: 'Measured pressure in bars'
  },
  visualCheck: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    comment: 'Result of visual inspection'
  },
  valveCheck: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    comment: 'Result of valve inspection'
  },
  result: {
    type: DataTypes.ENUM('Approved', 'Rejected'),
    allowNull: false
  },
  rejectionReason: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Reason for rejection if applicable'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  hooks: {
    afterCreate: async (inspection) => {
      // Update cylinder status and lastInspected date based on inspection result
      const Cylinder = require('./cylinder');
      if (inspection.result === 'Approved') {
        await Cylinder.update(
          { lastInspected: inspection.inspectionDate },
          { where: { id: inspection.cylinderId } }
        );
      } else if (inspection.result === 'Rejected') {
        await Cylinder.update(
          { 
            status: 'Error',
            lastInspected: inspection.inspectionDate
          },
          { where: { id: inspection.cylinderId } }
        );
      }
    }
  }
});

module.exports = Inspection;
