// config/connectDB.js

const { MongoClient, ServerApiVersion } = require('mongodb');
const { MONGO_URI, DB_NAME }     = require('./config');

let dbInstance = null;

async function connectDB() {
  if (dbInstance) return dbInstance;

  const client = new MongoClient(MONGO_URI, {
    serverApi: { version: ServerApiVersion.v1, strict: true, deprecationErrors: true }
  });

  await client.connect();
  console.log('✅ MongoDB connected to', DB_NAME);

  dbInstance = client.db(DB_NAME);
  return dbInstance;
}

module.exports = connectDB;
