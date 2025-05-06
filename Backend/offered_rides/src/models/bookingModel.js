// src/models/bookingModel.js
const { getClient } = require('../config/connectDB');
async function getBookingCollection() {
  const client = await getClient();
  const ridesDb = client.db('rides');           // same DB as offeredRideModel
  return ridesDb.collection('booking');
}
module.exports = { getBookingCollection };
