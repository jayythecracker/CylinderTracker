const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const TRUCK_STATUS = {
  AVAILABLE: 'available',
  IN_DELIVERY: 'in_delivery',
  MAINTENANCE: 'maintenance'
};

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
    allowNull: false
  },
  owner: {
    type: DataTypes.STRING,
    allowNull: false
  },
  capacity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: 'Number of cylinders the truck can carry'
  },
  status: {
    type: DataTypes.ENUM,
    values: Object.values(TRUCK_STATUS),
    allowNull: false,
    defaultValue: TRUCK_STATUS.AVAILABLE
  },
  lastMaintenanceDate: {
    type: DataTypes.DATEONLY,
    allowNull: true
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  timestamps: true
});

// DeliveryTrip model to track deliveries
const DeliveryTrip = sequelize.define('DeliveryTrip', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  truckId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'Trucks',
      key: 'id'
    },
    allowNull: false
  },
  driverId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'Users',
      key: 'id'
    },
    allowNull: false
  },
  departureTime: {
    type: DataTypes.DATE,
    allowNull: false
  },
  returnTime: {
    type: DataTypes.DATE,
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM,
    values: ['planned', 'in_progress', 'completed', 'cancelled'],
    allowNull: false,
    defaultValue: 'planned'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  timestamps: true
});

module.exports = {
  Truck,
  DeliveryTrip,
  TRUCK_STATUS
};
