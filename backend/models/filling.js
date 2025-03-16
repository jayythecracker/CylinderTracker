const { sequelize, Sequelize } = require('../config/db');
const User = require('./user');
const Cylinder = require('./cylinder');

const FillingLine = sequelize.define('FillingLine', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: Sequelize.STRING,
    allowNull: false
  },
  capacity: {
    type: Sequelize.INTEGER,
    allowNull: false,
    defaultValue: 10
  },
  gasType: {
    type: Sequelize.ENUM('Medical', 'Industrial'),
    allowNull: false
  },
  status: {
    type: Sequelize.ENUM('Idle', 'Active', 'Maintenance'),
    defaultValue: 'Idle'
  },
  isActive: {
    type: Sequelize.BOOLEAN,
    defaultValue: true
  }
}, {
  timestamps: true
});

const FillingBatch = sequelize.define('FillingBatch', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  batchNumber: {
    type: Sequelize.STRING,
    allowNull: false,
    unique: true
  },
  startTime: {
    type: Sequelize.DATE,
    allowNull: false,
    defaultValue: Sequelize.NOW
  },
  endTime: {
    type: Sequelize.DATE,
    allowNull: true
  },
  status: {
    type: Sequelize.ENUM('In Progress', 'Completed', 'Failed'),
    defaultValue: 'In Progress'
  },
  fillingLineId: {
    type: Sequelize.INTEGER,
    references: {
      model: FillingLine,
      key: 'id'
    }
  },
  startedById: {
    type: Sequelize.INTEGER,
    references: {
      model: User,
      key: 'id'
    }
  },
  endedById: {
    type: Sequelize.INTEGER,
    allowNull: true,
    references: {
      model: User,
      key: 'id'
    }
  },
  notes: {
    type: Sequelize.TEXT,
    allowNull: true
  }
}, {
  timestamps: true
});

const FillingDetail = sequelize.define('FillingDetail', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  fillingBatchId: {
    type: Sequelize.INTEGER,
    references: {
      model: FillingBatch,
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
  initialPressure: {
    type: Sequelize.FLOAT,
    allowNull: false,
    defaultValue: 0
  },
  finalPressure: {
    type: Sequelize.FLOAT,
    allowNull: true
  },
  status: {
    type: Sequelize.ENUM('Pending', 'In Progress', 'Success', 'Failed'),
    defaultValue: 'Pending'
  },
  notes: {
    type: Sequelize.TEXT,
    allowNull: true
  }
}, {
  timestamps: true
});

// Relationships
FillingLine.hasMany(FillingBatch, { foreignKey: 'fillingLineId' });
FillingBatch.belongsTo(FillingLine, { foreignKey: 'fillingLineId' });

User.hasMany(FillingBatch, { foreignKey: 'startedById', as: 'StartedBatches' });
FillingBatch.belongsTo(User, { foreignKey: 'startedById', as: 'StartedBy' });

User.hasMany(FillingBatch, { foreignKey: 'endedById', as: 'EndedBatches' });
FillingBatch.belongsTo(User, { foreignKey: 'endedById', as: 'EndedBy' });

FillingBatch.hasMany(FillingDetail, { foreignKey: 'fillingBatchId' });
FillingDetail.belongsTo(FillingBatch, { foreignKey: 'fillingBatchId' });

Cylinder.hasMany(FillingDetail, { foreignKey: 'cylinderId' });
FillingDetail.belongsTo(Cylinder, { foreignKey: 'cylinderId' });

module.exports = {
  FillingLine,
  FillingBatch,
  FillingDetail
};
