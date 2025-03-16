const WebSocket = require('ws');
const readline = require('readline');

// Create WebSocket connection
const ws = new WebSocket('ws://0.0.0.0:5000/ws');

// Create readline interface for user input
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Sample data for various events
const sampleEvents = {
  cylinderStatusUpdated: {
    id: 123,
    status: 'Full',
    notes: 'Filled and ready for delivery'
  },
  fillingStarted: {
    id: 456,
    cylinderId: 123,
    filledBy: 'John Doe',
    startTime: new Date().toISOString(),
    gasType: 'Oxygen'
  },
  fillingCompleted: {
    id: 456,
    cylinderId: 123,
    filledBy: 'John Doe',
    startTime: new Date(Date.now() - 3600000).toISOString(),
    endTime: new Date().toISOString(),
    gasType: 'Oxygen',
    quantity: 10.5,
    status: 'Completed'
  },
  inspectionCompleted: {
    id: 789,
    cylinderId: 123,
    inspectedBy: 'Jane Smith',
    inspectionDate: new Date().toISOString(),
    result: 'Approved',
    notes: 'Passed all safety checks'
  },
  saleCreated: {
    id: 101,
    customerId: 202,
    customerName: 'Acme Hospital',
    totalAmount: 1250,
    status: 'Pending',
    paymentStatus: 'Unpaid',
    items: [
      { cylinderId: 123, quantity: 1, unitPrice: 1250 }
    ]
  },
  saleStatusUpdated: {
    id: 101,
    status: 'Delivered',
    notes: 'Delivered on time'
  },
  custom: {
    message: 'System maintenance scheduled for tomorrow at 2:00 AM'
  }
};

// Display menu options
function showMenu() {
  console.log('\n== Cylinder Management System WebSocket Simulator ==');
  console.log('1. Simulate cylinder status update');
  console.log('2. Simulate filling started');
  console.log('3. Simulate filling completed');
  console.log('4. Simulate inspection completed');
  console.log('5. Simulate sale created');
  console.log('6. Simulate sale status updated');
  console.log('7. Send custom message');
  console.log('0. Exit');
  rl.question('\nSelect an option: ', handleOption);
}

// Handle user selection
function handleOption(option) {
  switch (option) {
    case '1':
      sendEvent('cylinder_status_updated', sampleEvents.cylinderStatusUpdated);
      break;
    case '2':
      sendEvent('filling_started', sampleEvents.fillingStarted);
      break;
    case '3':
      sendEvent('filling_completed', sampleEvents.fillingCompleted);
      break;
    case '4':
      sendEvent('inspection_completed', sampleEvents.inspectionCompleted);
      break;
    case '5':
      sendEvent('sale_created', sampleEvents.saleCreated);
      break;
    case '6':
      sendEvent('sale_status_updated', sampleEvents.saleStatusUpdated);
      break;
    case '7':
      rl.question('Enter custom message: ', (message) => {
        sendEvent('custom', { message });
      });
      return; // Skip showMenu call to wait for user input
    case '0':
      console.log('Exiting...');
      ws.close();
      rl.close();
      return;
    default:
      console.log('Invalid option, please try again.');
  }
  
  // Show menu again after processing option
  setTimeout(showMenu, 500);
}

// Send event to WebSocket server
function sendEvent(type, data) {
  if (ws.readyState === WebSocket.OPEN) {
    const event = { type, data };
    console.log(`Sending event: ${type}`);
    ws.send(JSON.stringify(event));
  } else {
    console.log('WebSocket is not connected. Please wait...');
  }
}

// Connection opened
ws.on('open', function() {
  console.log('Connected to the WebSocket server');
  showMenu();
});

// Listen for messages
ws.on('message', function(data) {
  const message = JSON.parse(data.toString());
  console.log('\nReceived from server:', message);
  
  // Don't show menu again if we're waiting for custom message input
  if (message.type !== 'echo' || message.data.type !== 'custom') {
    setTimeout(showMenu, 500);
  }
});

// Handle errors
ws.on('error', function(error) {
  console.error('WebSocket error:', error);
});

// Handle connection close
ws.on('close', function() {
  console.log('Disconnected from the WebSocket server');
  rl.close();
  process.exit(0);
});

console.log('Connecting to WebSocket server...');