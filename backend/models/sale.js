const { sequelize, Sequelize } = require('../config/db');
const User = require('./user');
const Customer = require('./customer');
const Cylinder = require('./cylinder');
const Truck = require('./truck');

const Sale = sequelize.define('Sale', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  invoiceNumber: {
    type: Sequelize.STRING,
    allowNull: false,
    unique: true
  },
  saleDate: {
    type: Sequelize.DATE,
    allowNull: false,
    defaultValue: Sequelize.NOW
  },
  customerId: {
    type: Sequelize.INTEGER,
    references: {
      model: Customer,
      key: 'id'
    }
  },
  sellerId: {
    type: Sequelize.INTEGER,
    references: {
      model: User,
      key: 'id'
    }
  },
  deliveryType: {
    type: Sequelize.ENUM('Truck Delivery', 'Customer Pickup'),
    allowNull: false
  },
  truckId: {
    type: Sequelize.INTEGER,
    allowNull: true,
    references: {
      model: Truck,
      key: 'id'
    }
  },
  status: {
    type: Sequelize.ENUM('Pending', 'In Progress', 'Delivered', 'Completed', 'Cancelled'),
    defaultValue: 'Pending'
  },
  totalAmount: {
    type: Sequelize.FLOAT,
    allowNull: false
  },
  paidAmount: {
    type: Sequelize.FLOAT,
    allowNull: false,
    defaultValue: 0
  },
  paymentStatus: {
    type: Sequelize.ENUM('Unpaid', 'Partial', 'Paid'),
    defaultValue: 'Unpaid'
  },
  paymentMethod: {
    type: Sequelize.ENUM('Cash', 'Credit'),
    defaultValue: 'Cash'
  },
  notes: {
    type: Sequelize.TEXT,
    allowNull: true
  },
  deliveryAddress: {
    type: Sequelize.TEXT,
    allowNull: true
  },
  customerSignature: {
    type: Sequelize.TEXT,
    allowNull: true
  },
  deliveryDate: {
    type: Sequelize.DATE,
    allowNull: true
  }
}, {
  timestamps: true
});

const SaleItem = sequelize.define('SaleItem', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  saleId: {
    type: Sequelize.INTEGER,
    references: {
      model: Sale,
      key: 'id'
    }
  },
  cylinderId: {
    type: Sequelize.INTEGER,
    references: {
      model: Cylinder,
      key: 'id'
    }
  },
  price: {
    type: Sequelize.FLOAT,
    allowNull: false
  },
  returnedEmpty: {
    type: Sequelize.BOOLEAN,
    defaultValue: false
  },
  returnDate: {
    type: Sequelize.DATE,
    allowNull: true
  }
}, {
  timestamps: true
});

// Relationships
Customer.hasMany(Sale, { foreignKey: 'customerId' });
Sale.belongsTo(Customer, { foreignKey: 'customerId' });

User.hasMany(Sale, { foreignKey: 'sellerId' });
Sale.belongsTo(User, { foreignKey: 'sellerId', as: 'Seller' });

Truck.hasMany(Sale, { foreignKey: 'truckId' });
Sale.belongsTo(Truck, { foreignKey: 'truckId' });

Sale.hasMany(SaleItem, { foreignKey: 'saleId' });
SaleItem.belongsTo(Sale, { foreignKey: 'saleId' });

Cylinder.hasMany(SaleItem, { foreignKey: 'cylinderId' });
SaleItem.belongsTo(Cylinder, { foreignKey: 'cylinderId' });

module.exports = { Sale, SaleItem };
