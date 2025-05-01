// config/connectDB.js

const { MongoClient, ServerApiVersion } = require('mongodb');
const { MONGO_URI, DB_NAME }            = require('./config');

let _client = null;

async function getClient() {
  if (!_client) {
    _client = new MongoClient(MONGO_URI, {
      serverApi: { version: ServerApiVersion.v1 }
    });
    await _client.connect();
  }
  return _client;
}

// Legacy: connects and returns the “rides” database
async function connectDB() {
  const client = await getClient();
  return client.db(DB_NAME);
}

module.exports = { getClient, connectDB };
