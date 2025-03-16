import { pgTable, serial, varchar, timestamp, text, integer, boolean, numeric, date, pgEnum, json, jsonb, foreignKey } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { relations } from 'drizzle-orm';

// Enums
export const userRoleEnum = pgEnum('user_role', ['admin', 'manager', 'filler', 'inspector', 'seller', 'viewer']);
export const cylinderStatusEnum = pgEnum('cylinder_status', ['Empty', 'Full', 'InTransit', 'AtCustomer', 'Error', 'Scrapped']);
export const paymentTypeEnum = pgEnum('payment_type', ['Cash', 'Credit']);
export const customerTypeEnum = pgEnum('customer_type', ['Hospital', 'Factory', 'Shop', 'Workshop', 'Individual']);
export const inspectionResultEnum = pgEnum('inspection_result', ['Approved', 'Rejected']);
export const saleStatusEnum = pgEnum('sale_status', ['Pending', 'Delivered', 'Completed', 'Cancelled']);
export const paymentStatusEnum = pgEnum('payment_status', ['Unpaid', 'Partially Paid', 'Paid']);
export const deliveryTypeEnum = pgEnum('delivery_type', ['Pickup', 'Delivery']);

// Users table
export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 100 }).notNull(),
  username: varchar('username', { length: 50 }).notNull().unique(),
  password: varchar('password', { length: 100 }).notNull(),
  role: userRoleEnum('role').notNull().default('viewer'),
  email: varchar('email', { length: 100 }),
  phone: varchar('phone', { length: 20 }),
  active: boolean('active').notNull().default(true),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// User relations
export const usersRelations = relations(users, ({ many }) => ({
  inspections: many(inspections),
  fillingOperations: many(fillingOperations),
  sales: many(sales),
}));

// Customers table
export const customers = pgTable('customers', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 100 }).notNull(),
  type: customerTypeEnum('type').notNull(),
  contactPerson: varchar('contact_person', { length: 100 }),
  contactNumber: varchar('contact_number', { length: 20 }),
  email: varchar('email', { length: 100 }),
  address: text('address'),
  paymentType: paymentTypeEnum('payment_type').notNull().default('Cash'),
  creditLimit: numeric('credit_limit', { precision: 10, scale: 2 }).default('0'),
  currentCredit: numeric('current_credit', { precision: 10, scale: 2 }).default('0'),
  notes: text('notes'),
  active: boolean('active').notNull().default(true),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Customer relations
export const customersRelations = relations(customers, ({ many }) => ({
  cylinders: many(cylinders),
  sales: many(sales),
}));

