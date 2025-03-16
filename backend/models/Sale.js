const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const { Customer } = require('./Customer');
const { User } = require('./User');
const { Cylinder } = require('./Cylinder');
const { DeliveryTrip } = require('./Truck');

const SALE_STATUS = {
  PENDING: 'pending',
  PROCESSING: 'processing',
  DELIVERED: 'delivered',
  PICKED_UP: 'picked_up',
  CANCELLED: 'cancelled'
};

const DELIVERY_TYPE = {
  DELIVERY: 'delivery',
  PICKUP: 'pickup'
};

const Sale = sequelize.define('Sale', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  invoiceNumber: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  customerId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'Customers',
      key: 'id'
    },
    allowNull: false
  },
  sellerId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'Users',
      key: 'id'
    },
    allowNull: false
  },
  saleDate: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  totalAmount: {
    type: DataTypes.FLOAT,
    allowNull: false
  },
  paidAmount: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 0
  },
  deliveryType: {
    type: DataTypes.ENUM,
    values: Object.values(DELIVERY_TYPE),
    allowNull: false
  },
  deliveryTripId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'DeliveryTrips',
      key: 'id'
    },
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM,
    values: Object.values(SALE_STATUS),
    allowNull: false,
    defaultValue: SALE_STATUS.PENDING
  },
  customerSignature: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  deliveryDate: {
    type: DataTypes.DATE,
    allowNull: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  timestamps: true
});

// SaleItem model to track individual cylinders in a sale
const SaleItem = sequelize.define('SaleItem', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  saleId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'Sales',
      key: 'id'
    },
    allowNull: false
  },
  cylinderId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'Cylinders',
      key: 'id'
    },
    allowNull: false
  },
  price: {
    type: DataTypes.FLOAT,
    allowNull: false
  },
  isReturn: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    comment: 'Indicates if this is a returned empty cylinder'
  },
  status: {
    type: DataTypes.ENUM,
    values: ['pending', 'delivered', 'returned'],
    allowNull: false,
    defaultValue: 'pending'
  }
}, {
  timestamps: true
});

// Define relationships
Sale.belongsTo(Customer, { foreignKey: 'customerId', as: 'customer' });
Customer.hasMany(Sale, { foreignKey: 'customerId', as: 'sales' });

Sale.belongsTo(User, { foreignKey: 'sellerId', as: 'seller' });
User.hasMany(Sale, { foreignKey: 'sellerId', as: 'sales' });

Sale.belongsTo(DeliveryTrip, { foreignKey: 'deliveryTripId', as: 'deliveryTrip' });
DeliveryTrip.hasMany(Sale, { foreignKey: 'deliveryTripId', as: 'sales' });

Sale.hasMany(SaleItem, { foreignKey: 'saleId', as: 'items' });
SaleItem.belongsTo(Sale, { foreignKey: 'saleId', as: 'sale' });

SaleItem.belongsTo(Cylinder, { foreignKey: 'cylinderId', as: 'cylinder' });
Cylinder.hasMany(SaleItem, { foreignKey: 'cylinderId', as: 'saleHistory' });

module.exports = {
  Sale,
  SaleItem,
  SALE_STATUS,
  DELIVERY_TYPE
};
