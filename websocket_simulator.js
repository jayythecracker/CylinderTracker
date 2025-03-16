// WebSocket Event Simulator for Cylinder Management System
// This script simulates WebSocket events to test real-time functionality
// Usage: node websocket_simulator.js

const WebSocket = require('ws');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Define a sample cylinder
const sampleCylinder = {
  id: 123,
  serialNumber: 'CYL-2025-123',
  size: 'Medium',
  type: 'Industrial',
  gasType: 'Oxygen',
  importDate: '2025-01-15T00:00:00.000Z',
  productionDate: '2025-01-01T00:00:00.000Z',
  originalNumber: 'MFR-123-456',
  workingPressure: 150.0,
  designPressure: 200.0,
  status: 'Empty',
  factoryId: 1,
  lastFilled: null,
  lastInspected: '2025-02-01T00:00:00.000Z',
  qrCode: 'QR-CYL-123',
  notes: 'New cylinder',
  createdAt: '2025-03-01T00:00:00.000Z',
  updatedAt: '2025-03-01T00:00:00.000Z'
};

// Define a sample filling operation
const sampleFillingOperation = {
  id: 456,
  cylinderId: 123,
  filledById: 789,
  fillingDate: new Date().toISOString(),
  gasType: 'Oxygen',
  initialPressure: 0,
  finalPressure: 200,
  status: 'Completed',
  notes: 'Standard filling',
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString()
};

// Define a sample inspection
const sampleInspection = {
  id: 789,
  cylinderId: 123,
  inspectionDate: new Date().toISOString(),
  inspectedById: 789,
  visualInspection: true,
  pressureReading: 200,
  result: 'Approved',
  notes: 'Regular inspection, no issues found',
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString()
};

// Define a sample sale
const sampleSale = {
  id: 101,
  customerId: 202,
  saleDate: new Date().toISOString(),
  totalAmount: 1500.0,
  paidAmount: 0,
  status: 'Pending',
  paymentStatus: 'Unpaid',
  deliveryType: 'Delivery',
  notes: 'Regular customer order',
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString()
};

// Connect to WebSocket server
let serverUrl = 'ws://localhost:5000/ws';
let ws;

function connectWebSocket() {
  ws = new WebSocket(serverUrl);
  
  ws.on('open', () => {
    console.log('Connected to WebSocket server at ' + serverUrl);
    showMenu();
  });
  
  ws.on('message', (data) => {
    console.log('Received: ' + data);
  });
  
  ws.on('close', () => {
    console.log('Disconnected from WebSocket server');
  });
  
  ws.on('error', (error) => {
    console.error('WebSocket error: ', error);
  });
}

// Main menu
function showMenu() {
  console.log('\n=== WebSocket Event Simulator ===');
  console.log('1. Cylinder Created');
  console.log('2. Cylinder Updated');
  console.log('3. Cylinder Status Updated');
  console.log('4. Filling Started');
  console.log('5. Filling Completed');
  console.log('6. Inspection Completed');
  console.log('7. Sale Created');
  console.log('8. Sale Status Updated');
  console.log('9. Change Connection URL');
  console.log('0. Exit');
  
  rl.question('Select an option: ', (answer) => {
    handleOption(answer);
  });
}

// Handle menu option
function handleOption(option) {
  switch (option) {
    case '1':
      sendEvent('cylinder_created', sampleCylinder);
      break;
    case '2':
      const updatedCylinder = { ...sampleCylinder, status: 'Full', notes: 'Updated cylinder' };
      sendEvent('cylinder_updated', updatedCylinder);
      break;
    case '3':
      sendEvent('cylinder_status_updated', {
        id: sampleCylinder.id,
        status: 'Full',
        notes: 'Filled and ready for delivery'
      });
      break;
    case '4':
      sendEvent('filling_started', {
        ...sampleFillingOperation,
        status: 'InProgress',
        finalPressure: null
      });
      break;
    case '5':
      sendEvent('filling_completed', sampleFillingOperation);
      break;
    case '6':
      sendEvent('inspection_completed', sampleInspection);
      break;
    case '7':
      sendEvent('sale_created', sampleSale);
      break;
    case '8':
      sendEvent('sale_status_updated', {
        id: sampleSale.id,
        status: 'Delivered',
        notes: 'Successfully delivered to customer'
      });
      break;
    case '9':
      rl.question('Enter new WebSocket URL (default: ws://localhost:5000/ws): ', (url) => {
        serverUrl = url || 'ws://localhost:5000/ws';
        console.log(`WebSocket URL changed to ${serverUrl}`);
        if (ws) {
          ws.close();
        }
        connectWebSocket();
      });
      return;
    case '0':
      console.log('Exiting...');
      if (ws) {
        ws.close();
      }
      rl.close();
      process.exit(0);
      break;
    default:
      console.log('Invalid option');
      break;
  }
  
  // Show menu again unless exiting
  if (option !== '0' && option !== '9') {
    showMenu();
  }
}

// Send event to WebSocket server
function sendEvent(type, data) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    const message = JSON.stringify({
      type: type,
      data: data
    });
    
    ws.send(message);
    console.log(`Sent ${type} event:`);
    console.log(JSON.stringify(data, null, 2));
  } else {
    console.log('WebSocket not connected. Reconnecting...');
    connectWebSocket();
  }
}

// Start the program
console.log('Starting WebSocket Event Simulator...');
connectWebSocket();