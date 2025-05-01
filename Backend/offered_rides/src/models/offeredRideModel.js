// models/offeredRideModel.js

const { getClient } = require('../config/connectDB');

async function getOfferedRideCollection() {
  const client = await getClient();
  const ridesDb = client.db('rides');          // explicitly “rides”
  return ridesDb.collection('offeredride');
}

module.exports = { getOfferedRideCollection };
