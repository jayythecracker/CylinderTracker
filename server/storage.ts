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
  
  // Additional entity operations would be added here for Customer, Inspection, FillingOperation, etc.
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

  // Additional entity operations would be implemented here for Customer, Inspection, FillingOperation, etc.
}

export const storage = new DatabaseStorage();