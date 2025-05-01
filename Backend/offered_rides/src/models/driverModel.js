// models/driverModel.js

const { getClient } = require('../config/connectDB');

async function findDriverByEmail(email) {
  const client  = await getClient();
  const usersDb = client.db('Users');
  return usersDb
    .collection('driver')
    .findOne({ email }, { projection: { name:1, phone:1, _id:0 } });
}

module.exports = { findDriverByEmail };
