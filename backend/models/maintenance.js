module.exports = (sequelize, DataTypes) => {
  const Maintenance = sequelize.define('Maintenance', {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true
    },
    maintenanceDate: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW
    },
    issueDescription: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    actionTaken: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    status: {
      type: DataTypes.ENUM('Pending', 'InProgress', 'Completed', 'Unrepairable'),
      defaultValue: 'Pending'
    },
    cost: {
      type: DataTypes.FLOAT,
      allowNull: true
    },
    completionDate: {
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

  // Associations
  Maintenance.associate = function (models) {
    Maintenance.belongsTo(models.Cylinder, { foreignKey: 'cylinderId' });
    Maintenance.belongsTo(models.User, { foreignKey: 'technicianId' });
  };

  return Maintenance;
};
