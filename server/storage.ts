import { 
  users, cylinders, factories, customers, inspections, fillingOperations, sales, saleItems, payments, trucks, deliveries,
  type User, type InsertUser,
  type Cylinder, type InsertCylinder,
  type Factory, type InsertFactory,
  type Customer, type InsertCustomer,
  type Inspection, type InsertInspection,
  type FillingOperation, type InsertFillingOperation,
  type Sale, type InsertSale,
  type SaleItem, type InsertSaleItem,
  type Payment, type InsertPayment,
  type Truck, type InsertTruck,
  type Delivery, type InsertDelivery
} from "../shared/schema";
import { db } from "./db";
import { eq, and, desc, asc, gte, lte, like, inArray, count } from "drizzle-orm";

// Interface for storage operations
export interface IStorage {
  // User operations
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  getUsers(page?: number, limit?: number): Promise<{ users: User[], total: number }>;
  createUser(insertUser: InsertUser): Promise<User>;
  updateUser(id: number, updateData: Partial<InsertUser>): Promise<User | undefined>;
  deleteUser(id: number): Promise<boolean>;

  // Factory operations
  getFactory(id: number): Promise<Factory | undefined>;
  getFactories(page?: number, limit?: number): Promise<{ factories: Factory[], total: number }>;
  createFactory(insertFactory: InsertFactory): Promise<Factory>;
  updateFactory(id: number, updateData: Partial<InsertFactory>): Promise<Factory | undefined>;
  deleteFactory(id: number): Promise<boolean>;

  // Cylinder operations
  getCylinder(id: number): Promise<Cylinder | undefined>;
  getCylinderBySerialNumber(serialNumber: string): Promise<Cylinder | undefined>;
  getCylinders(page?: number, limit?: number, filters?: Partial<Cylinder>): Promise<{ cylinders: Cylinder[], total: number }>;
  createCylinder(insertCylinder: InsertCylinder): Promise<Cylinder>;
  updateCylinder(id: number, updateData: Partial<InsertCylinder>): Promise<Cylinder | undefined>;
  deleteCylinder(id: number): Promise<boolean>;
  
  // Customer operations
  getCustomer(id: number): Promise<Customer | undefined>;
  getCustomers(page?: number, limit?: number, filters?: Partial<Customer>): Promise<{ customers: Customer[], total: number }>;
  createCustomer(insertCustomer: InsertCustomer): Promise<Customer>;
  updateCustomer(id: number, updateData: Partial<InsertCustomer>): Promise<Customer | undefined>;
  deleteCustomer(id: number): Promise<boolean>;
  
  // Inspection operations
  getInspection(id: number): Promise<Inspection | undefined>;
  getInspections(page?: number, limit?: number, cylinderId?: number): Promise<{ inspections: Inspection[], total: number }>;
  createInspection(insertInspection: InsertInspection): Promise<Inspection>;
  
  // FillingOperation operations
  getFillingOperation(id: number): Promise<FillingOperation | undefined>;
  getFillingOperations(page?: number, limit?: number, cylinderId?: number): Promise<{ fillingOperations: FillingOperation[], total: number }>;
  createFillingOperation(insertFillingOperation: InsertFillingOperation): Promise<FillingOperation>;
  
  // Sale operations
  getSale(id: number): Promise<Sale | undefined>;
  getSales(page?: number, limit?: number, customerId?: number): Promise<{ sales: Sale[], total: number }>;
  createSale(insertSale: InsertSale): Promise<Sale>;
  updateSaleStatus(id: number, status: string, notes?: string): Promise<Sale | undefined>;
  updateSalePaymentStatus(id: number, paymentStatus: string, paidAmount: number): Promise<Sale | undefined>;
  
  // SaleItem operations
  getSaleItems(saleId: number): Promise<SaleItem[]>;
  createSaleItem(insertSaleItem: InsertSaleItem): Promise<SaleItem>;
  
  // Payment operations
  getPayment(id: number): Promise<Payment | undefined>;
  getPaymentsBySale(saleId: number): Promise<Payment[]>;
  createPayment(insertPayment: InsertPayment): Promise<Payment>;
  