// Cylinders table
export const cylinders = pgTable('cylinders', {
  id: serial('id').primaryKey(),
  serialNumber: varchar('serial_number', { length: 50 }).notNull().unique(),
  gasType: varchar('gas_type', { length: 50 }).notNull(),
  size: varchar('size', { length: 20 }).notNull(),
  manufacturer: varchar('manufacturer', { length: 100 }),
  manufactureDate: date('manufacture_date'),
  lastInspectionDate: date('last_inspection_date'),
  nextInspectionDate: date('next_inspection_date'),
  status: cylinderStatusEnum('status').notNull().default('Empty'),
  workingPressure: numeric('working_pressure', { precision: 10, scale: 2 }),
  testPressure: numeric('test_pressure', { precision: 10, scale: 2 }),
  waterCapacity: numeric('water_capacity', { precision: 10, scale: 2 }),
  emptyWeight: numeric('empty_weight', { precision: 10, scale: 2 }),
  valveType: varchar('valve_type', { length: 50 }),
  currentLocation: varchar('current_location', { length: 100 }).default('Factory'),
  currentCustomerId: integer('current_customer_id').references(() => customers.id),
  qrCode: varchar('qr_code', { length: 200 }),
  notes: text('notes'),
  active: boolean('active').notNull().default(true),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Cylinder relations
export const cylindersRelations = relations(cylinders, ({ one, many }) => ({
  currentCustomer: one(customers, {
    fields: [cylinders.currentCustomerId],
    references: [customers.id],
  }),
  inspections: many(inspections),
  fillingOperations: many(fillingOperations),
  saleItems: many(saleItems),
}));

// Inspections table
export const inspections = pgTable('inspections', {
  id: serial('id').primaryKey(),
  cylinderId: integer('cylinder_id').notNull().references(() => cylinders.id),
  inspectionDate: timestamp('inspection_date').notNull().defaultNow(),
  inspectedById: integer('inspected_by_id').notNull().references(() => users.id),
  visualInspection: boolean('visual_inspection').notNull(),
  pressureReading: numeric('pressure_reading', { precision: 10, scale: 2 }),
  result: inspectionResultEnum('result').notNull(),
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Inspection relations
export const inspectionsRelations = relations(inspections, ({ one }) => ({
  cylinder: one(cylinders, {
    fields: [inspections.cylinderId],
    references: [cylinders.id],
  }),
  inspectedBy: one(users, {
    fields: [inspections.inspectedById],
    references: [users.id],
  }),
}));

// Filling Operations table
export const fillingOperations = pgTable('filling_operations', {
  id: serial('id').primaryKey(),
  cylinderId: integer('cylinder_id').notNull().references(() => cylinders.id),
  fillingDate: timestamp('filling_date').notNull().defaultNow(),
  filledById: integer('filled_by_id').notNull().references(() => users.id),
  pressureBefore: numeric('pressure_before', { precision: 10, scale: 2 }),
  pressureAfter: numeric('pressure_after', { precision: 10, scale: 2 }),
  gasWeight: numeric('gas_weight', { precision: 10, scale: 2 }),
  batchNumber: varchar('batch_number', { length: 50 }),
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Filling Operations relations
export const fillingOperationsRelations = relations(fillingOperations, ({ one }) => ({
  cylinder: one(cylinders, {
    fields: [fillingOperations.cylinderId],
    references: [cylinders.id],
  }),
  filledBy: one(users, {
    fields: [fillingOperations.filledById],
    references: [users.id],
  }),
}));

// Sales table
export const sales = pgTable('sales', {
  id: serial('id').primaryKey(),
  invoiceNumber: varchar('invoice_number', { length: 50 }).notNull().unique(),
  customerId: integer('customer_id').notNull().references(() => customers.id),
  saleDate: timestamp('sale_date').notNull().defaultNow(),
  soldById: integer('sold_by_id').notNull().references(() => users.id),
  status: saleStatusEnum('status').notNull().default('Pending'),
  deliveryType: deliveryTypeEnum('delivery_type').notNull().default('Pickup'),
  paymentStatus: paymentStatusEnum('payment_status').notNull().default('Unpaid'),
  subtotalAmount: numeric('subtotal_amount', { precision: 10, scale: 2 }).notNull(),
  taxAmount: numeric('tax_amount', { precision: 10, scale: 2 }).default('0'),
  discountAmount: numeric('discount_amount', { precision: 10, scale: 2 }).default('0'),
  totalAmount: numeric('total_amount', { precision: 10, scale: 2 }).notNull(),
  paidAmount: numeric('paid_amount', { precision: 10, scale: 2 }).default('0'),
  notes: text('notes'),
  deliveryAddress: text('delivery_address'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Sales relations
export const salesRelations = relations(sales, ({ one, many }) => ({
  customer: one(customers, {
    fields: [sales.customerId],
    references: [customers.id],
  }),
  soldBy: one(users, {
    fields: [sales.soldById],
    references: [users.id],
  }),
  saleItems: many(saleItems),
  payments: many(payments),
}));

// Sale Items table
export const saleItems = pgTable('sale_items', {
  id: serial('id').primaryKey(),
  saleId: integer('sale_id').notNull().references(() => sales.id),
  cylinderId: integer('cylinder_id').notNull().references(() => cylinders.id),
  gasType: varchar('gas_type', { length: 50 }).notNull(),
  cylinderSize: varchar('cylinder_size', { length: 20 }).notNull(),
  quantity: integer('quantity').notNull().default(1),
  unitPrice: numeric('unit_price', { precision: 10, scale: 2 }).notNull(),
  totalPrice: numeric('total_price', { precision: 10, scale: 2 }).notNull(),
  status: varchar('status', { length: 20 }).notNull().default('Sold'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Sale Items relations
export const saleItemsRelations = relations(saleItems, ({ one }) => ({
  sale: one(sales, {
    fields: [saleItems.saleId],
    references: [sales.id],
  }),
  cylinder: one(cylinders, {
    fields: [saleItems.cylinderId],
    references: [cylinders.id],
  }),
}));

// Payments table
export const payments = pgTable('payments', {
  id: serial('id').primaryKey(),
  saleId: integer('sale_id').notNull().references(() => sales.id),
  paymentDate: timestamp('payment_date').notNull().defaultNow(),
  receivedById: integer('received_by_id').notNull().references(() => users.id),
  amount: numeric('amount', { precision: 10, scale: 2 }).notNull(),
  paymentMethod: varchar('payment_method', { length: 50 }).notNull(),
  referenceNumber: varchar('reference_number', { length: 50 }),
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Payments relations
export const paymentsRelations = relations(payments, ({ one }) => ({
  sale: one(sales, {
    fields: [payments.saleId],
    references: [sales.id],
  }),
  receivedBy: one(users, {
    fields: [payments.receivedById],
    references: [users.id],
  }),
}));

// Trucks table
export const trucks = pgTable('trucks', {
  id: serial('id').primaryKey(),
  registrationNumber: varchar('registration_number', { length: 50 }).notNull().unique(),
  model: varchar('model', { length: 100 }),
  capacity: integer('capacity'),
  driverId: integer('driver_id').references(() => users.id),
  status: varchar('status', { length: 20 }).notNull().default('Available'),
  notes: text('notes'),
  active: boolean('active').notNull().default(true),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Trucks relations
export const trucksRelations = relations(trucks, ({ one, many }) => ({
  driver: one(users, {
    fields: [trucks.driverId],
    references: [users.id],
  }),
  deliveries: many(deliveries),
}));

// Deliveries table
export const deliveries = pgTable('deliveries', {
  id: serial('id').primaryKey(),
  saleId: integer('sale_id').notNull().references(() => sales.id),
  truckId: integer('truck_id').references(() => trucks.id),
  deliveryDate: timestamp('delivery_date'),
  scheduledDate: timestamp('scheduled_date'),
  driverId: integer('driver_id').references(() => users.id),
  status: varchar('status', { length: 20 }).notNull().default('Scheduled'),
  notes: text('notes'),
  address: text('address').notNull(),
  contactNumber: varchar('contact_number', { length: 20 }),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Deliveries relations
export const deliveriesRelations = relations(deliveries, ({ one }) => ({
  sale: one(sales, {
    fields: [deliveries.saleId],
    references: [sales.id],
  }),
  truck: one(trucks, {
    fields: [deliveries.truckId],
    references: [trucks.id],
  }),
  driver: one(users, {
    fields: [deliveries.driverId],
    references: [users.id],
  }),
}));

// Export types
export type User = typeof users.$inferSelect;
export type InsertUser = typeof users.$inferInsert;

export type Customer = typeof customers.$inferSelect;
export type InsertCustomer = typeof customers.$inferInsert;

export type Cylinder = typeof cylinders.$inferSelect;
export type InsertCylinder = typeof cylinders.$inferInsert;

export type Inspection = typeof inspections.$inferSelect;
export type InsertInspection = typeof inspections.$inferInsert;

export type FillingOperation = typeof fillingOperations.$inferSelect;
export type InsertFillingOperation = typeof fillingOperations.$inferInsert;

export type Sale = typeof sales.$inferSelect;
export type InsertSale = typeof sales.$inferInsert;

export type SaleItem = typeof saleItems.$inferSelect;
export type InsertSaleItem = typeof saleItems.$inferInsert;

export type Payment = typeof payments.$inferSelect;
export type InsertPayment = typeof payments.$inferInsert;

export type Truck = typeof trucks.$inferSelect;
export type InsertTruck = typeof trucks.$inferInsert;

export type Delivery = typeof deliveries.$inferSelect;
export type InsertDelivery = typeof deliveries.$inferInsert;