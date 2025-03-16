const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
// Relationships will be defined in index.js

const FILLING_LINE_STATUS = {
  IDLE: 'idle',
  ACTIVE: 'active',
  MAINTENANCE: 'maintenance'
};

const FillingLine = sequelize.define('FillingLine', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  capacity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 10,
    comment: 'Number of cylinders that can be filled simultaneously'
  },
  status: {
    type: DataTypes.ENUM,
    values: Object.values(FILLING_LINE_STATUS),
    allowNull: false,
    defaultValue: FILLING_LINE_STATUS.IDLE
  },
  cylinderType: {
    type: DataTypes.ENUM,
    values: ['medical', 'industrial'],
    allowNull: false,
    comment: 'Type of cylinders this line can fill'
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

// FillingSession model to track filling operations
const FillingSession = sequelize.define('FillingSession', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  startTime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  endTime: {
    type: DataTypes.DATE,
    allowNull: true
  },
  fillingLineId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'FillingLines',
      key: 'id'
    },
    allowNull: false
  },
  startedById: {
    type: DataTypes.INTEGER,
    references: {
      model: 'Users',
      key: 'id'
    },
    allowNull: false
  },
  endedById: {
    type: DataTypes.INTEGER,
    references: {
      model: 'Users',
      key: 'id'
    },
    allowNull: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  timestamps: true
});

// FillingSessionCylinder to track cylinders in a filling session
const FillingSessionCylinder = sequelize.define('FillingSessionCylinder', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  fillingSessionId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'FillingSessions',
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
  status: {
    type: DataTypes.ENUM,
    values: ['pending', 'filling', 'success', 'failed'],
    allowNull: false,
    defaultValue: 'pending'
  },
  filledAt: {
    type: DataTypes.DATE,
    allowNull: true
  },
  pressureBeforeFilling: {
    type: DataTypes.FLOAT,
    allowNull: true
  },
  pressureAfterFilling: {
    type: DataTypes.FLOAT,
    allowNull: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  timestamps: true
});

// Define relationships
FillingLine.hasMany(FillingSession, { foreignKey: 'fillingLineId', as: 'sessions' });
FillingSession.belongsTo(FillingLine, { foreignKey: 'fillingLineId', as: 'fillingLine' });

FillingSession.belongsTo(User, { foreignKey: 'startedById', as: 'startedBy' });
FillingSession.belongsTo(User, { foreignKey: 'endedById', as: 'endedBy' });

FillingSession.hasMany(FillingSessionCylinder, { foreignKey: 'fillingSessionId', as: 'cylinders' });
FillingSessionCylinder.belongsTo(FillingSession, { foreignKey: 'fillingSessionId', as: 'session' });

FillingSessionCylinder.belongsTo(Cylinder, { foreignKey: 'cylinderId', as: 'cylinder' });
Cylinder.hasMany(FillingSessionCylinder, { foreignKey: 'cylinderId', as: 'fillingHistory' });

module.exports = {
  FillingLine,
  FillingSession,
  FillingSessionCylinder,
  FILLING_LINE_STATUS
};