  // Truck operations
  getTruck(id: number): Promise<Truck | undefined>;
  getTrucks(page?: number, limit?: number, activeOnly?: boolean): Promise<{ trucks: Truck[], total: number }>;
  createTruck(insertTruck: InsertTruck): Promise<Truck>;
  updateTruck(id: number, updateData: Partial<InsertTruck>): Promise<Truck | undefined>;
  deleteTruck(id: number): Promise<boolean>;
  
  // Delivery operations
  getDelivery(id: number): Promise<Delivery | undefined>;
  getDeliveriesBySale(saleId: number): Promise<Delivery[]>;
  createDelivery(insertDelivery: InsertDelivery): Promise<Delivery>;
  updateDeliveryStatus(id: number, status: string, notes?: string): Promise<Delivery | undefined>;
}

// Database implementation of storage
export class DatabaseStorage implements IStorage {
  // ============ USER OPERATIONS ============
  async getUser(id: number): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user || undefined;
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.username, username));
    return user || undefined;
  }

  async getUsers(page = 1, limit = 10): Promise<{ users: User[], total: number }> {
    const offset = (page - 1) * limit;
    const results = await db.select().from(users).limit(limit).offset(offset);
    const [countResult] = await db.select({ count: count() }).from(users);
    return { 
      users: results, 
      total: Number(countResult.count) 
    };
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    const [user] = await db
      .insert(users)
      .values(insertUser)
      .returning();
    return user;
  }

  async updateUser(id: number, updateData: Partial<InsertUser>): Promise<User | undefined> {
    const [updatedUser] = await db
      .update(users)
      .set({...updateData, updated_at: new Date()})
      .where(eq(users.id, id))
      .returning();
    return updatedUser;
  }

  async deleteUser(id: number): Promise<boolean> {
    const result = await db
      .delete(users)
      .where(eq(users.id, id))
      .returning({ id: users.id });
    return result.length > 0;
  }

  // ============ FACTORY OPERATIONS ============
  async getFactory(id: number): Promise<Factory | undefined> {
    const [factory] = await db.select().from(factories).where(eq(factories.id, id));
    return factory || undefined;
  }

  async getFactories(page = 1, limit = 10): Promise<{ factories: Factory[], total: number }> {
    const offset = (page - 1) * limit;
    const results = await db.select().from(factories).limit(limit).offset(offset);
    const [countResult] = await db.select({ count: count() }).from(factories);
    return { 
      factories: results, 
      total: Number(countResult.count) 
    };
  }

  async createFactory(insertFactory: InsertFactory): Promise<Factory> {
    const [factory] = await db
      .insert(factories)
      .values(insertFactory)
      .returning();
    return factory;
  }

  async updateFactory(id: number, updateData: Partial<InsertFactory>): Promise<Factory | undefined> {
    const [updatedFactory] = await db
      .update(factories)
      .set({...updateData, updated_at: new Date()})
      .where(eq(factories.id, id))
      .returning();
    return updatedFactory;
  }

  async deleteFactory(id: number): Promise<boolean> {
    const result = await db
      .delete(factories)
      .where(eq(factories.id, id))
      .returning({ id: factories.id });
    return result.length > 0;
  }

  // ============ CYLINDER OPERATIONS ============
  async getCylinder(id: number): Promise<Cylinder | undefined> {
    const [cylinder] = await db.select().from(cylinders).where(eq(cylinders.id, id));
    return cylinder || undefined;
  }

  async getCylinderBySerialNumber(serialNumber: string): Promise<Cylinder | undefined> {
    const [cylinder] = await db.select().from(cylinders).where(eq(cylinders.serialNumber, serialNumber));
    return cylinder || undefined;
  }

  async getCylinders(page = 1, limit = 10, filters?: Partial<Cylinder>): Promise<{ cylinders: Cylinder[], total: number }> {
    const offset = (page - 1) * limit;
    
    // Build conditions array
    const conditions = [];
    if (filters) {
      if (filters.gasType) {
        conditions.push(eq(cylinders.gasType, filters.gasType));
      }
      
      if (filters.status) {
        conditions.push(eq(cylinders.status, filters.status));
      }
      
      if (filters.size) {
        conditions.push(eq(cylinders.size, filters.size));
      }
      
      if (filters.factoryId) {
        conditions.push(eq(cylinders.factoryId, filters.factoryId));
      }
      
      if (filters.currentCustomerId) {
        conditions.push(eq(cylinders.currentCustomerId, filters.currentCustomerId));
      }
    }
    
    // Execute the query with pagination
    let results: Cylinder[];
    if (conditions.length > 0) {
      results = await db.select()
        .from(cylinders)
        .where(and(...conditions))
        .limit(limit)
        .offset(offset);
    } else {
      results = await db.select()
        .from(cylinders)
        .limit(limit)
        .offset(offset);
    }
    
    // Count total records
    let countResult;
    if (conditions.length > 0) {
      [countResult] = await db.select({ count: count() })
        .from(cylinders)
        .where(and(...conditions));
    } else {
      [countResult] = await db.select({ count: count() })
        .from(cylinders);
    }
    
    return { 
      cylinders: results, 
      total: Number(countResult.count) 
    };
  }

  async createCylinder(insertCylinder: InsertCylinder): Promise<Cylinder> {
    const [cylinder] = await db
      .insert(cylinders)
      .values(insertCylinder)
      .returning();
    return cylinder;
  }

  async updateCylinder(id: number, updateData: Partial<InsertCylinder>): Promise<Cylinder | undefined> {
    const [updatedCylinder] = await db
      .update(cylinders)
      .set({...updateData, updatedAt: new Date()})
      .where(eq(cylinders.id, id))
      .returning();
    return updatedCylinder;
  }

  async deleteCylinder(id: number): Promise<boolean> {
    const result = await db
      .delete(cylinders)
      .where(eq(cylinders.id, id))
      .returning({ id: cylinders.id });
    return result.length > 0;
  }

  // ============ CUSTOMER OPERATIONS ============
  async getCustomer(id: number): Promise<Customer | undefined> {
    const [customer] = await db.select().from(customers).where(eq(customers.id, id));
    return customer || undefined;
  }

  async getCustomers(page = 1, limit = 10, filters?: Partial<Customer>): Promise<{ customers: Customer[], total: number }> {
    const offset = (page - 1) * limit;
    
    // Build conditions array
    const conditions = [];
    if (filters) {
      if (filters.type) {
        conditions.push(eq(customers.type, filters.type));
      }
      
      if (filters.paymentType) {
        conditions.push(eq(customers.paymentType, filters.paymentType));
      }
      
      if (filters.active !== undefined) {
        conditions.push(eq(customers.active, filters.active));
      }
    }
    
    // Execute the query with pagination
    let results: Customer[];
    if (conditions.length > 0) {
      results = await db.select()
        .from(customers)
        .where(and(...conditions))
        .limit(limit)
        .offset(offset);
    } else {
      results = await db.select()
        .from(customers)
        .limit(limit)
        .offset(offset);
    }
    
    // Count total records
    let countResult;
    if (conditions.length > 0) {
      [countResult] = await db.select({ count: count() })
        .from(customers)
        .where(and(...conditions));
    } else {
      [countResult] = await db.select({ count: count() })
        .from(customers);
    }
    
    return { 
      customers: results, 
      total: Number(countResult.count) 
    };
  }

  async createCustomer(insertCustomer: InsertCustomer): Promise<Customer> {
    const [customer] = await db
      .insert(customers)
      .values(insertCustomer)
      .returning();
    return customer;
  }

  async updateCustomer(id: number, updateData: Partial<InsertCustomer>): Promise<Customer | undefined> {
    const [updatedCustomer] = await db
      .update(customers)
      .set({...updateData, updatedAt: new Date()})
      .where(eq(customers.id, id))
      .returning();
    return updatedCustomer;
  }

  async deleteCustomer(id: number): Promise<boolean> {
    const result = await db
      .delete(customers)
      .where(eq(customers.id, id))
      .returning({ id: customers.id });
    return result.length > 0;
  }

  // ============ INSPECTION OPERATIONS ============
  async getInspection(id: number): Promise<Inspection | undefined> {
    const [inspection] = await db.select().from(inspections).where(eq(inspections.id, id));
    return inspection || undefined;
  }

  async getInspections(page = 1, limit = 10, cylinderId?: number): Promise<{ inspections: Inspection[], total: number }> {
    const offset = (page - 1) * limit;
    
    // Execute the query with pagination
    let results: Inspection[];
    let countResult;
    
    if (cylinderId) {
      results = await db.select()
        .from(inspections)
        .where(eq(inspections.cylinderId, cylinderId))
        .limit(limit)
        .offset(offset);
      
      [countResult] = await db.select({ count: count() })
        .from(inspections)
        .where(eq(inspections.cylinderId, cylinderId));
    } else {
      results = await db.select()
        .from(inspections)
        .limit(limit)
        .offset(offset);
      
      [countResult] = await db.select({ count: count() })
        .from(inspections);
    }
    
    return { 
      inspections: results, 
      total: Number(countResult.count) 
    };
  }

  async createInspection(insertInspection: InsertInspection): Promise<Inspection> {
    const [inspection] = await db
      .insert(inspections)
      .values(insertInspection)
      .returning();
    return inspection;
  }

  // ============ FILLING OPERATION OPERATIONS ============
  async getFillingOperation(id: number): Promise<FillingOperation | undefined> {
    const [fillingOperation] = await db.select()
      .from(fillingOperations)
      .where(eq(fillingOperations.id, id));
    return fillingOperation || undefined;
  }

  async getFillingOperations(page = 1, limit = 10, cylinderId?: number): Promise<{ fillingOperations: FillingOperation[], total: number }> {
    const offset = (page - 1) * limit;
    
    // Execute the query with pagination
    let results: FillingOperation[];
    let countResult;
    
    if (cylinderId) {
      results = await db.select()
        .from(fillingOperations)
        .where(eq(fillingOperations.cylinderId, cylinderId))
        .limit(limit)
        .offset(offset);
      
      [countResult] = await db.select({ count: count() })
        .from(fillingOperations)
        .where(eq(fillingOperations.cylinderId, cylinderId));
    } else {
      results = await db.select()
        .from(fillingOperations)
        .limit(limit)
        .offset(offset);
      
      [countResult] = await db.select({ count: count() })
        .from(fillingOperations);
    }
    
    return { 
      fillingOperations: results, 
      total: Number(countResult.count) 
    };
  }

  async createFillingOperation(insertFillingOperation: InsertFillingOperation): Promise<FillingOperation> {
    const [fillingOperation] = await db
      .insert(fillingOperations)
      .values(insertFillingOperation)
      .returning();
    return fillingOperation;
  }

  // ============ SALE OPERATIONS ============
  async getSale(id: number): Promise<Sale | undefined> {
    const [sale] = await db.select().from(sales).where(eq(sales.id, id));
    return sale || undefined;
  }

  async getSales(page = 1, limit = 10, customerId?: number): Promise<{ sales: Sale[], total: number }> {
    const offset = (page - 1) * limit;
    
    // Execute the query with pagination
    let results: Sale[];
    let countResult;
    
    if (customerId) {
      results = await db.select()
        .from(sales)
        .where(eq(sales.customerId, customerId))
        .orderBy(desc(sales.saleDate))
        .limit(limit)
        .offset(offset);
      
      [countResult] = await db.select({ count: count() })
        .from(sales)
        .where(eq(sales.customerId, customerId));
    } else {
      results = await db.select()
        .from(sales)
        .orderBy(desc(sales.saleDate))
        .limit(limit)
        .offset(offset);
      
      [countResult] = await db.select({ count: count() })
        .from(sales);
    }
    
    return { 
      sales: results, 
      total: Number(countResult.count) 
    };
  }

  async createSale(insertSale: InsertSale): Promise<Sale> {
    const [sale] = await db
      .insert(sales)
      .values(insertSale)
      .returning();
    return sale;
  }

  async updateSaleStatus(id: number, status: string, notes?: string): Promise<Sale | undefined> {
    const [updatedSale] = await db
      .update(sales)
      .set({ 
        status: status as any, // Type cast for enum
        notes: notes,
        updatedAt: new Date()
      })
      .where(eq(sales.id, id))
      .returning();
    return updatedSale;
  }

  async updateSalePaymentStatus(id: number, paymentStatus: string, paidAmount: number): Promise<Sale | undefined> {
    const [updatedSale] = await db
      .update(sales)
      .set({ 
        paymentStatus: paymentStatus as any, // Type cast for enum
        paidAmount,
        updatedAt: new Date()
      })
      .where(eq(sales.id, id))
      .returning();
    return updatedSale;
  }

  // ============ SALE ITEM OPERATIONS ============
  async getSaleItems(saleId: number): Promise<SaleItem[]> {
    return db.select()
      .from(saleItems)
      .where(eq(saleItems.saleId, saleId));
  }

  async createSaleItem(insertSaleItem: InsertSaleItem): Promise<SaleItem> {
    const [saleItem] = await db
      .insert(saleItems)
      .values(insertSaleItem)
      .returning();
    return saleItem;
  }

  // ============ PAYMENT OPERATIONS ============
  async getPayment(id: number): Promise<Payment | undefined> {
    const [payment] = await db.select().from(payments).where(eq(payments.id, id));
    return payment || undefined;
  }

  async getPaymentsBySale(saleId: number): Promise<Payment[]> {
    return db.select()
      .from(payments)
      .where(eq(payments.saleId, saleId))
      .orderBy(desc(payments.paymentDate));
  }

  async createPayment(insertPayment: InsertPayment): Promise<Payment> {
    const [payment] = await db
      .insert(payments)
      .values(insertPayment)
      .returning();
    return payment;
  }

  // ============ TRUCK OPERATIONS ============
  async getTruck(id: number): Promise<Truck | undefined> {
    const [truck] = await db.select().from(trucks).where(eq(trucks.id, id));
    return truck || undefined;
  }

  async getTrucks(page = 1, limit = 10, activeOnly = true): Promise<{ trucks: Truck[], total: number }> {
    const offset = (page - 1) * limit;
    
    // Execute the query with pagination
    let results: Truck[];
    let countResult;
    
    if (activeOnly) {
      results = await db.select()
        .from(trucks)
        .where(eq(trucks.active, true))
        .limit(limit)
        .offset(offset);
      
      [countResult] = await db.select({ count: count() })
        .from(trucks)
        .where(eq(trucks.active, true));
    } else {
      results = await db.select()
        .from(trucks)
        .limit(limit)
        .offset(offset);
      
      [countResult] = await db.select({ count: count() })
        .from(trucks);
    }
    
    return { 
      trucks: results, 
      total: Number(countResult.count) 
    };
  }

  async createTruck(insertTruck: InsertTruck): Promise<Truck> {
    const [truck] = await db
      .insert(trucks)
      .values(insertTruck)
      .returning();
    return truck;
  }

  async updateTruck(id: number, updateData: Partial<InsertTruck>): Promise<Truck | undefined> {
    const [updatedTruck] = await db
      .update(trucks)
      .set({...updateData, updatedAt: new Date()})
      .where(eq(trucks.id, id))
      .returning();
    return updatedTruck;
  }

  async deleteTruck(id: number): Promise<boolean> {
    const result = await db
      .delete(trucks)
      .where(eq(trucks.id, id))
      .returning({ id: trucks.id });
    return result.length > 0;
  }

  // ============ DELIVERY OPERATIONS ============
  async getDelivery(id: number): Promise<Delivery | undefined> {
    const [delivery] = await db.select().from(deliveries).where(eq(deliveries.id, id));
    return delivery || undefined;
  }

  async getDeliveriesBySale(saleId: number): Promise<Delivery[]> {
    return db.select()
      .from(deliveries)
      .where(eq(deliveries.saleId, saleId));
  }

  async createDelivery(insertDelivery: InsertDelivery): Promise<Delivery> {
    const [delivery] = await db
      .insert(deliveries)
      .values(insertDelivery)
      .returning();
    return delivery;
  }

  async updateDeliveryStatus(id: number, status: string, notes?: string): Promise<Delivery | undefined> {
    const [updatedDelivery] = await db
      .update(deliveries)
      .set({ 
        status: status,
        notes: notes,
        updatedAt: new Date()
      })
      .where(eq(deliveries.id, id))
      .returning();
    return updatedDelivery;
  }
}

export const storage = new DatabaseStorage();