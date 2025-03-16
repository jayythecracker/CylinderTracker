const app = require('./app');
const dotenv = require('dotenv');
const { WebSocketServer, WebSocket } = require('ws');
const http = require('http');

// Load environment variables
dotenv.config();

const PORT = process.env.PORT || 5000;
const HOST = '0.0.0.0';

// Store active WebSocket connections
let activeConnections = [];

// Broadcast to all connected clients
function broadcast(data) {
  const message = JSON.stringify(data);
  activeConnections.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// Make broadcast function available globally
global.wsBroadcast = broadcast;

async function startServer() {
  try {
    // Create HTTP server
    const server = http.createServer(app);
    
    // Initialize WebSocket server
    const wss = new WebSocketServer({ server, path: '/ws' });
    
    // WebSocket connection handling
    wss.on('connection', (ws) => {
      console.log('WebSocket client connected');
      
      // Add to active connections
      activeConnections.push(ws);
      
      // Send welcome message
      ws.send(JSON.stringify({
        type: 'connection',
        message: 'Connected to Cylinder Management System'
      }));
      
      // Handle messages from client
      ws.on('message', (message) => {
        try {
          const data = JSON.parse(message);
          console.log('Received:', data);
          
          // Echo back to client for now
          ws.send(JSON.stringify({
            type: 'echo',
            data
          }));
        } catch (error) {
          console.error('Error processing WebSocket message:', error);
        }
      });
      
      // Handle disconnection
      ws.on('close', () => {
        console.log('WebSocket client disconnected');
        // Remove from active connections
        activeConnections = activeConnections.filter(client => client !== ws);
      });
    });
    
    // Start the server
    server.listen(PORT, HOST, () => {
      console.log(`Server running on http://${HOST}:${PORT}`);
      console.log(`WebSocket server running on ws://${HOST}:${PORT}/ws`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
