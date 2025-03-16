const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Cylinder = sequelize.define('Cylinder', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  serial_number: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  size: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Size of the cylinder (e.g., small, medium, large)'
  },
  type: {
    type: DataTypes.ENUM('Medical', 'Industrial'),
    allowNull: false
  },
  import_date: {
    type: DataTypes.DATE,
    allowNull: true
  },
  production_date: {
    type: DataTypes.DATE,
    allowNull: false
  },
  working_pressure: {
    type: DataTypes.FLOAT,
    allowNull: false,
    comment: 'Working pressure in bars'
  },
  design_pressure: {
    type: DataTypes.FLOAT,
    allowNull: false,
    comment: 'Design pressure in bars'
  },
  status: {
    type: DataTypes.ENUM('Empty', 'Full', 'Error', 'InMaintenance', 'InTransit'),
    defaultValue: 'Empty'
  },
  factory_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'factories',
      key: 'id'
    }
  },
  last_filled: {
    type: DataTypes.DATE,
    allowNull: true
  },
  last_inspected: {
    type: DataTypes.DATE,
    allowNull: true
  },
  qr_code: {
    type: DataTypes.STRING,
    allowNull: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  tableName: 'cylinders',
  underscored: true,
  hooks: {
    beforeCreate: (cylinder) => {
      // Generate QR code based on serial number
      cylinder.qr_code = `CYL-${cylinder.serial_number}`;
    }
  }
});

module.exports = Cylinder;
