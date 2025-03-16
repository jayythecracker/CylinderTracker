const { sequelize, Sequelize } = require('../config/db');
const Factory = require('./factory');

const Cylinder = sequelize.define('Cylinder', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  serialNumber: {
    type: Sequelize.STRING,
    allowNull: false,
    unique: true
  },
  qrCode: {
    type: Sequelize.STRING,
    allowNull: false,
    unique: true
  },
  size: {
    type: Sequelize.STRING,
    allowNull: false
  },
  importDate: {
    type: Sequelize.DATEONLY,
    allowNull: true
  },
  productionDate: {
    type: Sequelize.DATEONLY,
    allowNull: false
  },
  originalNumber: {
    type: Sequelize.STRING,
    allowNull: true
  },
  workingPressure: {
    type: Sequelize.FLOAT,
    allowNull: false
  },
  designPressure: {
    type: Sequelize.FLOAT,
    allowNull: false
  },
  gasType: {
    type: Sequelize.ENUM('Medical', 'Industrial'),
    allowNull: false
  },
  status: {
    type: Sequelize.ENUM('Empty', 'Full', 'In Filling', 'In Inspection', 'Error', 'In Delivery', 'Maintenance'),
    defaultValue: 'Empty'
  },
  lastFilledDate: {
    type: Sequelize.DATE,
    allowNull: true
  },
  lastInspectionDate: {
    type: Sequelize.DATE,
    allowNull: true
  },
  factoryId: {
    type: Sequelize.INTEGER,
    references: {
      model: Factory,
      key: 'id'
    }
  },
  currentCustomerId: {
    type: Sequelize.INTEGER,
    allowNull: true
  },
  isActive: {
    type: Sequelize.BOOLEAN,
    defaultValue: true
  }
}, {
  timestamps: true
});

// Establish relationship with Factory
Cylinder.belongsTo(Factory, { foreignKey: 'factoryId' });
Factory.hasMany(Cylinder, { foreignKey: 'factoryId' });

module.exports = Cylinder;
