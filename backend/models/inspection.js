const { sequelize, Sequelize } = require('../config/db');
const User = require('./user');
const Cylinder = require('./cylinder');

const Inspection = sequelize.define('Inspection', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  inspectionDate: {
    type: Sequelize.DATE,
    allowNull: false,
    defaultValue: Sequelize.NOW
  },
  cylinderId: {
    type: Sequelize.INTEGER,
    references: {
      model: Cylinder,
      key: 'id'
    }
  },
  inspectedById: {
    type: Sequelize.INTEGER,
    references: {
      model: User,
      key: 'id'
    }
  },
  pressureReading: {
    type: Sequelize.FLOAT,
    allowNull: false
  },
  visualInspection: {
    type: Sequelize.BOOLEAN,
    defaultValue: true
  },
  result: {
    type: Sequelize.ENUM('Approved', 'Rejected'),
    allowNull: false
  },
  notes: {
    type: Sequelize.TEXT,
    allowNull: true
  }
}, {
  timestamps: true
});

// Relationships
Cylinder.hasMany(Inspection, { foreignKey: 'cylinderId' });
Inspection.belongsTo(Cylinder, { foreignKey: 'cylinderId' });

User.hasMany(Inspection, { foreignKey: 'inspectedById' });
Inspection.belongsTo(User, { foreignKey: 'inspectedById', as: 'InspectedBy' });

module.exports = Inspection;
