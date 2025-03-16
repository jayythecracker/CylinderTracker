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

### Data Storage Architecture

The system implements a clean separation of concerns with a repository pattern:

- **IStorage Interface**: Defines a consistent API for data access operations
- **DatabaseStorage Class**: Implements the storage interface with Drizzle ORM
- **Controller Layer**: Uses the storage interface to interact with the database
- **Service Layer**: Implements business logic using the storage interface

Each entity (User, Factory, Cylinder, etc.) has corresponding CRUD operations and specialized methods in the storage interface. This architecture allows for:

- Consistent data access patterns
- Easy testing with mock implementations
- Clear separation between business logic and data access
- Clean implementation of transaction management

## WebSocket Events

The system implements real-time updates via WebSocket for the following events:

### WebSocket Event Types

| Event Type | Description | Trigger |
|------------|-------------|---------|
| `cylinder_created` | New cylinder added to the system | When a new cylinder is created |
| `cylinder_updated` | Cylinder details updated | When cylinder information is modified |
| `cylinder_deleted` | Cylinder removed from the system | When a cylinder is deleted |
| `cylinder_status_updated` | Cylinder status changed | When a cylinder's status is updated (e.g., Empty → Full) |
| `filling_started` | Filling operation initiated | When a filling process begins |
| `filling_completed` | Filling operation finished | When a filling process is completed |
| `inspection_completed` | Inspection performed | When a cylinder inspection is completed |
| `sale_created` | New sale recorded | When a new sale is created |
| `sale_status_updated` | Sale status changed | When a sale's status is updated |
| `custom` | Custom system message | For system announcements or custom notifications |

### WebSocket Implementation

The system uses a dedicated WebSocket server that:

1. **Runs on the same HTTP server** as the REST API (path: `/ws`)
2. **Maintains active connections** in a connection pool
3. **Broadcasts events** to all connected clients
4. **Provides utility functions** through the `broadcast.js` module
5. **Supports event types** for all major system operations

### Message Format

All WebSocket messages follow a standard format:

```json
{
  "type": "event_type_name",
  "data": {
    // Event-specific data payload
  }
}
```

### Example Messages

**Cylinder Status Update:**
```json
{
  "type": "cylinder_status_updated",
  "data": {
    "id": 123,
    "status": "Full",
    "notes": "Filled on March 15",
    "updatedBy": "john.doe",
    "timestamp": "2025-03-16T10:30:45Z"
  }
}
```

**Filling Completed:**
```json
{
  "type": "filling_completed",
  "data": {
    "id": 456,
    "cylinderId": 123,
    "filledBy": "john.doe",
    "startTime": "2025-03-16T09:15:20Z",
    "endTime": "2025-03-16T10:20:30Z",
    "gasType": "Oxygen",
    "quantity": 10.5,
    "status": "Completed"
  }
}
```

**Inspection Completed:**
```json
{
  "type": "inspection_completed",
  "data": {
    "id": 789,
    "cylinderId": 123,
    "inspectedBy": "jane.smith",
    "inspectionDate": "2025-03-16T11:45:00Z",
    "result": "Approved",
    "notes": "Passed all safety checks"
  }
}
```

### Integration in Flutter Frontend

The Flutter app uses the `WebSocketService` class to maintain a connection to the server and process events:

```dart
// Initialize the service
final websocketService = ref.watch(websocketServiceProvider);

// Listen for specific event types
ref.listen<AsyncValue<dynamic>>(
  websocketEventProvider(WebSocketEventType.cylinderStatusUpdated), 
  (_, state) {
    state.whenData((data) {
      // Handle cylinder status update
    });
  }
);
```

The `RealTimeUpdatesWidget` component provides a ready-to-use UI element that displays recent events in real-time.

Clients can subscribe to these events to update their UI in real-time without polling the server.

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

### API Security

The API implements several security measures:

1. **JWT Authentication**: All protected endpoints require a valid JWT token
2. **Role-Based Access Control**: Endpoints are restricted based on user roles
3. **Input Validation**: Request data is validated before processing
4. **Rate Limiting**: Prevents abuse of the API with rate limits
5. **Error Handling**: Standardized error responses with appropriate HTTP status codes

Example authentication flow:
```
POST /api/auth/login
{
  "username": "user@example.com",
  "password": "securePassword"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "user@example.com",
    "role": "manager"
  }
}
```

All subsequent requests include the JWT token in the Authorization header:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

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