module.exports = (sequelize, DataTypes) => {
  const Delivery = sequelize.define('Delivery', {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true
    },
    deliveryDate: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW
    },
    deliveryType: {
      type: DataTypes.ENUM('Truck', 'CustomerPickup'),
      allowNull: false
    },
    status: {
      type: DataTypes.ENUM('Pending', 'InTransit', 'Delivered', 'Cancelled'),
      defaultValue: 'Pending'
    },
    signature: {
      type: DataTypes.STRING,
      allowNull: true
    },
    receiptNumber: {
      type: DataTypes.STRING,
      allowNull: true
    },
    totalAmount: {
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

  // Associations
  Delivery.associate = function (models) {
    Delivery.belongsTo(models.Customer, { foreignKey: 'customerId' });
    Delivery.belongsTo(models.User, { foreignKey: 'deliveryPersonId' });
    Delivery.belongsTo(models.Truck, { foreignKey: 'truckId' });
    Delivery.belongsToMany(models.Cylinder, {
      through: 'DeliveryCylinders',
      foreignKey: 'deliveryId',
      otherKey: 'cylinderId'
    });
  };

  return Delivery;
};
