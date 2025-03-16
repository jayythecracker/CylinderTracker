/**
 * WebSocket Broadcast Utility
 * Provides functions for sending real-time updates to connected clients
 */

// Reference to wsBroadcast function from server.js
const broadcast = (data) => {
  if (global.wsBroadcast) {
    global.wsBroadcast(data);
  }
};

/**
 * Broadcast cylinder created event
 * @param {Object} cylinder - The newly created cylinder object
 */
exports.cylinderCreated = (cylinder) => {
  broadcast({
    type: 'cylinder_created',
    data: cylinder
  });
};

/**
 * Broadcast cylinder updated event
 * @param {Object} cylinder - The updated cylinder object
 */
exports.cylinderUpdated = (cylinder) => {
  broadcast({
    type: 'cylinder_updated',
    data: cylinder
  });
};

/**
 * Broadcast cylinder deleted event
 * @param {number} id - The ID of the deleted cylinder
 */
exports.cylinderDeleted = (id) => {
  broadcast({
    type: 'cylinder_deleted',
    data: { id }
  });
};

/**
 * Broadcast cylinder status update event
 * @param {Object} data - Contains id, status and notes
 */
exports.cylinderStatusUpdated = (data) => {
  broadcast({
    type: 'cylinder_status_updated',
    data
  });
};

/**
 * Broadcast filling operation started event
 * @param {Object} filling - The filling operation details
 */
exports.fillingStarted = (filling) => {
  broadcast({
    type: 'filling_started',
    data: filling
  });
};

/**
 * Broadcast filling operation completed event
 * @param {Object} filling - The completed filling operation details
 */
exports.fillingCompleted = (filling) => {
  broadcast({
    type: 'filling_completed',
    data: filling
  });
};

/**
 * Broadcast inspection event
 * @param {Object} inspection - The inspection details
 */
exports.inspectionCompleted = (inspection) => {
  broadcast({
    type: 'inspection_completed',
    data: inspection
  });
};

/**
 * Broadcast sale event
 * @param {Object} sale - The sale details
 */
exports.saleCreated = (sale) => {
  broadcast({
    type: 'sale_created',
    data: sale
  });
};

/**
 * Broadcast sale status update event
 * @param {Object} data - The sale status update details
 */
exports.saleStatusUpdated = (data) => {
  broadcast({
    type: 'sale_status_updated',
    data
  });
};

/**
 * Broadcast custom event
 * @param {string} type - The event type
 * @param {Object} data - The data to broadcast
 */
exports.custom = (type, data) => {
  broadcast({
    type,
    data
  });
};