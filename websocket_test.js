// Simple WebSocket Test Client
// This script connects to the WebSocket server and listens for events
// Usage: node websocket_test.js

const WebSocket = require('ws');

// Connect to WebSocket server
const serverUrl = 'ws://localhost:5000/ws';
const ws = new WebSocket(serverUrl);

console.log(`Connecting to WebSocket server at ${serverUrl}...`);

// Connection opened
ws.on('open', () => {
  console.log('Connected to WebSocket server!');
  console.log('Listening for events... (Ctrl+C to exit)');
  
  // Send a ping message every 30 seconds to keep the connection alive
  setInterval(() => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'ping', data: { timestamp: new Date().toISOString() } }));
    }
  }, 30000);
});

// Listen for messages
ws.on('message', (data) => {
  try {
    const message = JSON.parse(data.toString());
    console.log('\n===== EVENT RECEIVED =====');
    console.log(`Type: ${message.type}`);
    console.log('Data:');
    console.log(JSON.stringify(message.data, null, 2));
    console.log('=========================\n');
  } catch (error) {
    console.log('Received non-JSON message: ' + data);
  }
});

// Connection closed
ws.on('close', (code, reason) => {
  console.log(`Disconnected from WebSocket server: ${code} - ${reason}`);
  process.exit(0);
});

// Connection error
ws.on('error', (error) => {
  console.error('WebSocket error:', error);
});

// Handle process termination
process.on('SIGINT', () => {
  console.log('Closing WebSocket connection...');
  ws.close();
  process.exit(0);
});