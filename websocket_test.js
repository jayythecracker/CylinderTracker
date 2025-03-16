const WebSocket = require('ws');

// Create WebSocket connection
const ws = new WebSocket('ws://0.0.0.0:5000/ws');

// Connection opened
ws.on('open', function() {
  console.log('Connected to the WebSocket server');
  
  // Send a test message
  ws.send(JSON.stringify({
    type: 'test',
    message: 'Hello from WebSocket client'
  }));
});

// Listen for messages
ws.on('message', function(data) {
  console.log('Message from server:', JSON.parse(data.toString()));
  
  // Close the connection after receiving a message
  setTimeout(() => {
    console.log('Closing connection...');
    ws.close();
    process.exit(0);
  }, 1000);
});

// Handle errors
ws.on('error', function(error) {
  console.error('WebSocket error:', error);
  process.exit(1);
});
