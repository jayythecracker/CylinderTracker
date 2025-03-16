const Sequelize = require('sequelize');
const sequelize = require('../config/database');

// Import models
const User = require('./user');
const Factory = require('./factory');
const Cylinder = require('./cylinder');
const Customer = require('./customer');
const Filling = require('./filling');
const Inspection = require('./inspection');
const Truck = require('./truck');
const Sale = require('./sale');

// Define associations

// Factory and Cylinder (Factory has many Cylinders)
Factory.hasMany(Cylinder, { foreignKey: 'factoryId', as: 'cylinders' });
Cylinder.belongsTo(Factory, { foreignKey: 'factoryId', as: 'factory' });

// User and Filling (User starts and ends filling processes)
User.hasMany(Filling, { foreignKey: 'startedById', as: 'startedFillings' });
Filling.belongsTo(User, { foreignKey: 'startedById', as: 'startedBy' });
User.hasMany(Filling, { foreignKey: 'endedById', as: 'endedFillings' });
Filling.belongsTo(User, { foreignKey: 'endedById', as: 'endedBy' });

// Cylinder and Filling
Cylinder.hasMany(Filling, { foreignKey: 'cylinderId', as: 'fillings' });
Filling.belongsTo(Cylinder, { foreignKey: 'cylinderId', as: 'cylinder' });

// User and Inspection
User.hasMany(Inspection, { foreignKey: 'inspectedById', as: 'inspections' });
Inspection.belongsTo(User, { foreignKey: 'inspectedById', as: 'inspectedBy' });

// Cylinder and Inspection
Cylinder.hasMany(Inspection, { foreignKey: 'cylinderId', as: 'inspections' });
Inspection.belongsTo(Cylinder, { foreignKey: 'cylinderId', as: 'cylinder' });

// Customer and Sale
Customer.hasMany(Sale, { foreignKey: 'customerId', as: 'sales' });
Sale.belongsTo(Customer, { foreignKey: 'customerId', as: 'customer' });

// User and Sale
User.hasMany(Sale, { foreignKey: 'sellerId', as: 'sales' });
Sale.belongsTo(User, { foreignKey: 'sellerId', as: 'seller' });

// Truck and Sale
Truck.hasMany(Sale, { foreignKey: 'truckId', as: 'sales' });
Sale.belongsTo(Truck, { foreignKey: 'truckId', as: 'truck' });

// Cylinder and Sale through SaleCylinder join table
const SaleCylinder = sequelize.define('SaleCylinder', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  quantity: {
    type: Sequelize.INTEGER,
    allowNull: false,
    defaultValue: 1
  }
});

Sale.belongsToMany(Cylinder, { through: SaleCylinder, as: 'cylinders' });
Cylinder.belongsToMany(Sale, { through: SaleCylinder, as: 'sales' });

// Export models and sequelize
module.exports = {
  sequelize,
  Sequelize,
  User,
  Factory,
  Cylinder,
  Customer,
  Filling,
  Inspection,
  Truck,
  Sale,
  SaleCylinder
};
