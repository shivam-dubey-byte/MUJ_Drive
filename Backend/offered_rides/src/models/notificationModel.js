// src/models/notificationModel.js
const { getClient } = require('../config/connectDB');
async function getNotificationCollection() {
  const client = await getClient();
  const ridesDb = client.db('rides');
  return ridesDb.collection('notification');
}
module.exports = { getNotificationCollection };
