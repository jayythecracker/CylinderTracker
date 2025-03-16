# Cylinder Management System

A comprehensive system for tracking and managing the complete lifecycle of industrial gas cylinders, from manufacturing to delivery and inspection.

## Architecture

### Backend (Node.js)
- **Express.js** RESTful API
- **PostgreSQL** database with **Drizzle ORM**
- **JWT** authentication with role-based access control
- **WebSocket** server for real-time updates

### Frontend (Flutter)
- Cross-platform support for mobile and web
- Material Design UI
- Real-time updates via WebSocket connection

## Core Features

- **User Management**: Role-based access (Admin, Manager, Filler, Inspector, Seller, Viewer)
- **Factory Management**: Track multiple factories and their cylinders
- **Cylinder Tracking**: Complete lifecycle tracking with QR codes
- **Customer Management**: Track customer data, credit limits, and preferences
- **Filling Operations**: Record and track cylinder filling processes
- **Inspections**: Schedule and record mandatory safety inspections
- **Sales**: Track cylinder sales and deliveries
- **Real-time Updates**: WebSocket-based notifications for status changes

## Database Schema

The system uses a comprehensive relational database schema with the following main entities:

- **Users**: System users with different roles and permissions
- **Factories**: Production facilities and their information
- **Cylinders**: Individual cylinders and their specifications
- **Customers**: Customer profiles and account information
- **Inspections**: Safety inspection records
- **Filling Operations**: Records of cylinder filling processes
- **Sales**: Sales records with items and payments
- **Deliveries**: Delivery tracking for cylinders

## WebSocket Events

The system implements real-time updates via WebSocket for the following events:

- Cylinder status changes
- Filling operations (start/complete)
- Inspection results
- Sale updates
- Delivery status changes

## API Structure

The API follows a RESTful structure with the following main endpoints:

- `/api/auth`: Authentication and user management
- `/api/factories`: Factory CRUD operations
- `/api/cylinders`: Cylinder management and tracking
- `/api/customers`: Customer management
- `/api/fillings`: Filling operations
- `/api/inspections`: Inspection management
- `/api/sales`: Sales and delivery tracking
- `/api/reports`: Reporting and analytics

## Getting Started

1. Ensure you have Node.js and PostgreSQL installed
2. Clone the repository
3. Install dependencies: `npm install`
4. Set up environment variables in `.env`
5. Run database migrations: `npm run db:push`
6. Start the server: `npm start`
7. Access the API at `http://localhost:5000`

## Environment Variables

- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: Secret key for JWT token generation
- `PORT`: Server port (default: 5000)

## Development

- `npm run dev`: Start development server with hot-reload
- `npm run db:push`: Push schema changes to the database
- `npm run test`: Run tests