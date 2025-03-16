const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Filling = sequelize.define('Filling', {
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
  startedById: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id'
    }
  },
  endedById: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'Users',
      key: 'id'
    }
  },
  lineNumber: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: 'Filling line number'
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
  initialPressure: {
    type: DataTypes.FLOAT,
    allowNull: false,
    comment: 'Initial pressure in bars'
  },
  finalPressure: {
    type: DataTypes.FLOAT,
    allowNull: true,
    comment: 'Final pressure in bars'
  },
  targetPressure: {
    type: DataTypes.FLOAT,
    allowNull: false,
    comment: 'Target pressure in bars'
  },
  gasType: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Type of gas filled'
  },
  status: {
    type: DataTypes.ENUM('InProgress', 'Completed', 'Failed'),
    defaultValue: 'InProgress'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  hooks: {
    afterUpdate: async (filling) => {
      // Update cylinder status based on filling status
      if (filling.status === 'Completed') {
        const Cylinder = require('./cylinder');
        await Cylinder.update(
          { 
            status: 'Full',
            lastFilled: filling.endTime
          },
          { where: { id: filling.cylinderId } }
        );
      } else if (filling.status === 'Failed') {
        const Cylinder = require('./cylinder');
        await Cylinder.update(
          { status: 'Error' },
          { where: { id: filling.cylinderId } }
        );
      }
    }
  }
});

module.exports = Filling;
