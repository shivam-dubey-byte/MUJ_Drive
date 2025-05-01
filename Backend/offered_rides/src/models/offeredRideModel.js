// models/offeredRideModel.js

const connectDB = require('../config/connectDB');

async function getOfferedRideCollection() {
  const db = await connectDB();
  return db.collection('offeredride');
}

module.exports = { getOfferedRideCollection };
